# Configuration Paths & Architecture

Comprehensive guide to configuration files on Omarchy Quattro, their functional roles, and precise editing rules.

---

## Critical Safety Rules

1. **NEVER modify `/usr/share/omarchy/`.**
   This directory is owned by the system package manager. Any edits here will be overwritten on the next `omarchy update`. Reading is safe and encouraged for inspecting stock commands, themes, and default Lua configs.
2. **Always edit user configurations in `~/.config/`.**
   Use targeted edits (`replace_file_content`, patch, append). Never overwrite whole configuration files blindly, as this deletes existing user customizations and theme hooks.
3. **Hyprland Lua validation.**
   Hyprland on Omarchy Quattro uses Lua configuration files. After making changes, always test and validate using:
   ```bash
   hyprctl reload
   hyprctl configerrors
   ```
4. **Elevated privileges.**
   For commands requiring sudo, launch an interactive terminal (`kitty -e bash -c "sudo <cmd>; read"`) so the user can provide credentials securely.

---

## Hyprland Configuration (`~/.config/hypr/`)

Omarchy Quattro loads system defaults from `/usr/share/omarchy/default/hypr/`, followed by user overrides in `~/.config/hypr/`.

| File | Purpose | Customization & Edit Rules |
|------|---------|----------------------------|
| `hyprland.lua` | Compositor entrypoint | Sources Omarchy defaults, then loads user modules. Append `require(...)` statements or global options. |
| `bindings.lua` | Keyboard shortcuts & hardware keys | Use `o.bind("MOD + KEY", "Description", action)`. If rebinding an existing key, call `hl.unbind("MOD + KEY")` first. |
| `monitors.lua` | Display panels, resolutions, and scales | Set `hl.monitor({ output = "...", mode = "...", position = "...", scale = ... })` and export `hl.env("GDK_SCALE", ...)`. |
| `input.lua` | Touchpad, mouse, gestures, cursor options | Use `hl.config({ input = { ... } })` and `hl.gesture({ fingers = N, direction = "...", action = "..." })`. |
| `looknfeel.lua` | Visual styling: gaps, borders, rounding, blur, shadows | Edit decorative values inside `hl.config({ general = { ... }, decoration = { ... } })`. |
| `autostart.lua` | User applications launched on compositor boot | Append commands to run upon session startup. |
| `hyprsunset.conf` | Blue light filter / Night light schedule | Standard config syntax. Reload via `omarchy restart hyprsunset`. |
| `xdph.conf` | XDG Desktop Portal Hyprland settings | Screen sharing and screencopy portal configuration. Reloads on session login. |

---

## Omarchy Shell & Desktop Services (`~/.config/omarchy/`)

The Omarchy Shell is built with Quickshell, providing an ultra-responsive status bar, notification center, on-screen display (OSD), and menus.

| File / Directory | Purpose | Customization & Edit Rules |
|------------------|---------|----------------------------|
| `shell.json` | Status bar layout, widgets, and idle timers | Modify widget arrays under `bar.layout` (`left`, `center`, `right`) and idle timers (`idle.lock`, `idle.screensaver`). Hot-reloads on save, or run `omarchy restart shell`. |
| `extensions/omarchy-menu.jsonc` | Application launcher and menu structure | Hot-reloads on file save. |
| `themes/<custom-theme>/` | Custom user themes | Overlay `colors.toml`, icons, wallpapers, and fonts. Apply via `omarchy theme set <custom-theme>`. |
| `hooks/` | Automation event hooks | Executable scripts in event subdirectories (e.g. `theme-set.d/`, `workspace-changed.d/`). Install via `omarchy hook install <event> <script>`. |
| `plugins/` | Cloned or custom Quickshell plugins | Clone stock plugins via `omarchy plugin clone <plugin>` to edit them locally in user space without modifying vendor files. |

---

## Terminal Emulators (`~/.config/`)

Omarchy Quattro supports multiple modern Wayland terminals.

| Path | Emulator | Reload / Apply Command |
|------|----------|------------------------|
| `~/.config/kitty/kitty.conf` | Kitty | `omarchy restart terminal` or `kill -SIGUSR1 $(pidof kitty)` |
| `~/.config/alacritty/alacritty.toml` | Alacritty | Hot-reloads on save or `omarchy restart terminal` |
| `~/.config/foot/foot.ini` | Foot | Applied to newly opened windows |
| `~/.config/ghostty/config` | Ghostty | Hot-reloads on save or `omarchy restart terminal` |

---

## Shell & Command Environment

| Path | Purpose | Edit Rules |
|------|---------|------------|
| `~/.config/fish/config.fish` | Interactive Fish shell configuration | Add functions, environment exports, and aliases. Keep fish-compatible syntax. |
| `~/.local/bin/` | User executable binaries & helper scripts | Must have `chmod +x`. Precedence given over system paths in user session. |
| `~/.local/share/applications/` | User desktop entry files & Webapps | Custom `.desktop` launchers for PWAs (e.g. YouTube, AllAnime) and custom icons. |

---

## System Configuration (Requires Elevated Sudo)

| Path | Purpose | Safe Editing Pattern |
|------|---------|----------------------|
| `/etc/pacman.conf` | Arch Linux / Omarchy repositories | Edit with targeted diffs; preserve repository signing keys. |
| `/etc/fstab` | Filesystem mount definitions | Never overwrite; always verify UUIDs and mount options with `findmnt`. |
| `/etc/systemd/system/` | System-wide systemd services | Reload after changes using `sudo systemctl daemon-reload`. |
