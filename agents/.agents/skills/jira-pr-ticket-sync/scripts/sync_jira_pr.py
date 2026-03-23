#!/usr/bin/env python3

from __future__ import annotations

import argparse
import base64
import gzip
import json
import subprocess
import sys
from pathlib import Path
from typing import Any
from urllib.error import HTTPError
from urllib.request import Request, urlopen


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create a Jira ticket, optionally add it to sprint, and sync the current GitHub PR metadata."
    )
    parser.add_argument("--project", required=True, help="Jira project key, for example DO")
    parser.add_argument("--board-id", type=int, help="Jira board id used to resolve the active sprint")
    parser.add_argument("--sprint-id", type=int, help="Explicit sprint id to use instead of resolving the active sprint")
    parser.add_argument("--sprint-field-key", help="Explicit Jira sprint custom field key, for example customfield_10020")
    parser.add_argument("--type", default="Task", help="Jira work item type")
    parser.add_argument("--summary", required=True, help="Jira summary and default PR title text")
    parser.add_argument("--description", help="Jira description text")
    parser.add_argument("--description-file", help="Path to a Jira description file")
    parser.add_argument("--assign-to", default="@me", help="Assignee for acli jira workitem assign")
    parser.add_argument("--skip-assign", action="store_true", help="Skip Jira assignee update")
    parser.add_argument("--skip-sprint", action="store_true", help="Skip sprint assignment")
    parser.add_argument("--pr-number", type=int, help="Explicit PR number; default is the current branch PR")
    parser.add_argument("--pr-title", help="Explicit PR title")
    parser.add_argument("--pr-title-prefix", default="Feat", help="PR title prefix used when --pr-title is omitted")
    parser.add_argument("--skip-pr-title", action="store_true", help="Do not update the PR title")
    parser.add_argument("--pr-body", help="Inline PR body")
    parser.add_argument("--pr-body-file", help="Path to a PR body markdown file")
    parser.add_argument("--skip-pr", action="store_true", help="Skip all PR updates")
    parser.add_argument("--dry-run", action="store_true", help="Print the planned actions without making changes")
    parser.add_argument("--json", action="store_true", help="Emit machine-readable output")
    args = parser.parse_args()

    if args.description and args.description_file:
        parser.error("Use only one of --description and --description-file.")
    if not args.description and not args.description_file:
        parser.error("One of --description or --description-file is required.")
    if args.pr_body and args.pr_body_file:
        parser.error("Use only one of --pr-body and --pr-body-file.")
    if not args.skip_sprint and args.board_id is None and args.sprint_id is None:
        parser.error("Provide --board-id or --sprint-id unless --skip-sprint is set.")
    if not args.skip_sprint and args.board_id is None and args.sprint_field_key is None:
        parser.error("Provide --board-id or --sprint-field-key when assigning a sprint.")
    return args


def run_command(command: list[str], *, capture: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, check=True, text=True, capture_output=capture)


def run_json(command: list[str]) -> dict[str, Any]:
    completed = run_command(command)
    return json.loads(completed.stdout)


def description_text(args: argparse.Namespace) -> str:
    if args.description is not None:
        return args.description
    return Path(args.description_file).read_text()


def current_site() -> str:
    completed = run_command(["acli", "auth", "status"])
    for line in completed.stdout.splitlines():
        stripped = line.strip()
        if stripped.startswith("Site:"):
            site = stripped.split(":", 1)[1].strip()
            if site:
                return site
    raise RuntimeError("Unable to determine the current Atlassian site from `acli auth status`.")


def render_template(text: str, *, issue_key: str, pr_number: int | None = None) -> str:
    issue_url = f"https://{current_site()}/browse/{issue_key}"
    rendered = (
        text.replace("{{ISSUE_KEY}}", issue_key)
        .replace("__ISSUE_KEY__", issue_key)
        .replace("{{ISSUE_URL}}", issue_url)
    )
    if pr_number is not None:
        rendered = rendered.replace("{{PR_NUMBER}}", str(pr_number)).replace("__PR_NUMBER__", str(pr_number))
    return rendered


def pr_body_text(args: argparse.Namespace, *, issue_key: str, pr_number: int | None = None) -> str | None:
    if args.pr_body is not None:
        return render_template(args.pr_body, issue_key=issue_key, pr_number=pr_number)
    if args.pr_body_file is not None:
        return render_template(Path(args.pr_body_file).read_text(), issue_key=issue_key, pr_number=pr_number)
    return None


def create_issue(args: argparse.Namespace) -> str:
    command = [
        "acli",
        "jira",
        "workitem",
        "create",
        "--summary",
        args.summary,
        "--project",
        args.project,
        "--type",
        args.type,
        "--description",
        description_text(args),
        "--json",
    ]
    payload = run_json(command)
    return str(payload["key"])


def assign_issue(issue_key: str, assignee: str) -> None:
    run_command(
        [
            "acli",
            "jira",
            "workitem",
            "assign",
            "--key",
            issue_key,
            "--assignee",
            assignee,
            "--yes",
            "--json",
        ]
    )


def resolve_sprint_id(args: argparse.Namespace) -> int:
    if args.sprint_id is not None:
        return args.sprint_id
    payload = run_json(
        [
            "acli",
            "jira",
            "board",
            "list-sprints",
            "--id",
            str(args.board_id),
            "--state",
            "active",
            "--json",
        ]
    )
    sprints = payload.get("sprints", [])
    if not sprints:
        raise RuntimeError("No active sprint found for the provided board.")
    if len(sprints) > 1:
        raise RuntimeError("Multiple active sprints found. Re-run with --sprint-id.")
    return int(sprints[0]["id"])


def infer_sprint_field_key(board_id: int, sprint_id: int) -> str:
    sprint_issues = run_json(
        [
            "acli",
            "jira",
            "sprint",
            "list-workitems",
            "--board",
            str(board_id),
            "--sprint",
            str(sprint_id),
            "--limit",
            "1",
            "--json",
        ]
    )
    issues = sprint_issues.get("issues", [])
    if not issues:
        raise RuntimeError("Cannot infer sprint field: the sprint has no visible issues. Re-run with --sprint-field-key.")
    sample_issue_key = str(issues[0]["key"])
    issue_payload = run_json(["acli", "jira", "workitem", "view", sample_issue_key, "--fields", "*all", "--json"])
    fields = issue_payload.get("fields", {})

    for field_key, value in fields.items():
        if not isinstance(value, list) or not value:
            continue
        first_item = value[0]
        if not isinstance(first_item, dict):
            continue
        required_keys = {"id", "name", "state"}
        if not required_keys.issubset(first_item.keys()):
            continue
        if any(str(item.get("id")) == str(sprint_id) for item in value if isinstance(item, dict)):
            return str(field_key)

    raise RuntimeError("Unable to infer the Jira sprint field key. Re-run with --sprint-field-key.")


def current_cloud_id() -> str:
    config_path = Path.home() / ".config" / "acli" / "global_auth_config.yaml"
    for line in config_path.read_text().splitlines():
        stripped = line.strip()
        if stripped.startswith("current_profile:"):
            value = stripped.split(":", 1)[1].strip()
            return value.split(":", 1)[0]
    raise RuntimeError(f"Unable to find current_profile in {config_path}.")


def current_access_token() -> str:
    secret = run_command(["security", "find-generic-password", "-s", "acli", "-w"]).stdout.strip()
    prefix = "go-keyring-base64:"
    if not secret.startswith(prefix):
        raise RuntimeError("Unexpected acli keychain entry format.")
    payload = json.loads(gzip.decompress(base64.b64decode(secret.removeprefix(prefix))))
    token = payload.get("access_token")
    if not isinstance(token, str) or not token:
        raise RuntimeError("Unable to read acli access token from keychain.")
    return token


def update_issue_field(issue_key: str, field_key: str, value: int) -> None:
    url = f"https://api.atlassian.com/ex/jira/{current_cloud_id()}/rest/api/3/issue/{issue_key}"
    body = json.dumps({"fields": {field_key: value}}).encode()
    request = Request(
        url,
        data=body,
        method="PUT",
        headers={
            "Authorization": f"Bearer {current_access_token()}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        },
    )
    try:
        with urlopen(request) as response:
            response.read()
    except HTTPError as exc:
        detail = exc.read().decode()
        raise RuntimeError(f"Failed to update Jira sprint field: HTTP {exc.code} {detail}") from exc


def current_pr_number() -> int:
    payload = run_json(["gh", "pr", "view", "--json", "number"])
    return int(payload["number"])


def update_pr(args: argparse.Namespace, issue_key: str) -> int | None:
    if args.skip_pr:
        return None

    pr_number = args.pr_number if args.pr_number is not None else current_pr_number()
    command = ["gh", "pr", "edit", str(pr_number)]

    if not args.skip_pr_title:
        pr_title = render_template(
            args.pr_title or f"{args.pr_title_prefix}: {issue_key} {args.summary}",
            issue_key=issue_key,
            pr_number=pr_number,
        )
        command.extend(["--title", pr_title])

    body = pr_body_text(args, issue_key=issue_key, pr_number=pr_number)
    if body is not None:
        command.extend(["--body", body])

    if len(command) > 3:
        run_command(command)
    return pr_number


def emit(payload: dict[str, Any], *, as_json: bool) -> None:
    if as_json:
        print(json.dumps(payload, indent=2, sort_keys=True))
        return
    for key, value in payload.items():
        print(f"{key}: {value}")


def main() -> int:
    args = parse_args()

    if args.dry_run:
        sprint_id = args.sprint_id if args.sprint_id is not None else "<active>"
        issue_key = f"{args.project}-NEW"
        pr_number = args.pr_number if args.pr_number is not None else "<current>"
        pr_title = render_template(
            args.pr_title or f"{args.pr_title_prefix}: {issue_key} {args.summary}",
            issue_key=issue_key,
            pr_number=None if isinstance(pr_number, str) else pr_number,
        )
        emit(
            {
                "project": args.project,
                "board_id": args.board_id,
                "sprint_id": sprint_id,
                "issue_type": args.type,
                "summary": args.summary,
                "assign_to": None if args.skip_assign else args.assign_to,
                "update_sprint": not args.skip_sprint,
                "pr_number": None if args.skip_pr else pr_number,
                "pr_title": None if args.skip_pr or args.skip_pr_title else pr_title,
                "pr_body_preview": None
                if args.skip_pr
                else pr_body_text(args, issue_key=issue_key, pr_number=None if isinstance(pr_number, str) else pr_number),
            },
            as_json=args.json,
        )
        return 0

    issue_key = create_issue(args)

    if not args.skip_assign:
        assign_issue(issue_key, args.assign_to)

    resolved_sprint_id: int | None = None
    sprint_field_key: str | None = None
    if not args.skip_sprint:
        resolved_sprint_id = resolve_sprint_id(args)
        sprint_field_key = args.sprint_field_key or infer_sprint_field_key(args.board_id, resolved_sprint_id)
        update_issue_field(issue_key, sprint_field_key, resolved_sprint_id)

    pr_number = update_pr(args, issue_key)
    emit(
        {
            "issue_key": issue_key,
            "assignee": None if args.skip_assign else args.assign_to,
            "sprint_id": resolved_sprint_id,
            "sprint_field_key": sprint_field_key,
            "pr_number": pr_number,
        },
        as_json=args.json,
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except subprocess.CalledProcessError as exc:
        if exc.stderr:
            sys.stderr.write(exc.stderr)
        raise SystemExit(exc.returncode)
    except Exception as exc:  # noqa: BLE001
        sys.stderr.write(f"error: {exc}\n")
        raise SystemExit(1)
