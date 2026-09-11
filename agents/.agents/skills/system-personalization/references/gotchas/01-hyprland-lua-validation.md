# Hyprland Lua Configuration Error Diagnostics

- **ID**: `01-hyprland-lua-validation`
- **Category**: `Hyprland`
- **Hardware / Target**: `Universal`
- **Severity**: `Critical`

---

## Symptom
After modifying a Hyprland configuration file in `~/.config/hypr/` (such as `bindings.lua`, `input.lua`, `monitors.lua`, or `looknfeel.lua`), Hyprland displays a bright red error overlay bar across the top of the monitor, or a desktop error appears. Checking `journalctl -xe`, `journalctl -u hyprland`, or `systemctl --user status hyprland` reveals no configuration parse errors or line-by-line syntax diagnostics.

## Root Cause
Hyprland parses and executes its configuration inside a native Lua runtime environment. When Lua syntax errors, unknown keys, or invalid configuration tables are encountered, Hyprland captures these internally and exposes them strictly through its compositor IPC socket and an on-screen visual overlay. It does **NOT** write configuration validation errors to systemd's journald or syslog. Relying on `journalctl` to diagnose desktop configuration errors will produce false negatives.

## Solution & Fix
ALWAYS use Hyprland's dedicated IPC diagnostic command as the first step whenever configuration errors or unexpected behavior occur:

```bash
# Force a reload of the compositor configuration
hyprctl reload

# Inspect all active configuration parsing errors
hyprctl configerrors
```

If the configuration is valid, `hyprctl configerrors` returns `ok` or produces no output. If errors exist, it outputs the exact absolute file path, the problematic line number, and a detailed compiler message (e.g. `unknown field 'tap_to_drag'`, `')' expected near 'CTRL'`).

### Common Pitfalls in Hyprland Lua Mode
1. **Invalid Touchpad Keys**: Keys like `tap_to_drag` or `tap-to-drag` under `input.touchpad` are invalid in modern Hyprland and will trigger a red banner. Tap-to-drag is handled automatically when `tap_to_click = true`.
2. **Missing Quotes on IPC Dispatches**: Running `hyprctl dispatch sendshortcut CTRL, U, activewindow` breaks Lua parsing. Always format dispatches using native Lua calls:
   ```bash
   hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "CTRL", key = "u", window = "activewindow" })'
   ```
3. **Omitting Window Target**: In `hl.dsp.send_shortcut`, omitting `window = "activewindow"` may cause the key event to be dropped.

## Verification
Run:
```bash
hyprctl configerrors
```
Confirm the output is completely clear of error messages.

## Related References
- [`references/config-paths.md`](../config-paths.md)
- [`~/.config/hypr/bindings.lua`](file:///home/jmvp/.config/hypr/bindings.lua)
- [`~/.config/hypr/input.lua`](file:///home/jmvp/.config/hypr/input.lua)
