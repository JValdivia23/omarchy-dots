# Microsoft Surface Go 3 Display Scaling & Touch Configuration

- **ID**: `03-surface-go3-scaling-and-touch`
- **Category**: `Display / Input / Hardware`
- **Hardware / Target**: `Microsoft Surface Go 3`
- **Severity**: `Info`

---

## Context
1. **10.5" 1920x1280 Display**: At 1x scale UI is too small; at 2x scale logical resolution is 960x640 (tight for tiled terminals). Setting `scale = 1.6` gives a clean `1200x800` logical workspace (`1920 / 1.6 = 1200`, `1280 / 1.6 = 800`) while keeping `GDK_SCALE=2` for XWayland/GTK2 apps.
2. **Touchscreen & Stylus (`ELAN9038:00 04F3:2A1C`)**: Surface Go 3 uses standard I2C-HID (`ELAN9038`) rather than Intel Precise Touch (`iptsd`), and does not have a Surface Book DTX detachable base (`surface-dtx-daemon`). Touch, stylus, Type Cover, and battery reporting (`BAT1` via `surface_aggregator`) work out of the box on the stock Omarchy kernel.
3. **Trackpad Scroll Factor**: Precision Type Cover touchpad uses `scroll_factor = 0.4` and `drag_3fg = 0` so two-finger scrolling and 3-finger workspace swipes feel smooth.

## Verification
```bash
hyprctl monitors
```
Confirm `eDP-1` is `1920x1280@60.00000` at `scale: 1.60`.

## Related References
- [`~/.config/hypr/monitors.lua`](file:///home/user/.config/hypr/monitors.lua)
- [`~/.config/hypr/input.lua`](file:///home/user/.config/hypr/input.lua)
