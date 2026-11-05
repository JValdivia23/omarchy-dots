# EdgePad Graphical Session Target & OSD Environment

- **ID**: `08-edgepad-graphical-session-target`
- **Category**: `Input / Wayland / System`
- **Hardware / Target**: `Universal (Laptops running EdgePad)`
- **Severity**: `Warning`

---

## Symptom

When using EdgePad edge gestures (e.g. sliding the right edge for volume or left edge for brightness), the hardware volume and backlight levels adjust as expected, but the native Omarchy On-Screen Display (OSD) pop-up menu never appears. In addition, `journalctl --user -u edgepad.service` may report:

```text
jq: parse error: Invalid numeric literal at line 1, column 28
```

## Root Cause

1. **Systemd Target Ordering**: `edgepad.service` was initially enabled under `default.target`. At system startup, `user@<uid>.service` reaches `default.target` before the user logs into the graphical Wayland session.
2. **Missing Wayland & Omarchy Session Environment**:
   - `omarchy-shell` powers `omarchy-osd`. In quiet mode (`-q`), `omarchy-shell` immediately checks `[[ -n ${OMARCHY_PATH:-} ]]` and exits silently with status 0 if not defined.
   - `omarchy-brightness-display` invokes `hyprctl monitors -j` via `omarchy-hyprland-monitor-focused-apple`. Without `HYPRLAND_INSTANCE_SIGNATURE`, `hyprctl` outputs `HYPRLAND_INSTANCE_SIGNATURE not set! (is hyprland running?)`, causing `jq` to fail parsing.
3. **Static Process Environment**: In Linux/systemd, environment variables imported later into `systemd --user` by UWSM/Hyprland (such as `WAYLAND_DISPLAY`, `HYPRLAND_INSTANCE_SIGNATURE`, and `OMARCHY_PATH`) are NOT dynamically pushed into already running daemon processes.

## Solution & Fix

1. **Bind `edgepad.service` to `graphical-session.target`**:
   In `core/.config/systemd/user/edgepad.service`:
   ```ini
   [Unit]
   Description=edgepad touchpad edge gesture daemon
   Documentation=https://github.com/assembledev/edgepad
   After=graphical-session.target
   PartOf=graphical-session.target

   [Service]
   Type=notify
   NotifyAccess=main
   TimeoutStartSec=45s
   ExecStart=%h/.local/bin/edgepad daemon --config %h/.config/edgepad/edgepad.toml
   ExecReload=kill -HUP $MAINPID
   Restart=on-failure
   RestartSec=1s
   Environment=PATH=%h/.local/bin:/usr/share/omarchy/bin:/usr/local/bin:/usr/bin:/bin
   Environment=OMARCHY_PATH=/usr/share/omarchy

   [Install]
   WantedBy=graphical-session.target
   ```

2. **Reload and Re-enable the User Unit**:
   ```bash
   systemctl --user daemon-reload
   systemctl --user disable edgepad.service
   ln -sf ~/dotfiles/core/.config/systemd/user/edgepad.service ~/.config/systemd/user/edgepad.service
   systemctl --user enable --now edgepad.service
   ```

## Verification

1. Check that the active daemon inherits `OMARCHY_PATH`, `WAYLAND_DISPLAY`, and `HYPRLAND_INSTANCE_SIGNATURE`:
   ```bash
   xargs -0 -L1 -a /proc/$(pgrep -f "edgepad daemon")/environ | grep -E "OMARCHY|WAYLAND|HYPRLAND"
   ```
2. Slide along the right edge of the touchpad to verify that the volume OSD pop-up appears on screen.
3. Slide along the left edge of the touchpad to verify that the display brightness OSD pop-up appears on screen.

## Related References
- [`06-edgepad-uaccess-uinput.md`](06-edgepad-uaccess-uinput.md)
- [`references/config-paths.md`](../config-paths.md)
