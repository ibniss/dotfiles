# Ghostty Workspaces

A local Raycast command for finding project workspaces and switching between live Ghostty windows managed by AeroSpace.

The command discovers `~/dotfiles` plus immediate, non-hidden directories and symlinks under `~/code`. It reads Ghostty's native AppleScript model to show open windows, including their tab and pane counts. Selecting an open workspace focuses its existing window. Selecting an unopened project creates exactly one Ghostty window rooted there, moves it to an AeroSpace workspace named after the project, and enables AeroSpace fullscreen.

## Run locally

```fish
nub install
nub run dev
```

Then run **Switch Ghostty Workspace** in Raycast. Assign a global hotkey from Raycast Settings → Extensions → Ghostty Workspaces.

Raycast global shortcuts are single chords, so an exact sequential `Ctrl+A`, then `F` binding needs a small Karabiner-Elements or Hammerspoon bridge that opens this command's Raycast deeplink.

## Actions

- `Return`: focus an open Ghostty workspace or create a new one
- `Cmd+R`: refresh the live window list
- `Cmd+K`: show all actions, including Finder and copy-path actions
