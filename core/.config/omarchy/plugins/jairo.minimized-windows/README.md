# Minimized windows

The bar and Omarchy's floating dock use the same minimized-window pool.

- **Super+M:** minimize the focused window, from either a tiled or floating workspace.
- **Click the bar icon:** open the list of minimized windows.
- **Click a row in the list:** restore that window into the workspace currently in front of you, as the floating dock does. Other minimized windows stay hidden.
- **Click the bar icon again or click outside:** dismiss the list, without restoring anything.

Restoring is not a scratchpad toggle. A restored window belongs to the normal workspace; no additional shortcut is needed to show or hide a special workspace. Omarchy's existing workspace-mode rules handle its tiled/floating state, just as with dock restores.

`~/.local/bin/hypr-restore-window` performs the dock-style move and checks actual workspace membership before focusing the window. A rejected or ineffective move reports an error in the popup instead of focusing a window that is still parked. An already-visible `special:minimized` overlay is closed only after a successful move; unrelated special workspaces are not toggled by the helper.

From `~/dotfiles`, run the mocked helper tests and real-QML offscreen interaction tests with:

```bash
python -B -m unittest discover -s tests -p 'test_minimized_restore.py' -v
```

The QML tests require Omarchy/Quickshell. They mock window/monitor data and the restore helper, never dispatching to real application windows. The complete layer-shell bar and compositor-side workspace membership still need live verification.
