# Wayland On-Screen Virtual Keyboard with Fcitx5

- **ID**: `07-fcitx5-wayland-virtual-keyboard`
- **Category**: `Input / Wayland`
- **Hardware / Target**: `Touchscreen devices (Surface Book, 2-in-1s, Tablets)`
- **Severity**: `Warning`

---

## Symptom
When detaching the keyboard on a Surface Book or folding a 2-in-1 convertible into tablet mode, the physical keyboard is no longer accessible. Tapping text input fields (such as browser address bars, search fields, or text editors) under Hyprland does not bring up an on-screen keyboard, making text input impossible without physically reattaching the base.

## Root Cause
Minimal Wayland compositors like Hyprland do not include a built-in graphical on-screen keyboard by default. Wayland text input relies on the `text-input-v3` or `input-method-v2` protocols implemented by dedicated input method engines such as `fcitx5`.

Without a keybinding or trigger daemon to toggle the input panel, the virtual keyboard remains hidden.

## Solution & Fix

### 1. Toggle Input Method Panel via CLI
Fcitx5 provides the `fcitx5-remote` utility to query and toggle input states:
```bash
# Toggle input method panel Active / Inactive
fcitx5-remote -t
```

### 2. Hyprland Keybinding (`~/.config/hypr/bindings.lua`)
Bind `SUPER + SHIFT + U` to toggle the virtual keyboard panel on demand:
```lua
-- Toggle virtual keyboard input method panel (fcitx5).
-- Enables touchscreen typing after iptsd + surface kernel setup.
-- Note: SUPER+SHIFT+O is bound to Obsidian by default, so U is used instead.
o.bind("SUPER + SHIFT + U", "On-screen keyboard", "fcitx5-remote -t")
```

### 3. Ensure Fcitx5 is Running in Compositor Session
Verify that `fcitx5` starts automatically with the Wayland session:
```bash
# Check running processes
ps aux | grep -i fcitx5

# Start manually if not running
fcitx5 -d --replace
```

## Verification
1. Press `SUPER + SHIFT + U` (or execute `fcitx5-remote -t` in a terminal).
2. Verify that the fcitx5 input panel activates and allows on-screen text input directly into Wayland applications.

## Related References
- [`~/.config/hypr/bindings.lua`](file:///home/jmvp/.config/hypr/bindings.lua)
- [`03-surface-scaling-and-touch.md`](03-surface-scaling-and-touch.md)
- [`04-surface-dtx-tablet-detach.md`](04-surface-dtx-tablet-detach.md)
