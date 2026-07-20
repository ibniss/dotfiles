import {
  Action,
  ActionPanel,
  Cache,
  closeMainWindow,
  Color,
  Icon,
  Keyboard,
  List,
  showToast,
  Toast,
} from "@raycast/api";
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
  parseGhosttyState,
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

type Loadable<T> =
  | Readonly<{ kind: "loading"; value: T | null }>
  | Readonly<{ kind: "loaded"; value: T }>
  | Readonly<{ kind: "failed"; value: T | null; message: string }>;

type ViewState = Readonly<{
  projects: Loadable<readonly Project[]>;
  ghostty: Loadable<GhosttyState>;
  confirmedGhosttyWindowIds: ReadonlySet<string>;
}>;

const workspaceCache = new Cache({ namespace: "switch-workspace" });
const PROJECT_CACHE_KEY = "projects-v1";
const GHOSTTY_CACHE_KEY = "ghostty-v1";

/** Render the interactive Ghostty project and live-window picker. */
export default function SwitchWorkspaceCommand() {
  const [state, setState] = useState<ViewState>(initialViewState);

  const reload = useCallback(async () => {
    setState((current) => ({
      projects: { kind: "loading", value: current.projects.value },
      ghostty: { kind: "loading", value: current.ghostty.value },
      confirmedGhosttyWindowIds: new Set(),
    }));

    const projectsPromise = discoverProjects()
      .then((projects) => {
        cacheProjects(projects);
        setState((current) => ({ ...current, projects: { kind: "loaded", value: projects } }));
      })
      .catch((error: unknown) => {
        setState((current) => ({
          ...current,
          projects: { kind: "failed", value: current.projects.value, message: errorMessage(error) },
        }));
      });
    const ghosttyPromise = queryGhostty((windows) => {
      setState((current) => ({
        ...current,
        ghostty: {
          kind: "loading",
          value: { windows: mergeGhosttyWindows(windows, current.ghostty.value?.windows ?? []) },
        },
        confirmedGhosttyWindowIds: new Set(windows.map((window) => window.id)),
      }));
    })
      .then((ghostty) => {
        cacheGhostty(ghostty);
        setState((current) => ({
          ...current,
          ghostty: { kind: "loaded", value: ghostty },
          confirmedGhosttyWindowIds: new Set(ghostty.windows.map((window) => window.id)),
        }));
      })
      .catch((error: unknown) => {
        setState((current) => ({
          ...current,
          ghostty: { kind: "failed", value: current.ghostty.value, message: errorMessage(error) },
        }));
      });

    await Promise.all([projectsPromise, ghosttyPromise]);
  }, []);

  useEffect(() => {
    void reload();
  }, [reload]);

  const projects = state.projects.value ?? [];
  const ghostty = state.ghostty.value;
  const items = useMemo(() => buildWorkspaceItems(projects, ghostty?.windows ?? []), [projects, ghostty]);
  const openItems = items.filter((item) => item.kind === "open-window");
  const newItems = items.filter((item) => item.kind === "new-project");
  const isLoading = state.projects.kind === "loading" || state.ghostty.kind === "loading";
  const blockingFailure = failureWithoutFallback(state);

  return (
    <List isLoading={isLoading} searchBarPlaceholder="Search Ghostty workspaces and projects…" filtering>
      {blockingFailure !== null ? (
        <List.EmptyView
          icon={Icon.Warning}
          title="Could not read Ghostty workspaces"
          description={blockingFailure}
          actions={
            <ActionPanel>
              <Action title="Try Again" icon={Icon.ArrowClockwise} onAction={reload} />
            </ActionPanel>
          }
        />
      ) : null}

      <List.Section title="Open Workspaces" subtitle={openItems.length.toString()}>
        {openItems.map((item) => (
          <WorkspaceListItem
            key={item.project?.path ?? item.window.id}
            item={item}
            reload={reload}
            isConfirmed={state.confirmedGhosttyWindowIds.has(item.window.id)}
          />
        ))}
      </List.Section>

      <List.Section title="Projects" subtitle={newItems.length.toString()}>
        {newItems.map((item) => (
          <WorkspaceListItem key={item.project.path} item={item} reload={reload} isConfirmed />
        ))}
      </List.Section>

      {blockingFailure === null && items.length === 0 && !isLoading ? (
        <List.EmptyView
          icon={Icon.Folder}
          title="No projects found"
          description="Expected ~/dotfiles or project directories immediately inside ~/code."
        />
      ) : null}
    </List>
  );
}

function initialViewState(): ViewState {
  return {
    projects: { kind: "loading", value: readCachedProjects() },
    ghostty: { kind: "loading", value: readCachedGhostty() },
    confirmedGhosttyWindowIds: new Set(),
  };
}

function failureWithoutFallback(state: ViewState): string | null {
  if (state.projects.kind === "failed" && state.projects.value === null) return state.projects.message;
  if (state.ghostty.kind === "failed" && state.projects.value === null) return state.ghostty.message;
  return null;
}

function readCachedProjects(): readonly Project[] | null {
  try {
    const serialized = workspaceCache.get(PROJECT_CACHE_KEY);
    if (serialized === undefined) return null;

    const projects = parseCachedProjects(JSON.parse(serialized) as unknown);
    if (projects !== null) return projects;

    removeCachedProjects();
    return null;
  } catch {
    removeCachedProjects();
    return null;
  }
}

function cacheProjects(projects: readonly Project[]): void {
  try {
    workspaceCache.set(PROJECT_CACHE_KEY, JSON.stringify(projects));
  } catch {
    // The cache is only a launch optimization; discovery remains authoritative.
  }
}

function removeCachedProjects(): void {
  try {
    workspaceCache.remove(PROJECT_CACHE_KEY);
  } catch {
    // An unreadable cache should never prevent the picker from opening.
  }
}

function readCachedGhostty(): GhosttyState | null {
  try {
    const serialized = workspaceCache.get(GHOSTTY_CACHE_KEY);
    if (serialized === undefined) return null;
    return parseGhosttyState(JSON.parse(serialized) as unknown);
  } catch {
    removeCachedGhostty();
    return null;
  }
}

function cacheGhostty(ghostty: GhosttyState): void {
  try {
    workspaceCache.set(GHOSTTY_CACHE_KEY, JSON.stringify(ghostty));
  } catch {
    // The cache is only a launch optimization; the live stream remains authoritative.
  }
}

function removeCachedGhostty(): void {
  try {
    workspaceCache.remove(GHOSTTY_CACHE_KEY);
  } catch {
    // An unreadable cache should never prevent the picker from opening.
  }
}

function mergeGhosttyWindows(
  fresh: readonly GhosttyWindow[],
  fallback: readonly GhosttyWindow[],
): readonly GhosttyWindow[] {
  const freshIds = new Set(fresh.map((window) => window.id));
  return [...fresh, ...fallback.filter((window) => !freshIds.has(window.id))];
}

function parseCachedProjects(value: unknown): readonly Project[] | null {
  if (!Array.isArray(value)) return null;

  const projects: Project[] = [];
  for (const item of value) {
    if (typeof item !== "object" || item === null || Array.isArray(item)) return null;

    const record = item as Record<string, unknown>;
    if (typeof record.name !== "string" || typeof record.path !== "string") return null;
    projects.push({ name: record.name, path: record.path });
  }
  return projects;
}

function WorkspaceListItem({
  item,
  reload,
  isConfirmed,
}: {
  item: WorkspaceItem;
  reload: () => Promise<void>;
  isConfirmed: boolean;
}) {
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
      icon={{ source: Icon.Terminal, tintColor: isConfirmed ? Color.Green : Color.SecondaryText }}
      title={title}
      subtitle={subtitleParts.join(" · ")}
      keywords={[...workspaceKeywords(item)]}
      accessories={[
        {
          tag: { value: "open", color: isConfirmed ? Color.Green : Color.SecondaryText },
        },
        { text: `${tabCount} ${tabCount === 1 ? "tab" : "tabs"} · ${paneCount} ${paneCount === 1 ? "pane" : "panes"}` },
      ]}
      actions={isConfirmed ? <WorkspaceActions item={item} reload={reload} /> : null}
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
