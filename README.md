# 🪐 Omarchy Quattro Multi-Machine Dotfiles

Automated, reproducible, and hardware-aware desktop environment configured for **Omarchy Quattro (Omarchy v4)** on Arch Linux, powered by **Hyprland (Native Lua API)**, **GNU Stow**, and a **Self-Improving AI System Skill**.

[![Omarchy Quattro](https://img.shields.io/badge/Omarchy-Quattro%20v4-blue?style=flat-square)](https://omarchy.org/)
[![Hyprland Lua](https://img.shields.io/badge/Hyprland-Lua%20API-teal?style=flat-square)](https://hyprland.org/)
[![GNU Stow](https://img.shields.io/badge/GNU-Stow%20Managed-orange?style=flat-square)](https://www.gnu.org/software/stow/)
[![AI Skill](https://img.shields.io/badge/AI-Self--Improving%20Skill-purple?style=flat-square)](./AGENTS.md)

---

## 🌟 Highlights & Architecture

This repository is built around a **3-Tier Architecture** that cleanly isolates universal configurations from hardware-specific overrides and AI system knowledge:

```
~/dotfiles/
├── core/                       # Tier 1: Universal configs (Fish, Kitty, Alacritty, Hyprland core)
├── profiles/                   # Tier 2: Modular hardware profiles (Surface, ASUS ROG, Desktop)
│   ├── surface/                # Microsoft Surface Book 3 / Surface Pro
│   ├── asus-rog/               # ASUS ROG Zephyrus gaming laptops
│   └── desktop/                # Multi-monitor workstations
└── agents/                     # Tier 3: Dynamic AI System Personalization Skill
    └── .agents/skills/system-personalization/
```

### 1. Omarchy Quattro Native Integration
- Built specifically for **Omarchy Quattro** (Omarchy v4).
- Uses Omarchy's official Lua bootstrap (`default.hypr.omarchy`, `default.hypr.toggles`).
- Respects Omarchy's system boundaries: `/usr/share/omarchy/` is treated as strictly read-only, and all customizations cleanly overlay via `~/.config/`.
- Uses `omarchy pkg add` for intelligent package reconciliation.

### 2. Native Hyprland Lua Configuration
- **Zero legacy `.conf` files**: Configured 100% in native Lua.
- Core configuration (`core/.config/hypr/hyprland.lua`) dynamically checks for and safely loads hardware profile modules via `pcall(require, ...)`:
  - `hypr.monitors`
  - `hypr.input`
  - `hypr.bindings-profile`
  - `hypr.autostart`

### 3. Multi-Machine Profiles
| Profile | Hardware Focus | Included Overrides |
| :--- | :--- | :--- |
| **`surface`** | Microsoft Surface Book 3 / Pro | 3000x2000 @ 2.0 integer scaling, Intel Precise Touch (`iptsd`), clipboard detach daemon (`surface-dtx-daemon`), tablet mode bindings. |
| **`asus-rog`** | ASUS ROG Zephyrus Laptops | GPU hybrid switcher (`supergfxctl`), RGB controls (`asusctl`), ROG Key shortcuts, AniMatrix LED lid display scripts. |
| **`desktop`** | Standard Workstations | Multi-head display templates, mouse input profiles, audio routing (`pavucontrol`), gaming mode (`gamemode`). |

### 4. Self-Improving System Personalization Skill
Located in `agents/.agents/skills/system-personalization/` and symlinked directly to `~/.agents/`:
- **Dynamic Hardware Probing**: Automatically detects your exact CPU, GPU, monitors, and active profiles to personalize `SKILL.md` and `references/hardware.md`.
- **Modular Gotchas Architecture**: Individual single-file gotcha notes in `references/gotchas/` so AI assistants only read targeted documentation.
- **Changelog Tracker**: Maintains a persistent record of all configuration modifications and bug fixes in `references/changelog.md`.

---

## ⚡ Quick Start

### 1. Fresh Installation
On any fresh Omarchy or Arch Linux system, run:

```bash
git clone https://github.com/JValdivia23/hyprland-dots.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### 2. What `install.sh` Does Automatically:
1. **Hardware Detection**: Probes DMI, chassis type, and PCI devices to identify your machine profile (`surface`, `asus-rog`, or `desktop`).
2. **Package Synchronization**: Installs missing core tools (`stow`, `fish`, `kitty`, `btop`, etc.) and profile-specific utilities via `omarchy pkg add`.
3. **Non-Destructive Backup**: Detects any existing non-symlink configuration files in `~/.config/` or `~/.local/bin/` and safely moves them to `~/.dotfiles_backup_<timestamp>/`.
4. **GNU Stow Deployment**: Links `core/`, the active profile, and `agents/` into your `$HOME` directory using `--no-folding`.
5. **Post-Install Setup**: Starts hardware services (such as `surface-dtx-daemon` or `supergfxd`) and initializes the AI system personalization skill.

---

## 🎛️ Command-Line Options

The installer supports flexible flags for testing and targeted updates:

```bash
# Preview actions without modifying the filesystem or installing packages
./install.sh --dry-run

# Manually force a specific hardware profile
./install.sh --profile asus-rog
./install.sh --profiles "surface,laptop"

# Only backup conflicts and re-stow symlinks (skips package installation and setup)
./install.sh --only-stow

# Only install core and profile packages
./install.sh --only-packages

# Show usage help
./install.sh --help
```

---

## ➕ Adding a New Computer Profile

Adding support for a new laptop or desktop takes only a few minutes:

1. **Create the profile folder**:
   ```bash
   mkdir -p profiles/my-laptop/.config/hypr
   ```

2. **Add display and input overrides** (optional):
   - `profiles/my-laptop/.config/hypr/monitors.lua`:
     ```lua
     local hl = require("hyprland")
     hl.monitor("eDP-1, 1920x1080@60, 0x0, 1")
     ```
   - `profiles/my-laptop/.config/hypr/input.lua`:
     ```lua
     local hl = require("hyprland")
     hl.input.touchpad.natural_scroll = true
     ```

3. **Specify required packages and daemons**:
   - Create `profiles/my-laptop/packages.txt` (one package per line).
   - Create `profiles/my-laptop/services.txt` (one systemd service per line).

4. **Create `setup.sh` and ignore file**:
   - Create an executable `profiles/my-laptop/setup.sh` to enable services.
   - Create `profiles/my-laptop/.stow-local-ignore`:
     ```
     ^packages\.txt$
     ^services\.txt$
     ^setup\.sh$
     ^\.stow-local-ignore$
     ```

5. **Deploy**:
   ```bash
   ./install.sh --profile my-laptop
   ```

---

## ⌨️ Custom Keybindings Quick Reference

### Applications & Utilities
| Shortcut | Action | Description |
| :--- | :--- | :--- |
| **`Super + Return`** | Terminal | Launches Kitty terminal emulator |
| **`Super + Space`** | App Launcher | Opens Noctalia / Omarchy application launcher |
| **`Super + Shift + B`** | Web Browser | Launches Zen Browser |
| **`Super + Shift + F`** | File Manager | Launches Dolphin file manager |
| **`Super + Shift + U`** | Terminal Files | Launches Yazi file manager |
| **`Super + Shift + A`** | Git Manager | Launches LazyGit |
| **`Super + Shift + D`** | Docker Manager | Launches LazyDocker |
| **`Ctrl + Shift + Esc`** | Task Manager | Launches Btop resource monitor |

### Desktop & Session Controls
| Shortcut | Action | Description |
| :--- | :--- | :--- |
| **`Alt + Space`** | Wallpaper App | Opens Waypaper dynamic wallpaper selector |
| **`Super + Shift + W`** | Wallpaper Gallery | Opens interactive wallpaper picker |
| **`Super + E`** | Control Center | Opens Noctalia quick settings panel |
| **`Super + A`** | Notifications | Opens notification panel |
| **`Super + Escape`** | Power Menu | Opens session lock/shutdown menu |
| **`Super + L`** | Lock Session | Locks current session |

### Window Management & Pop-outs
| Shortcut | Action | Description |
| :--- | :--- | :--- |
| **`Super + O`** | Window Pop-out | Floats, centers (1100x700), and pins active window |
| **`Super + Shift + O`** | PiP Pop-out | Floats small Picture-in-Picture window |
| **`Super + T`** | Toggle Float | Toggles floating mode for active window |
| **`Super + F`** | Fullscreen | Toggles true fullscreen |
| **`Super + D`** | Maximize | Toggles maximized / monocle layout |
| **`Super + Q` / `Super + W`** | Close Window | Closes focused window |

### macOS Navigation Layer
| Shortcut | Action | Description |
| :--- | :--- | :--- |
| **`Super + Alt + K`** | Toggle Layout | Toggles macOS (Command) vs PC (Ctrl) modifier keys |
| **`Super + C / V / X / Z`** | Edit Actions | Mac-style Copy, Paste, Cut, and Undo |
| **`Super + Left / Right`** | Line Jump | Beginning / End of line (`Home` / `End`) |
| **`Alt + Left / Right`** | Word Jump | Word jump backward / forward |
| **`Print` / `Super + Shift + S`**| Region Snip | Interactive region screenshot to Satty |

---

## 🛠️ Validation & Troubleshooting

After modifying configuration files, always validate your compositor:

```bash
# Check Hyprland Lua syntax errors (journalctl does NOT log Lua errors)
hyprctl configerrors

# Reload compositor without restarting session
hyprctl reload

# Check status of hardware services
systemctl status surface-dtx-daemon iptsd # On Surface
systemctl status asusd supergfxd         # On ASUS ROG
```

---

## 📄 License & Credits

Crafted for Omarchy Linux with Hyprland. Licensed under the MIT License.
