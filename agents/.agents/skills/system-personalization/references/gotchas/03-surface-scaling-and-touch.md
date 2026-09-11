# Microsoft Surface Display Scaling & Touchscreen Configuration

- **ID**: `03-surface-scaling-and-touch`
- **Category**: `Display / Input / Hardware`
- **Hardware / Target**: `Microsoft Surface Book 3 (and Surface HiDPI devices)`
- **Severity**: `Warning`

---

## Symptom
1. **Tiny UI / Blurry Fonts**: On the Surface Book 3 native 3000x2000 resolution display, desktop elements and text appear microscopic at 1x scaling. Applying fractional scaling (e.g. 1.33x, 1.5x) in Wayland can introduce subpixel font blurring or XWayland scaling artifacts.
2. **Touchscreen / Stylus Unresponsive**: Touching the screen or drawing with the Surface Pen produces no cursor movement or touch response.
3. **Hyperactive Trackpad Scrolling**: Scrolling with two fingers on the precision touchpad moves at lightning speed, flinging through hundreds of lines with the slightest swipe.

## Root Cause
- **HiDPI Scaling**: The Surface Book 3 panel is 3000x2000 pixels with an aspect ratio of 3:2 on a 13.5" or 15" screen. Integer 2x scaling (`scale = 2` and `GDK_SCALE=2`) produces crisp, pixel-perfect rendering without fractional scaling interpolation overhead.
- **Touchscreen Daemon**: Surface hardware relies on Intel Precise Touch and Stylus (IPTS) IP. The touchscreen is driven through the user-space `iptsd` daemon communicating with raw HID devices (`/dev/hidraw*`). If `iptsd` is inactive, touch and stylus inputs are not translated to Linux evdev events.
- **Trackpad Resolution**: The Surface precision trackpad reports extremely fine-grained scroll delta steps. Hyprland's default `scroll_factor = 1.0` amplifies these events excessively.

## Solution & Fix

### 1. Monitor Scaling Configuration (`~/.config/hypr/monitors.lua`)
Use integer 2x scaling and export `GDK_SCALE=2`:
```lua
local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 2

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "eDP-1", mode = "3000x2000@60", position = "0x0", scale = omarchy_monitor_scale })
```

### 2. Touchpad Scroll Factor & Gestures (`~/.config/hypr/input.lua`)
Tame touchpad scroll sensitivity by setting `scroll_factor = 0.4` and disable 3-finger drag (`drag_3fg = 0`) to prevent interference with workspace swipe gestures:
```lua
hl.config({
  input = {
    touchpad = {
      natural_scroll = true,
      clickfinger_behavior = true,
      scroll_factor = 0.4,
      disable_while_typing = false,
      drag_3fg = 0,
    },
  },
})

-- Enable smooth 3-finger workspace switching
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
```

### 3. IPTSD Daemon Verification
Ensure the `iptsd` systemd service is active:
```bash
systemctl status "iptsd@*"
```
If not active, enable and start the appropriate instance:
```bash
sudo systemctl enable --now iptsd@dev-hidraw4.service
```

## Verification
- Test two-finger trackpad scrolling in Kitty and browser; verify scrolling is smooth and controlled.
- Touch the screen and verify touch events register accurately at fingertip position without offset.
- Check active monitor scaling:
  ```bash
  hyprctl monitors
  ```

## Related References
- [`~/.config/hypr/monitors.lua`](file:///home/jmvp/.config/hypr/monitors.lua)
- [`~/.config/hypr/input.lua`](file:///home/jmvp/.config/hypr/input.lua)
- Linux Surface Project: `https://github.com/linux-surface/linux-surface`
