---
name: jira-pr-ticket-sync
description: Create or update a Jira ticket for the current branch or pull request, assign it, add it to the active sprint, and sync the GitHub PR title/body to match the real scope of the work. Use when asked to add a ticket, put it in sprint, fix stale PR metadata, or keep Jira and a PR aligned.
---

# Jira PR Ticket Sync

Use this skill for the mechanical Jira + GitHub PR sync flow after you have already decided the actual scope of the branch.

## Requirements

- `acli` must be installed and authenticated.
- `gh` must be installed and authenticated.
- The helper script assumes macOS for the sprint-assignment fallback because it reuses the `acli` OAuth token from the Keychain when `acli` itself cannot assign sprint membership.

## Current CLI Notes

- Prefer running real Jira commands over relying on `acli auth status`. In some setups, `acli auth status` may claim Jira is not authenticated even while `acli jira ...` commands succeed.
- For board lookup, use `acli jira board search`, not `acli jira board list`.
- Keep project keys, board ids, board names, site URLs, and assignee identities out of the skill itself. Discover them from the current repo, current PRs, or the user's explicit request.
- Prefer matching nearby PRs from the current author when title conventions vary.

## Workflow

1. Inspect the real branch scope before writing anything.
2. Draft a concise Jira summary and PR body that match the code, not stale history.
3. Run the helper script for the mechanical operations.
4. Verify the Jira issue and PR metadata after the update.

Do not guess the scope from the current PR title if it is stale. Prefer:

- `gh pr diff --name-only`
- `git log --oneline origin/main..HEAD`
- `gh pr view --json title,body,files`

Useful Jira/board discovery commands with the current `acli` shape:

- `acli jira board search --project PROJECT_KEY --json`
- `acli jira board list-sprints --id BOARD_ID --state active --json`
- `acli jira workitem view KEY --fields '*all' --json`

## Scope Rules

- Keep the skill generic. Do not hard-code project keys, board ids, email addresses, sprint field ids, or company names into the skill.
- Prefer `acli` for Jira operations.
- Use the script's REST fallback only for sprint assignment, because `acli` does not currently expose a direct "add issue to sprint" command.
- Honor the user's PR title convention instead of assuming one. If the user does not specify, ask or infer from existing PRs.

## Helper Script

Use `python3` with [sync_jira_pr.py](./scripts/sync_jira_pr.py) for the mechanical flow:

- create the Jira work item with `acli`
- optionally assign it with `acli`
- resolve the active sprint from a Jira board with `acli`
- infer the sprint custom field from an issue already in that sprint
- set sprint membership through Jira REST using the existing `acli` auth token
- update the current PR title and optional body with `gh`

The helper supports simple body/title templating after issue creation:

- `{{ISSUE_KEY}}` or `__ISSUE_KEY__`
- `{{ISSUE_URL}}`
- `{{PR_NUMBER}}` or `__PR_NUMBER__`

`{{ISSUE_URL}}` is derived from the currently authenticated Atlassian site, so no company-specific Jira URL needs to be hard-coded.

Use this when the PR body should mention the new Jira key without requiring a second manual PR edit.

Typical usage:

```bash
python3 /Users/kbiel/dotfiles/agents/.agents/skills/jira-pr-ticket-sync/scripts/sync_jira_pr.py \
  --project PROJECT_KEY \
  --board-id BOARD_ID \
  --summary "Add review history page and table" \
  --description "Add review decision history to the review workflow." \
  --pr-title-prefix Feat \
  --pr-body-file /tmp/pr-body.md
```

Example `pr-body.md` snippet using the new template placeholders:

```md
## Additional Context
This work is tracked in Jira: {{ISSUE_KEY}}.
```

Body-only PR update:

```bash
python3 /Users/kbiel/dotfiles/agents/.agents/skills/jira-pr-ticket-sync/scripts/sync_jira_pr.py \
  --project PROJECT_KEY \
  --board-id BOARD_ID \
  --summary "Add review history page and table" \
  --description "Add review decision history to the review workflow." \
  --skip-pr-title \
  --pr-body-file /tmp/pr-body.md
```

Dry run:

```bash
python3 /Users/kbiel/dotfiles/agents/.agents/skills/jira-pr-ticket-sync/scripts/sync_jira_pr.py \
  --project PROJECT_KEY \
  --board-id BOARD_ID \
  --summary "Example change" \
  --description "Example description." \
  --dry-run
```

## Parameters To Decide Before Running

- `--project`: Jira project key
- `--board-id`: Jira board id used to find the active sprint
- `--summary`: concise Jira title matching the actual branch scope
- `--description` or `--description-file`: concise Jira description
- `--pr-title-prefix`: PR title prefix such as `Feat` or `Fix`
- `--pr-body-file`: optional PR body markdown file when the PR description also needs updating

Optional overrides:

- `--sprint-id` when you already know the target sprint
- `--sprint-field-key` if sprint field inference fails in a custom Jira setup
- `--pr-number` if you do not want to use the current branch PR
- `--skip-sprint`, `--skip-assign`, `--skip-pr-title` for partial flows

## Verification

After running the script, verify with:

```bash
acli jira board search --project PROJECT_KEY --json
acli jira workitem view KEY --fields '*all' --json
gh pr view --json title,body,url
```

Check:

- Jira summary is correct
- assignee is correct
- sprint membership is present when requested
- PR title matches the requested convention
- PR body matches the actual branch scope
