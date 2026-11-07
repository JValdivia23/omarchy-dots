# Verify Plugin Code Reloads Before Debugging Click Routing

- **ID**: `15-shell-plugin-cached-reloads`
- **Category**: System / Wayland
- **Hardware / Target**: Universal (Omarchy shell / Quickshell)
- **Severity**: Warning

---

## Symptom

A newly added minimized-windows bar widget appears and detects parked windows, but clicking its icon does not open the popup. `omarchy plugin list --json` reports it enabled, and plugin rescans return successfully without loading newly added diagnostic code.

## Root Cause

In the observed long-running shell session, rescans refreshed plugin registrations but retained cached QML code. An added diagnostic IPC handler stayed unavailable after rescans. Switching temporarily to a new entry-point filename produced `File name case mismatch` despite the file existing with the correct name. Restarting the shell loaded the current code and restored popup opening without changing click handling.

The exact stale object responsible for the original missed click was not isolated. Do not assume every unresponsive widget has this cause, or that an enabled plugin has loaded the latest source. User plugins here are directory symlinks into `~/dotfiles/`; watcher and loader behavior must be verified rather than assumed.

## Solution & Fix

1. Check the widget's actual geometry and relevant QML errors before changing event routing.
2. Reproduce interaction with mouse events against the real QML in an isolated offscreen harness where possible. Omarchy's full `PanelWindow` bar cannot run with the offscreen backend; test its compositor-dependent behavior live with permission.
3. Try the documented rescan. If code changes demonstrably remain unloaded, ask before restarting the shell. It briefly reloads bar/notification services, not application windows. Do not reset the configuration or edit `/usr/share/omarchy/`.
4. Remove temporary diagnostics and reload the clean code before finishing.

```bash
omarchy-shell shell debugBarGeometry
omarchy plugin list --json
omarchy-shell shell rescanPlugins

# With user approval when the rescan does not load current code:
omarchy restart shell
```

## Verification

- A diagnostic handler present in the source became callable only after the shell restart.
- Live state confirmed the minimized button was registered, enabled, and hit-testable, with an anchor window.
- The user confirmed that clicking the icon opened the popup after the restart. Logs recorded left-button presses and popup-open transitions.
- Remove diagnostic code and verify its IPC target is absent after loading the clean version.

## Related References

- [`../config-paths.md`](../config-paths.md)
- [`07-omarchy-bar-accidental-drag-removal.md`](07-omarchy-bar-accidental-drag-removal.md)
- Built-in `omarchy` skill: `plugins.md` (user plugins and reload commands)
- Built-in `omarchy-app` skill: real-QML offscreen interaction testing
