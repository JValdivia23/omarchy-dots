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
   For background agent commands requiring sudo, use `pkexec <cmd>` to trigger Omarchy's graphical floating password dialog. For interactive commands, use `omarchy-launch-floating-terminal-with-presentation "<cmd>"`.

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
| `themes/aether/` | Generated adaptive Aether theme | Managed by `omarchy-aether`, with regular runtime `colors.toml` and native `preview.png`; choose Aether through Appearance → Theme. Do not Stow generated files. |
| `hooks/` | Automation event hooks | Executable scripts in event subdirectories (e.g. `theme-set.d/`, `workspace-changed.d/`). Install via `omarchy hook install <event> <script>`. |
| `plugins/` | Cloned or custom Quickshell plugins | Clone stock plugins via `omarchy plugin clone <plugin>` to edit them locally in user space without modifying vendor files. |

The universal Aether menu preference lives at `~/.config/omarchy-aether/menu.json` (backed by `core/`). Explicit `omarchy-aether integrate --yes` merges it into the existing native menu file with a backup; it does not replace the Theme action. With Aether active, Appearance → Background uses cached random candidates from the indexed library at `~/Pictures/Wallpapers/walls`. Other themes keep the stock background selector/setter. The standalone source repository is `~/Projects/omarchy-aether`; generated caches are under `~/.cache/omarchy-aether/`.

---

## Terminal Emulators (`~/.config/`)

Omarchy Quattro supports multiple modern Wayland terminals.

| Path | Emulator | Reload / Apply Command |
|------|----------|------------------------|
| `~/.config/kitty/kitty.conf` | Kitty | `omarchy restart terminal` or `kill -SIGUSR1 $(pidof kitty)` |
| `~/.config/alacritty/alacritty.toml` | Alacritty | Hot-reloads on save or `omarchy restart terminal` |
| `~/.config/foot/foot.ini` | Foot | New windows read the config; native theme switches retint existing windows through `omarchy theme set-foot`. |
| `~/.config/ghostty/config` | Ghostty | Hot-reloads on save or `omarchy restart terminal` |

The universal `~/.config/omarchy/hooks/theme-set.d/20-opencode-system-refresh` hook runs `~/.local/bin/omarchy-opencode-theme-refresh` after terminal retints. It requests fresh terminal-derived colors from already-open OpenCode TUIs, including npm/mise's `opencode.exe`, without changing app settings or signaling the background service. See [gotcha 17](gotchas/17-opencode-exe-theme-refresh.md).

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
