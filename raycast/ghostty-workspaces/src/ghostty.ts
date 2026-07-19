import { runAppleScript } from "@raycast/utils";

export type GhosttyTerminal = Readonly<{
  id: string;
  name: string;
  cwd: string | null;
}>;

export type GhosttyTab = Readonly<{
  id: string;
  name: string;
  index: number;
  selected: boolean;
  terminals: readonly GhosttyTerminal[];
}>;

export type GhosttyWindow = Readonly<{
  id: string;
  name: string;
  tabs: readonly GhosttyTab[];
}>;

export type GhosttyState = Readonly<{
  version: string;
  windows: readonly GhosttyWindow[];
}>;

const QUERY_GHOSTTY_SCRIPT = String.raw`
const ghostty = Application("Ghostty");
const windows = ghostty.windows();

JSON.stringify({
  version: ghostty.version(),
  windows: windows.map((window) => ({
    id: window.id(),
    name: window.name(),
    tabs: window.tabs().map((tab) => ({
      id: tab.id(),
      name: tab.name(),
      index: tab.index(),
      selected: tab.selected(),
      terminals: tab.terminals().map((terminal) => ({
        id: terminal.id(),
        name: terminal.name(),
        cwd: terminal.workingDirectory() || null,
      })),
    })),
  })),
});
`;

const FOCUS_WINDOW_SCRIPT = String.raw`
on run argv
  set targetId to item 1 of argv

  tell application "Ghostty"
    repeat with candidateWindow in windows
      if (id of candidateWindow as text) is targetId then
        activate
        activate window candidateWindow
        focus (focused terminal of selected tab of candidateWindow)
        return targetId
      end if
    end repeat
  end tell

  error "Ghostty window no longer exists: " & targetId
end run
`;

const CREATE_WINDOW_SCRIPT = String.raw`
on run argv
  set projectDirectory to item 1 of argv

  tell application "Ghostty"
    activate

    set surfaceConfig to new surface configuration
    set initial working directory of surfaceConfig to projectDirectory
    set createdWindow to new window with configuration surfaceConfig
    focus (focused terminal of selected tab of createdWindow)

    return id of createdWindow
  end tell
end run
`;

/** Read the current native Ghostty window, tab, and terminal hierarchy. */
export async function queryGhostty(): Promise<GhosttyState> {
  const output = await runAppleScript(QUERY_GHOSTTY_SCRIPT, {
    language: "JavaScript",
    timeout: 3_000,
  });

  return parseGhosttyState(JSON.parse(output) as unknown);
}

/** Bring an existing Ghostty window and its focused terminal to the foreground. */
export async function focusGhosttyWindow(windowId: string): Promise<void> {
  await runAppleScript(FOCUS_WINDOW_SCRIPT, [windowId], { timeout: 3_000 });
}

/** Create and focus a new Ghostty window rooted at a project directory. */
export async function createGhosttyWindow(projectDirectory: string): Promise<string> {
  return runAppleScript(CREATE_WINDOW_SCRIPT, [projectDirectory], { timeout: 5_000 });
}

function parseGhosttyState(value: unknown): GhosttyState {
  const record = parseRecord(value, "Ghostty state");
  return {
    version: parseString(record.version, "Ghostty version"),
    windows: parseArray(record.windows, "Ghostty windows").map(parseWindow),
  };
}

function parseWindow(value: unknown): GhosttyWindow {
  const record = parseRecord(value, "Ghostty window");
  return {
    id: parseString(record.id, "window id"),
    name: parseString(record.name, "window name"),
    tabs: parseArray(record.tabs, "window tabs").map(parseTab),
  };
}

function parseTab(value: unknown): GhosttyTab {
  const record = parseRecord(value, "Ghostty tab");
  return {
    id: parseString(record.id, "tab id"),
    name: parseString(record.name, "tab name"),
    index: parseNumber(record.index, "tab index"),
    selected: parseBoolean(record.selected, "tab selected state"),
    terminals: parseArray(record.terminals, "tab terminals").map(parseTerminal),
  };
}

function parseTerminal(value: unknown): GhosttyTerminal {
  const record = parseRecord(value, "Ghostty terminal");
  return {
    id: parseString(record.id, "terminal id"),
    name: parseString(record.name, "terminal name"),
    cwd: record.cwd === null ? null : parseString(record.cwd, "terminal working directory"),
  };
}

function parseRecord(value: unknown, label: string): Record<string, unknown> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw new Error(`${label} must be an object`);
  }
  return value as Record<string, unknown>;
}

function parseArray(value: unknown, label: string): readonly unknown[] {
  if (!Array.isArray(value)) throw new Error(`${label} must be an array`);
  return value;
}

function parseString(value: unknown, label: string): string {
  if (typeof value !== "string") throw new Error(`${label} must be text`);
  return value;
}

function parseNumber(value: unknown, label: string): number {
  if (typeof value !== "number" || !Number.isFinite(value)) throw new Error(`${label} must be a number`);
  return value;
}

function parseBoolean(value: unknown, label: string): boolean {
  if (typeof value !== "boolean") throw new Error(`${label} must be true or false`);
  return value;
}
