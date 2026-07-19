import { Action, ActionPanel, closeMainWindow, Color, Icon, Keyboard, List, showToast, Toast } from "@raycast/api";
import { homedir } from "node:os";
import { useCallback, useEffect, useMemo, useState } from "react";
import {
  focusAeroSpaceProjectWindow,
  listAeroSpaceGhosttyWindows,
  placeAeroSpaceWindow,
  waitForNewAeroSpaceGhosttyWindow,
} from "./aerospace";
import {
  createGhosttyWindow,
  focusGhosttyWindow,
  queryGhostty,
  type GhosttyState,
  type GhosttyWindow,
} from "./ghostty";
import {
  buildWorkspaceItems,
  discoverProjects,
  findProjectWindow,
  primaryWorkingDirectory,
  workspaceKeywords,
  type Project,
  type WorkspaceItem,
} from "./workspaces";

type LoadedWorkspaceState = Readonly<{
  projects: readonly Project[];
  ghostty: GhosttyState;
}>;

type ViewState =
  | Readonly<{ kind: "loading"; previous: LoadedWorkspaceState | null }>
  | Readonly<{ kind: "loaded"; value: LoadedWorkspaceState }>
  | Readonly<{ kind: "failed"; message: string }>;

/** Render the interactive Ghostty project and live-window picker. */
export default function SwitchWorkspaceCommand() {
  const [state, setState] = useState<ViewState>({ kind: "loading", previous: null });

  const reload = useCallback(async () => {
    setState((current) => ({
      kind: "loading",
      previous: current.kind === "loaded" ? current.value : current.kind === "loading" ? current.previous : null,
    }));

    try {
      const [projects, ghostty] = await Promise.all([discoverProjects(), queryGhostty()]);
      setState({ kind: "loaded", value: { projects, ghostty } });
    } catch (error) {
      setState({ kind: "failed", message: errorMessage(error) });
    }
  }, []);

  useEffect(() => {
    void reload();
  }, [reload]);

  const loaded = state.kind === "loaded" ? state.value : state.kind === "loading" ? state.previous : null;
  const items = useMemo(
    () => (loaded === null ? [] : buildWorkspaceItems(loaded.projects, loaded.ghostty.windows)),
    [loaded],
  );
  const openItems = items.filter((item) => item.kind === "open-window");
  const newItems = items.filter((item) => item.kind === "new-project");

  return (
    <List isLoading={state.kind === "loading"} searchBarPlaceholder="Search Ghostty workspaces and projects…" filtering>
      {state.kind === "failed" ? (
        <List.EmptyView
          icon={Icon.Warning}
          title="Could not read Ghostty workspaces"
          description={state.message}
          actions={
            <ActionPanel>
              <Action title="Try Again" icon={Icon.ArrowClockwise} onAction={reload} />
            </ActionPanel>
          }
        />
      ) : null}

      <List.Section title="Open Workspaces" subtitle={openItems.length.toString()}>
        {openItems.map((item) => (
          <WorkspaceListItem key={item.window.id} item={item} reload={reload} />
        ))}
      </List.Section>

      <List.Section title="Projects" subtitle={newItems.length.toString()}>
        {newItems.map((item) => (
          <WorkspaceListItem key={item.project.path} item={item} reload={reload} />
        ))}
      </List.Section>

      {state.kind !== "failed" && items.length === 0 && state.kind !== "loading" ? (
        <List.EmptyView
          icon={Icon.Folder}
          title="No projects found"
          description="Expected ~/dotfiles or project directories immediately inside ~/code."
        />
      ) : null}
    </List>
  );
}

function WorkspaceListItem({ item, reload }: { item: WorkspaceItem; reload: () => Promise<void> }) {
  if (item.kind === "new-project") {
    return (
      <List.Item
        icon={{ source: Icon.Folder, tintColor: Color.SecondaryText }}
        title={item.project.name}
        subtitle={shortenHome(item.project.path)}
        keywords={[...workspaceKeywords(item)]}
        accessories={[{ tag: { value: "new", color: Color.SecondaryText } }]}
        actions={<WorkspaceActions item={item} reload={reload} />}
      />
    );
  }

  const tabCount = item.window.tabs.length;
  const paneCount = item.window.tabs.reduce((total, tab) => total + tab.terminals.length, 0);
  const cwd = primaryWorkingDirectory(item.window);
  const title = item.project?.name ?? (item.window.name || "Ghostty");
  const subtitleParts = [
    cwd === null ? null : shortenHome(cwd),
    item.project === null ? item.window.name : null,
  ].filter((part): part is string => part !== null && part.length > 0 && part !== title);

  return (
    <List.Item
      icon={{ source: Icon.Terminal, tintColor: Color.Green }}
      title={title}
      subtitle={subtitleParts.join(" · ")}
      keywords={[...workspaceKeywords(item)]}
      accessories={[
        { tag: { value: "open", color: Color.Green } },
        { text: `${tabCount} ${tabCount === 1 ? "tab" : "tabs"} · ${paneCount} ${paneCount === 1 ? "pane" : "panes"}` },
      ]}
      actions={<WorkspaceActions item={item} reload={reload} />}
    />
  );
}

function WorkspaceActions({ item, reload }: { item: WorkspaceItem; reload: () => Promise<void> }) {
  const projectPath = item.kind === "new-project" ? item.project.path : item.project?.path;

  return (
    <ActionPanel>
      <Action
        title={item.kind === "open-window" ? "Focus Workspace" : "Open Workspace"}
        icon={item.kind === "open-window" ? Icon.Window : Icon.Plus}
        onAction={() => runPrimaryAction(item)}
      />
      {projectPath !== undefined ? <Action.ShowInFinder path={projectPath} /> : null}
      {projectPath !== undefined ? <Action.CopyToClipboard title="Copy Project Path" content={projectPath} /> : null}
      <Action
        title="Refresh Workspaces"
        icon={Icon.ArrowClockwise}
        shortcut={Keyboard.Shortcut.Common.Refresh}
        onAction={reload}
      />
    </ActionPanel>
  );
}

async function runPrimaryAction(item: WorkspaceItem): Promise<void> {
  await closeMainWindow();
  try {
    if (item.kind === "new-project") {
      await openProjectWorkspace(item.project);
      return;
    }

    if (item.project === null) {
      await focusGhosttyWindow(item.window.id);
      return;
    }

    await focusProjectWorkspace(item.project, item.window);
  } catch (error) {
    await showToast({
      style: Toast.Style.Failure,
      title: "Could not open Ghostty workspace",
      message: errorMessage(error),
    });
  }
}

async function openProjectWorkspace(project: Project): Promise<void> {
  const existingWindow = findProjectWindow(project.path, (await queryGhostty()).windows);
  if (existingWindow !== null) {
    await focusProjectWorkspace(project, existingWindow);
    return;
  }

  const existingAeroSpaceWindows = await listAeroSpaceGhosttyWindows();
  const previousWindowIds = new Set(existingAeroSpaceWindows.map((window) => window.id));
  await createGhosttyWindow(project.path);
  const createdWindow = await waitForNewAeroSpaceGhosttyWindow(previousWindowIds);
  await placeAeroSpaceWindow(createdWindow.id, project.name);
}

async function focusProjectWorkspace(project: Project, ghosttyWindow: GhosttyWindow): Promise<void> {
  await focusAeroSpaceProjectWindow(project.name, ghosttyWindow.name);
}

function shortenHome(path: string): string {
  const home = homedir();
  return path === home ? "~" : path.startsWith(`${home}/`) ? `~/${path.slice(home.length + 1)}` : path;
}

function errorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return String(error);
}
