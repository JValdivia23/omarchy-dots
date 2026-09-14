# Keyboard Shortcuts (Keybindings)

A comprehensive reference sheet of keyboard bindings on Omarchy Quattro (`omarchy` - Surface Book 3).

Configuration files:
- User overrides: [`~/.config/hypr/bindings.lua`](file:///home/jmvp/.config/hypr/bindings.lua)
- System defaults: `/usr/share/omarchy/default/hypr/bindings/`
- Interactive reference: Run `omarchy menu keybindings` or press `SUPER + K`

The primary modifier key is **`SUPER`** (Windows / Command key).

---

## Surface Book 3 & Hardware Functions

| Shortcut | Command / Action | Description |
|----------|------------------|-------------|
| `SUPER` + `D` | `surface-detach` | Request hardware latch release to detach tablet |
| `SUPER` + `R` | `surface-rotate` | Fast display transform rotation (0° → 90° → 270° → 0°) |
| `SUPER` + `SHIFT` + `U` | `fcitx5-remote -t` | Toggle on-screen virtual keyboard panel (Fcitx5) |
| `SUPER` + `ALT` + `K` | `~/.local/bin/hypr-toggle-altwin` | Toggle Alt / Super key swap (Mac vs PC layout) |
| `SUPER` + `ALT` + `BACKSPACE` | `omarchy-hyprland-window-transparency-toggle` | Toggle window transparency / opacity |
| `SUPER` + `/` | `omarchy monitor scale up` | Increase monitor scaling |
| `SUPER` + `ALT` + `/` | `omarchy monitor scale down` | Decrease monitor scaling |

---

## macOS-Style Navigation & Editing Overrides

Configured in `~/.config/hypr/bindings.lua` to provide smooth, familiar text editing:

| Shortcut | Action | Scope / Behavior |
|----------|--------|------------------|
| `CTRL` + `Left` / `Right` / `Up` / `Down` | Focus Window | Move window focus in directional grid |
| `CTRL` + `SHIFT` + `Left` / `Right` / `Up` / `Down` | Swap Window | Swap active window in directional grid |
| `SUPER` + `Left` | Line Start (Home) | Jump to beginning of line (repeating) |
| `SUPER` + `Right` | Line End (End) | Jump to end of line (repeating) |
| `SUPER` + `Up` | Document Start | Jump to top of document (`CTRL + Home`) |
| `SUPER` + `Down` | Document End | Jump to end of document (`CTRL + End`) |
| `SUPER` + `SHIFT` + `Left` | Select to Line Start | Select to beginning of line (`SHIFT + Home`) |
| `SUPER` + `SHIFT` + `Right` | Select to Line End | Select to end of line (`SHIFT + End`) |
| `SUPER` + `SHIFT` + `Up` | Select to Doc Start | Select to top of document (`CTRL + SHIFT + Home`) |
| `SUPER` + `SHIFT` + `Down` | Select to Doc End | Select to bottom of document (`CTRL + SHIFT + End`) |
| `ALT` + `Left` / `Right` | Word Navigation | Jump one word left / right (`CTRL + Left/Right`) |
| `ALT` + `SHIFT` + `Left` / `Right` | Word Selection | Select one word left / right (`CTRL + SHIFT + Left/Right`) |
| `ALT` + `BackSpace` | Delete Word | Delete word backward (`CTRL + BackSpace`) |
| `ALT` + `Delete` | Delete Word Forward | Delete word forward (`CTRL + Delete`) |
| `SUPER` + `BackSpace` | Delete Line | Delete line backward (`CTRL + U` in terminal, `SHIFT + Home + BackSpace` in GUI) |
| `SUPER` + `Delete` | Delete Line Forward | Delete line forward (`CTRL + K` in terminal, `SHIFT + End + BackSpace` in GUI) |
| `SUPER` + `Z` | Undo | Undo last action (`CTRL + Z`) |
| `SUPER` + `SHIFT` + `Z` | Redo | Redo last action (`CTRL + SHIFT + Z`) |
| `SUPER` + `C` | Copy | Universal copy (`CTRL + C` in GUI, `CTRL + Insert` in terminal) |
| `SUPER` + `V` | Paste | Universal paste (`CTRL + V` in GUI, `SHIFT + Insert` in terminal) |
| `SUPER` + `X` | Cut | Universal cut (`CTRL + X`) |

---

## Window Management & Tiling

| Shortcut | Action | Description |
|----------|--------|-------------|
| `CTRL` + `Left` / `Right` / `Up` / `Down` | Focus Window | Move focus in directional grid |
| `CTRL` + `SHIFT` + `Left` / `Right` / `Up` / `Down` | Swap Window | Swap window position in directional grid |
| `SUPER` + `W` | Close Window | Close the focused window |
| `SUPER` + `F` | Fullscreen | Toggle fullscreen mode |
| `SUPER` + `ALT` + `F` | Full Width | Maximize window width |
| `SUPER` + `T` | Toggle Floating | Toggle floating / tiling state for active window |
| `SUPER` + `J` | Toggle Split | Toggle horizontal / vertical window split (dwindle) |
| `SUPER` + `P` | Pseudo Tiling | Toggle pseudo-tiled layout |
| `SUPER` + `O` | Pop-out & Pin | Float, center, and pin window across workspaces |
| `SUPER` + `L` | Toggle Layout | Switch between tiling layouts |
| `SUPER` + `G` | Group Windows | Toggle window grouping / tabs |
| `SUPER` + `SHIFT` + `Backspace` | Window Gaps | Toggle outer and inner window gaps |
| `CTRL` + `ALT` + `Delete` | Close All | Terminate all active windows |
| `SUPER` + Left Click Drag | Move Window | Drag floating window |
| `SUPER` + Right Click Drag | Resize Window | Resize floating window |

---

## Applications & Webapps

| Shortcut | Target Application | Launch Command |
|----------|--------------------|----------------|
| `SUPER` + `Return` | Terminal | Default terminal (Kitty / Foot) |
| `SUPER` + `SHIFT` + `Return` | Browser | Zen Web Browser (`zen-browser-bin`) |
| `SUPER` + `SHIFT` + `B` | Browser | Zen Web Browser |
| `SUPER` + `SHIFT` + `ALT` + `B` | Browser (Private) | Zen Browser in private browsing mode |
| `SUPER` + `SHIFT` + `F` | File Manager | Dolphin (`dolphin`) |
| `SUPER` + `SHIFT` + `Y` | YouTube | YouTube Web App via Brave Origin (`brave-origin`) |
| `SUPER` + `SHIFT` + `O` | Obsidian | Obsidian markdown notes |
| `SUPER` + `SHIFT` + `N` | Editor | Text editor (Neovim / GUI editor) |
| `SUPER` + `SHIFT` + `A` | ChatGPT | AI assistant webapp |
| `SUPER` + `SHIFT` + `D` | Docker | Docker CLI / Manager |
| `SUPER` + `SHIFT` + `M` | Music | Audio & music player |
| `SUPER` + `SHIFT` + `X` | X | Social webapp |

---

## System Menus & Quick Settings

| Shortcut | Menu / Action | Description |
|----------|---------------|-------------|
| `SUPER` + `Space` | Omarchy Menu | Open root application launcher |
| `SUPER` + `K` | Keybindings | Searchable keybindings browser overlay |
| `SUPER` + `Escape` | System Menu | Shutdown, restart, lock, suspend menu |
| `SUPER` + `CTRL` + `L` | Lock Session | Lock screen immediately |
| `SUPER` + `CTRL` + `V` | Clipboard | Clipboard history manager |
| `SUPER` + `CTRL` + `E` | Emojis | Emoji selector menu |
| `SUPER` + `CTRL` + `Space` | Wallpaper | Wallpaper and background selector |
| `ALT` + `Space` | Waypaper GUI | Floating wallpaper & dynamic theme picker (centered 65%x75%) |
| `SUPER` + `SHIFT` + `CTRL` + `Space` | Themes | Omarchy theme switcher |
| `SUPER` + `SHIFT` + `Space` | Top Bar | Toggle Quickshell top bar visibility |
| `SUPER` + `CTRL` + `A` | Audio Panel | Audio volume and output settings |
| `SUPER` + `CTRL` + `B` | Bluetooth Panel | Bluetooth device pairing and management |
| `SUPER` + `CTRL` + `D` | Display Panel | Display and monitor settings |
| `SUPER` + `CTRL` + `W` | Network Panel | Wi-Fi and network configuration |
| `SUPER` + `CTRL` + `P` | Power Panel | Power profiles and battery management |
| `SUPER` + `CTRL` + `C` | Capture Menu | Screenshot & screenrecording options |
| `SUPER` + `CTRL` + `H` | Hardware Menu | System hardware diagnostics |

---

## Screenshots & Recording

| Shortcut | Action | Description |
|----------|--------|-------------|
| `Print` | Screenshot | Capture selected region with Satty annotation |
| `ALT` + `Print` | Screen Recording | Record selected region or desktop |
| `SUPER` + `Print` | Color Picker | Pick color hex code from screen |
| `SUPER` + `CTRL` + `Print` | OCR Text Extract | Extract text from on-screen region via OCR |

---

## Workspaces

| Shortcut | Action |
|----------|--------|
| `SUPER` + `1` .. `9`, `0` | Switch to workspace 1 through 10 |
| `SUPER` + `SHIFT` + `1` .. `9`, `0` | Move active window to workspace 1 through 10 |
| `SUPER` + `Tab` / `SUPER` + `SHIFT` + `Tab` | Cycle next / previous workspace |
| `SUPER` + `CTRL` + `Tab` | Switch to formerly active workspace |
| `SUPER` + Mouse Wheel Up / Down | Scroll active workspace forward / backward |

---

## Hardware Media & Brightness Controls

| Key | Action | Description |
|-----|--------|-------------|
| `XF86AudioRaiseVolume` / `LowerVolume` | Volume Up / Down | Adjust audio output volume |
| `XF86AudioMute` | Mute Audio | Toggle audio mute |
| `XF86AudioMicMute` | Mute Microphone | Toggle microphone input mute |
| `XF86AudioPlay` / `Pause` / `Next` / `Prev` | Media Controls | Control active MPRIS media playback |
| `XF86MonBrightnessUp` / `Down` | Screen Brightness | Adjust panel backlight brightness |
| `XF86KbdBrightnessUp` / `Down` | Keyboard Backlight | Adjust keyboard backlight illumination |
| `XF86KbdLightOnOff` | Keyboard Light Cycle | Toggle keyboard illumination |
| `XF86TouchpadToggle` | Touchpad Toggle | Enable / disable precision touchpad |
