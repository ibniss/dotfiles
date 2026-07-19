import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const AEROSPACE_BINARY = "/opt/homebrew/bin/aerospace";
const GHOSTTY_BUNDLE_ID = "com.mitchellh.ghostty";
const WINDOW_FORMAT = "%{window-id} %{app-bundle-id} %{workspace} %{window-is-fullscreen} %{window-title}";

export type AeroSpaceWindow = Readonly<{
  id: number;
  appBundleId: string;
  workspace: string;
  fullscreen: boolean;
  title: string;
}>;

/** Read every Ghostty window currently managed by AeroSpace. */
export async function listAeroSpaceGhosttyWindows(): Promise<readonly AeroSpaceWindow[]> {
  return listWindows(["--monitor", "all", "--app-bundle-id", GHOSTTY_BUNDLE_ID]);
}

/** Wait until AeroSpace reports a newly created Ghostty window. */
export async function waitForNewAeroSpaceGhosttyWindow(
  previousWindowIds: ReadonlySet<number>,
): Promise<AeroSpaceWindow> {
  for (let attempt = 0; attempt < 30; attempt += 1) {
    const windows = await listAeroSpaceGhosttyWindows();
    const created = windows.find((window) => !previousWindowIds.has(window.id));
    if (created !== undefined) return created;
    await delay(100);
  }

  throw new Error("AeroSpace did not detect the new Ghostty window");
}

/** Focus a project's existing Ghostty window using AeroSpace as the source of truth. */
export async function focusAeroSpaceProjectWindow(workspace: string, expectedTitle: string): Promise<void> {
  const windows = await listAeroSpaceGhosttyWindows();
  const workspaceWindows = windows.filter((candidate) => candidate.workspace === workspace);
  if (workspaceWindows.length > 0) {
    await runAeroSpace(["workspace", workspace]);
    const focusedWindow = (await listWindows(["--focused"]))[0];
    const window =
      focusedWindow?.appBundleId === GHOSTTY_BUNDLE_ID && focusedWindow.workspace === workspace
        ? focusedWindow
        : workspaceWindows[0];
    await focusAndFullscreenAeroSpaceWindow(window.id);
    return;
  }

  const window = windows.find((candidate) => candidate.title === expectedTitle);

  if (window === undefined) {
    throw new Error(`AeroSpace cannot find the existing Ghostty window for workspace ${workspace}`);
  }

  await placeAeroSpaceWindow(window.id, workspace);
}

/** Move one window into a project workspace, focus it, and enable AeroSpace fullscreen. */
export async function placeAeroSpaceWindow(windowId: number, workspace: string): Promise<void> {
  await runAeroSpace(["move-node-to-workspace", "--window-id", windowId.toString(), workspace]);
  await runAeroSpace(["workspace", workspace]);
  await focusAndFullscreenAeroSpaceWindow(windowId);
}

async function focusAndFullscreenAeroSpaceWindow(windowId: number): Promise<void> {
  await runAeroSpace(["focus", "--window-id", windowId.toString()]);
  await runAeroSpace(["fullscreen", "on", "--window-id", windowId.toString()]);
}

async function listWindows(filters: readonly string[]): Promise<readonly AeroSpaceWindow[]> {
  const output = await runAeroSpace(["list-windows", ...filters, "--format", WINDOW_FORMAT, "--json"]);
  return parseAeroSpaceWindows(JSON.parse(output) as unknown);
}

async function runAeroSpace(args: readonly string[]): Promise<string> {
  const { stdout } = await execFileAsync(AEROSPACE_BINARY, [...args], {
    encoding: "utf8",
    timeout: 5_000,
  });
  return stdout.trim();
}

function parseAeroSpaceWindows(value: unknown): readonly AeroSpaceWindow[] {
  if (!Array.isArray(value)) throw new Error("AeroSpace window response must be an array");
  return value.map((item) => {
    const record = parseRecord(item);
    return {
      id: parseNumber(record["window-id"], "AeroSpace window id"),
      appBundleId: parseString(record["app-bundle-id"], "AeroSpace app bundle id"),
      workspace: parseString(record.workspace, "AeroSpace workspace"),
      fullscreen: parseBoolean(record["window-is-fullscreen"], "AeroSpace fullscreen state"),
      title: parseString(record["window-title"], "AeroSpace window title"),
    };
  });
}

function parseRecord(value: unknown): Record<string, unknown> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw new Error("AeroSpace window must be an object");
  }
  return value as Record<string, unknown>;
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

function delay(milliseconds: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}
