# VeilShell gap gestures on the XPS

- **ID**: `04-veilshell-gap-gestures`
- **Category**: Hyprland / Input
- **Hardware / Target**: XPS 13 DX13260, `eDP-1`
- **Severity**: Info

## Symptom

The first touchscreen trial did not open panels with a swipe, even though
Home opened from `veilctl`. After releasing the gap input area, the software
renderer made the panels lag behind the finger. The GPU trial felt smoother
on the physical touchscreen.

## Root Cause

Hyprland's native border drag can use the same pixels as the 10 px outer gaps.
VeilShell leaves the strips off with `resize_on_border = true`. Separately,
CPU rendering at `2560×1600` was too slow for a fluid reveal; an isolated
test at the same resolution measured about 116 ms between Home animation
frames on CPU versus 8 ms on the GPU.

## Solution

`veilshell-gaps.service` starts the already-built VeilShell on the next
Omarchy/Hyprland login, on `eDP-1`, using `--renderer wgpu`. It only changes
the runtime border-resize setting once the GPU backend is ready. If the strips
never arm, the service stops and restores the starting resize setting.
Stopping the service also restores it in the starting compositor. No
Hyprland config, layout, or keybinding files are changed.

A Hyprland config reload can re-enable border resizing and disarm the strips.
If that happens and gestures are still wanted, restart `veilshell-gaps.service`.
Use `systemctl --user disable --now veilshell-gaps.service` to undo autostart
and stop the overlay. Keep the release binaries in
`~/Projects/veilshell/target/release/`; this setup does not install them.

## Verification

After logging in to Omarchy:

```bash
systemctl --user status veilshell-gaps.service
env VEILSHELL_SOCKET="$XDG_RUNTIME_DIR/veilshell-gaps/control.sock" \
  ~/Projects/veilshell/target/release/veilctl status
```

Expect `renderer: wgpu-sdf` and nonzero strip depths on the desktop.
Start a finger swipe in the outer gap below the bar or above the bottom
edge; gaps between windows are not gesture targets.

## Related References

- [VeilShell overlay gap behavior and tests](https://github.com/veilshell/veilshell/blob/5397b27/docs/tablet/overlay-gaps.md)
