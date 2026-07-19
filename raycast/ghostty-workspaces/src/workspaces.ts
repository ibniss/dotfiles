import { readdir, stat } from "node:fs/promises";
import { homedir } from "node:os";
import { basename, isAbsolute, join, normalize, relative, sep } from "node:path";
import type { GhosttyWindow } from "./ghostty";

export type Project = Readonly<{
  name: string;
  path: string;
}>;

export type OpenWorkspace = Readonly<{
  kind: "open-window";
  window: GhosttyWindow;
  project: Project | null;
}>;

export type NewWorkspace = Readonly<{
  kind: "new-project";
  project: Project;
}>;

export type WorkspaceItem = OpenWorkspace | NewWorkspace;

/** Discover projects using the same roots as the existing WezTerm project selector. */
export async function discoverProjects(): Promise<readonly Project[]> {
  const home = homedir();
  const projectPaths: string[] = [];
  const dotfiles = join(home, "dotfiles");

  if (await isDirectory(dotfiles)) projectPaths.push(dotfiles);

  const codeDirectory = join(home, "code");
  try {
    const entries = await readdir(codeDirectory, { withFileTypes: true });
    const childDirectories = await Promise.all(
      entries.map(async (entry) => {
        if (entry.name.startsWith(".")) return null;

        const path = join(codeDirectory, entry.name);
        return (entry.isDirectory() || entry.isSymbolicLink()) && (await isDirectory(path)) ? path : null;
      }),
    );
    projectPaths.push(...childDirectories.filter((path): path is string => path !== null));
  } catch (error) {
    if (!isMissingPathError(error)) throw error;
  }

  return projectPaths
    .map((path) => ({ name: basename(path), path: normalize(path) }))
    .sort((left, right) => left.name.localeCompare(right.name));
}

/** Merge live Ghostty windows with unopened projects for display in Raycast. */
export function buildWorkspaceItems(
  projects: readonly Project[],
  windows: readonly GhosttyWindow[],
): readonly WorkspaceItem[] {
  const inferredOpenItems: OpenWorkspace[] = windows.map((window) => ({
    kind: "open-window",
    window,
    project: inferProject(window, projects),
  }));
  const seenProjectPaths = new Set<string>();
  const openItems = inferredOpenItems.filter((item) => {
    if (item.project === null) return true;
    if (seenProjectPaths.has(item.project.path)) return false;
    seenProjectPaths.add(item.project.path);
    return true;
  });
  const openProjectPaths = new Set(openItems.flatMap((item) => (item.project === null ? [] : [item.project.path])));
  const newItems: NewWorkspace[] = projects
    .filter((project) => !openProjectPaths.has(project.path))
    .map((project) => ({ kind: "new-project", project }));

  return [...openItems, ...newItems];
}

/** Find the existing Ghostty window whose terminals belong to a project path. */
export function findProjectWindow(projectPath: string, windows: readonly GhosttyWindow[]): GhosttyWindow | null {
  return (
    windows.find((window) =>
      window.tabs.some((tab) =>
        tab.terminals.some((terminal) => terminal.cwd !== null && pathContains(projectPath, terminal.cwd)),
      ),
    ) ?? null
  );
}

/** Get the best human-readable working directory for a Ghostty window. */
export function primaryWorkingDirectory(window: GhosttyWindow): string | null {
  const selectedTab = window.tabs.find((tab) => tab.selected) ?? window.tabs[0];
  return selectedTab?.terminals.find((terminal) => terminal.cwd !== null)?.cwd ?? null;
}

/** Return every title and path that should participate in Raycast fuzzy matching. */
export function workspaceKeywords(item: WorkspaceItem): readonly string[] {
  if (item.kind === "new-project") return [item.project.name, item.project.path];

  return [
    item.window.name,
    ...(item.project === null ? [] : [item.project.name, item.project.path]),
    ...item.window.tabs.flatMap((tab) => [
      tab.name,
      ...tab.terminals.flatMap((terminal) => [terminal.name, ...(terminal.cwd === null ? [] : [terminal.cwd])]),
    ]),
  ].filter((keyword) => keyword.length > 0);
}

function inferProject(window: GhosttyWindow, projects: readonly Project[]): Project | null {
  const terminalDirectories = window.tabs.flatMap((tab) =>
    tab.terminals.flatMap((terminal) => (terminal.cwd === null ? [] : [terminal.cwd])),
  );
  const rankedProjects = projects
    .map((project) => ({
      project,
      matches: terminalDirectories.filter((cwd) => pathContains(project.path, cwd)).length,
    }))
    .filter(({ matches }) => matches > 0)
    .sort((left, right) => right.matches - left.matches || right.project.path.length - left.project.path.length);

  return rankedProjects[0]?.project ?? null;
}

function pathContains(parent: string, child: string): boolean {
  const relativePath = relative(normalize(parent), normalize(child));
  return (
    relativePath === "" || (!relativePath.startsWith(`..${sep}`) && relativePath !== ".." && !isAbsolute(relativePath))
  );
}

async function isDirectory(path: string): Promise<boolean> {
  try {
    return (await stat(path)).isDirectory();
  } catch (error) {
    if (isMissingPathError(error)) return false;
    throw error;
  }
}

function isMissingPathError(error: unknown): boolean {
  return error instanceof Error && "code" in error && error.code === "ENOENT";
}
