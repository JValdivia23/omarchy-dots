# Gotcha: Dell XPS 13 (DX13260) Display Scaling & Touchpad Configuration

- **Category**: Display / Input
- **Target Hardware**: Dell XPS 13 (`XPS 13 DX13260` — Intel Wildcat Lake, LG Display `2560x1600@120Hz`)
- **Severity**: Info

## Problem / Context
The Dell XPS 13 (`DX13260`) ships with a 13.4" `2560x1600@120Hz` internal panel (`eDP-1`), an I2C precision touchpad (`gxtp7863:00-27c6:0d4c-touchpad`), and a touchscreen (`lxst2024:00-1fd2:5010`). Without a dedicated `xps` profile, generic laptop detection previously fell back to stowing `profiles/desktop`, which forced `scale = 1` (tiny UI on a 226 PPI panel) and disabled `natural_scroll` and touchpad gestures.

## Cause
`install.sh` previously lacked a dedicated `xps` profile and mapped generic laptops to `("desktop" "laptop")`, stowing `profiles/desktop/.config/hypr/{monitors,input}.lua`.

## Solution
1. Dedicated `profiles/xps/` profile auto-detected when `SYS_PRODUCT_NAME` matches `XPS`.
2. `profiles/xps/.config/hypr/monitors.lua` explicitly sets `eDP-1` to `2560x1600@120` at `scale = 1.25` (giving an integer-aligned 2048x1280 viewport for high productivity and natural font proportions), while leaving external monitors on `preferred` / `auto`.
3. `profiles/xps/.config/foot/foot.ini` configures `JetBrainsMono Nerd Font:size=13` (equivalent to the initial 16px physical font size at 2.0x scale) and system UI font is set to 14 (`Adwaita Sans 14` in GTK and `base-size = 14` in `shell.toml`) to maintain balanced readability across terminal and desktop.
4. `profiles/xps/.config/hypr/input.lua` enables `natural_scroll = true`, `tap_to_click = true`, `clickfinger_behavior = true`, `scroll_factor = 0.4`, and 3/4-finger workspace/fullscreen/close gestures.

## Verification
```bash
hyprctl monitors
hyprctl getoption input:touchpad:natural_scroll
hyprctl configerrors
```
