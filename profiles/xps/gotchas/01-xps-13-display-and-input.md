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
3. `profiles/xps/.config/foot/foot.ini` configures `JetBrainsMono Nerd Font:size=13` and system UI font is set to 13 (`Adwaita Sans 13` in GTK and `base-size = 13` in `profiles/xps/.config/omarchy/shell.toml`) strictly isolated to the `xps` profile.
4. `profiles/xps/.config/hypr/input.lua` enables `natural_scroll = true`, `tap_to_click = true`, `clickfinger_behavior = true`, `scroll_factor = 0.4`, and 3/4-finger workspace/fullscreen/close gestures.
5. **Touchscreen Evdev Discovery & Permissions (`LXST2024:00 1FD2:5010`)**:
   - Unlike Surface devices (which expose `"IPTSD Virtual Touchscreen"` via `iptsd`), the XPS 13 internal touchscreen is an I2C HID device whose `/sys/class/input/event*/device/name` is `"LXST2024:00 1FD2:5010"` (no `"touchscreen"` substring), identified by kernel property bit `INPUT_PROP_DIRECT` (`properties = 2`) and udev `ID_INPUT_TOUCHSCREEN=1`.
   - `profiles/xps/setup.sh` installs `/etc/udev/rules.d/70-touchscreen-uaccess.rules` (`SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT_TOUCHSCREEN}=="1", TAG+="uaccess"`) so unprivileged user-space tools (such as `SideQuest` touch-to-mouse bridges) receive active-seat ACL access (`uaccess`) without requiring membership in the privileged `input` group.
6. **Copilot Key Hardware Chord (`SUPER + SHIFT + code:201`) & `altwin:menu_win` Gotcha**:
   - The physical Copilot key on the Dell XPS 13 (`DX13260`) transmits the 3-key hardware chord `Left Super + Left Shift + F23` (evdev `KEY_F23 = 193`, XKB `code:201`), which upstream Omarchy binds to `{ menu = "root" }` (`Omarchy menu`).
   - Overridden in `core/.config/hypr/bindings-common.lua` by unbinding `SUPER + SHIFT + code:201` and binding it to `hl.dsp.send_shortcut({ mods = "", key = "Menu", window = "activewindow" })` so tapping the Copilot key opens the active application's native right-click context menu.
   - **Critical Gotcha (`altwin:menu_win` breaks `send_shortcut` for `Menu`)**: Do NOT enable `altwin:menu_win` in `input:kb_options` when using `hl.dsp.send_shortcut({ key = "Menu" })`. `altwin:menu_win` remaps XKB `<COMP>` (`code:135`, the only keycode producing `XKB_KEY_Menu`) to `Super_R`. Because `send_shortcut` resolves keysyms by scanning the active keyboard's XKB keymap (`hl-virtual-keyboard-fcitx5`), removing `Menu` from the keymap causes `send_shortcut` to fail at runtime with `send_shortcut: key not found`. If `kb_options` is ever changed, restart `fcitx5 -r -d` so `hl-virtual-keyboard-fcitx5` reloads the keymap.

7. **Copilot Key Dual-Role Modifier via `keyd` (`overload(meta, compose)`)**:
   - Because the hardware firmware emits `Left Super + Left Shift + F23`, holding Copilot and pressing another key physically held `Shift`, turning `Super + Enter` into `Super + Shift + Enter` (opening the browser).
   - Configured `keyd` in `profiles/xps/setup.sh` (`/etc/keyd/default.conf`) with `leftmeta+leftshift+f23 = overload(meta, compose)` and deployed `/etc/libinput/local-overrides.quirks` (`AttrKeyboardIntegration=internal`) to preserve laptop palm rejection.
   - **`compose` vs `menu` in `keyd` Gotcha**: In keyd, key name `menu` emits evdev `KEY_MENU` (139), which XKB maps to `XF86MenuKB` (ignored by applications). Key name `compose` emits evdev `KEY_COMPOSE` (127), which XKB maps to `<COMP>` (135) with keysym `Menu`—the true context menu key recognized across Flea, Zen Browser, GTK, Qt, and Hyprland.
   - Result: Tapping Copilot emits `compose` $\rightarrow$ `Menu` (Context Menu in active window), while holding Copilot and pressing another key cleanly emits `meta` (`Super`), allowing `Copilot + Enter` for Terminal, `Copilot + Space` for launcher, etc. Strictly isolated to the `xps` profile.

## Verification
```bash
hyprctl monitors
hyprctl getoption input:touchpad:natural_scroll
getfacl /dev/input/event5
systemctl status keyd
hyprctl configerrors
```
