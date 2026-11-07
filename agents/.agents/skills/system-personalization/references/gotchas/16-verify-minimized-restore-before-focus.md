# Verify a Minimized Window Moved Before Focusing It

- **ID**: `16-verify-minimized-restore-before-focus`
- **Category**: Wayland / Input
- **Hardware / Target**: Universal (Hyprland / Omarchy)
- **Severity**: Warning

---

## Symptom

Windows appear above the normal workspace but remain on `special:minimized`, so hiding the special workspace makes them disappear again. The user reported this during bar-widget restore testing. The original overlay was not reproduced with a disposable window; both the original direct commands and a live popup-row selection moved the test window into a normal workspace.

## Root Cause

Focusing a window is not equivalent to moving it into the normal workspace. If it remains on a special workspace, focusing it can reveal that workspace and its other parked windows. A detached command chain cannot safely infer a successful move from a dispatcher's exit status alone; errors may be returned as text, and an apparently successful move can leave membership unchanged.

This is a defensive restore invariant, not a confirmed explanation for the original report. Keep the distinction between popup opening, successful window movement, and special-workspace visibility when diagnosing the UI.

## Solution & Fix

The bar calls `hypr-restore-window <address> <workspace-id>`. It validates arguments and source state, performs the same move as the floating dock, verifies `.workspace.id` through `hyprctl clients -j`, and only then focuses and raises the window. It conditionally closes an already-visible minimized overlay, never blindly toggling a closed one open. Animation overrides are cleaned up even after errors.

The QML runs the helper as a checked `Process`, avoids duplicate in-flight restores, and shows failed-move details as plain text in the popup. No packaged Omarchy files are modified.

The interaction contract is simple: the bar icon toggles only the list; selecting a row restores only that window into the current workspace. The floating dock shares the same minimized pool.

## Verification

```bash
python -B -m unittest discover -s tests -p 'test_minimized_restore.py' -v
hyprctl clients -j
hyprctl monitors -j
```

Tests cover a successful move, an `ok` reply without movement, a rejected move with exit status 0, stale/missing windows, invalid arguments, conditional overlay dismissal, and actual offscreen QML mouse interactions with mocked data/actions. They also check plain-text rendering of markup-shaped titles and errors.

For live verification, use only an approved disposable window. Check that its workspace ID is positive and is the workspace selected when restoring, that `specialWorkspace` remains empty, and that unselected windows remain parked. A user may switch back to the chat workspace before diagnostics are read, so the monitor's later active workspace alone is not proof of an incorrect destination.

## Related References

- [`15-shell-plugin-cached-reloads.md`](15-shell-plugin-cached-reloads.md)
- [`../keybindings.md`](../keybindings.md)
- User plugin: `core/.config/omarchy/plugins/jairo.minimized-windows/README.md`
- Stock reference (read-only): `/usr/share/omarchy/shell/plugins/dock/Dock.qml`
