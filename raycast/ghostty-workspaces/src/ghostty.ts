import { runAppleScript } from "@raycast/utils";
import { spawn } from "node:child_process";
import { createInterface } from "node:readline";

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
  windows: readonly GhosttyWindow[];
}>;

const QUERY_GHOSTTY_SCRIPT = String.raw`
ObjC.import("Foundation");

function emit(value) {
  const data = $(JSON.stringify(value) + "\n").dataUsingEncoding($.NSUTF8StringEncoding);
  $.NSFileHandle.fileHandleWithStandardOutput.writeData(data);
}

function main() {
  const ghostty = Application("Ghostty");
  const windows = ghostty.windows();

  windows.forEach((window) => {
    // Fetch each object's property record in one Apple event; individual getters roughly double query time.
    const windowProperties = window.properties();
    const id = windowProperties.id;
    const name = windowProperties.name;
    const nativeTabs = window.tabs();
    const tabs = [];
    const emitWindow = () => emit({ kind: "window", window: { id, name, tabs } });

    if (nativeTabs.length === 0) emitWindow();

    nativeTabs.forEach((tab) => {
      const tabProperties = tab.properties();
      tabs.push({
        id: tabProperties.id,
        name: tabProperties.name,
        index: tabProperties.index,
        selected: tabProperties.selected,
        terminals: tab.terminals().map((terminal) => {
          const terminalProperties = terminal.properties();
          return {
            id: terminalProperties.id,
            name: terminalProperties.name,
            cwd: terminalProperties.workingDirectory || null,
          };
        }),
      });
      emitWindow();
    });
  });

  emit({ kind: "complete" });
}

main();
`;

const OSASCRIPT_BINARY = "/usr/bin/osascript";
const QUERY_TIMEOUT_MS = 3_000;

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

/** Read Ghostty's hierarchy, reporting each fully hydrated window as soon as it is available. */
export async function queryGhostty(onProgress?: (windows: readonly GhosttyWindow[]) => void): Promise<GhosttyState> {
  const child = spawn(OSASCRIPT_BINARY, ["-l", "JavaScript", "-e", QUERY_GHOSTTY_SCRIPT], {
    stdio: ["ignore", "pipe", "pipe"],
  });
  const completion = waitForProcess(child);
  const lines = createInterface({ input: child.stdout, crlfDelay: Infinity });
  const windows: GhosttyWindow[] = [];
  let stderr = "";
  let complete = false;
  let timedOut = false;

  child.stderr.setEncoding("utf8");
  child.stderr.on("data", (chunk: string) => {
    stderr += chunk;
  });

  const timeout = setTimeout(() => {
    timedOut = true;
    child.kill();
  }, QUERY_TIMEOUT_MS);

  try {
    for await (const line of lines) {
      if (line.length === 0) continue;

      const event = parseQueryEvent(JSON.parse(line) as unknown);
      if (event.kind === "complete") {
        complete = true;
        continue;
      }

      const existingIndex = windows.findIndex((window) => window.id === event.window.id);
      if (existingIndex === -1) windows.push(event.window);
      else windows[existingIndex] = event.window;
      onProgress?.([...windows]);
    }

    const exitCode = await completion;
    if (timedOut) throw new Error(`Ghostty query timed out after ${QUERY_TIMEOUT_MS} ms`);
    if (exitCode !== 0) throw new Error(stderr.trim() || `Ghostty query exited with status ${exitCode}`);
    if (!complete) throw new Error("Ghostty query ended before reporting completion");

    return { windows };
  } finally {
    clearTimeout(timeout);
    lines.close();
    if (child.exitCode === null) child.kill();
  }
}

/** Parse a persisted Ghostty hierarchy at the cache boundary. */
export function parseGhosttyState(value: unknown): GhosttyState {
  const record = parseRecord(value, "Ghostty state");
  return { windows: parseArray(record.windows, "Ghostty windows").map(parseWindow) };
}

/** Bring an existing Ghostty window and its focused terminal to the foreground. */
export async function focusGhosttyWindow(windowId: string): Promise<void> {
  await runAppleScript(FOCUS_WINDOW_SCRIPT, [windowId], { timeout: 3_000 });
}

/** Create and focus a new Ghostty window rooted at a project directory. */
export async function createGhosttyWindow(projectDirectory: string): Promise<string> {
  return runAppleScript(CREATE_WINDOW_SCRIPT, [projectDirectory], { timeout: 5_000 });
}

type QueryEvent = Readonly<{ kind: "window"; window: GhosttyWindow }> | Readonly<{ kind: "complete" }>;

function parseQueryEvent(value: unknown): QueryEvent {
  const record = parseRecord(value, "Ghostty query event");
  const kind = parseString(record.kind, "Ghostty query event kind");
  if (kind === "window") return { kind, window: parseWindow(record.window) };
  if (kind === "complete") return { kind };
  throw new Error(`Unknown Ghostty query event: ${kind}`);
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

function waitForProcess(child: ReturnType<typeof spawn>): Promise<number | null> {
  return new Promise((resolve, reject) => {
    child.once("error", reject);
    child.once("close", resolve);
  });
}
