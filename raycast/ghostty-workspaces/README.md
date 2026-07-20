# Ghostty Workspaces

A local Raycast command for finding project workspaces and switching between live Ghostty windows managed by AeroSpace.

The command discovers `~/dotfiles` plus immediate, non-hidden directories and symlinks under `~/code`. It reads Ghostty's native AppleScript model to show open windows, including their tab and pane counts. Selecting an open workspace focuses its existing window. Selecting an unopened project creates exactly one Ghostty window rooted there, moves it to an AeroSpace workspace named after the project, and enables AeroSpace fullscreen.

## Install in Raycast

Install the dependencies and register the local extension once:

```fish
cd ~/dotfiles/raycast/ghostty-workspaces
nub install
nub run dev
```

Wait for `ready - built extension successfully`, then stop the watcher with `Ctrl+C`. The development command installs or updates the local extension; it does not need to keep running. Raycast retains the extension across Raycast and macOS restarts as long as this source directory remains in place.

After changing the extension, run `nub run dev` again and stop it once the new build is ready.

Run **Switch Ghostty Workspace** in Raycast. Assign a global hotkey from Raycast Settings → Extensions → Ghostty Workspaces.

Raycast global shortcuts are single chords, so an exact sequential `Ctrl+A`, then `F` binding needs a small Karabiner-Elements or Hammerspoon bridge that opens this command's Raycast deeplink.

## Actions

- `Return`: focus an open Ghostty workspace or create a new one
- `Cmd+R`: refresh the live window list
- `Cmd+K`: show all actions, including Finder and copy-path actions
