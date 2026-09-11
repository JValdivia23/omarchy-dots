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
├── core/                       # Tier 1: Universal configs (Git, Hyprland master, macOS nav overrides)
├── profiles/                   # Tier 2: Modular hardware profiles (Surface, Desktop)
│   ├── surface/                # Microsoft Surface Book 3 / Surface Pro
│   └── desktop/                # Multi-monitor workstations & standard PCs
└── agents/                     # Tier 3: Dynamic AI System Personalization Skill
    └── .agents/skills/system-personalization/
```

### 1. Omarchy Quattro Native Integration
- Built specifically for **Omarchy Quattro** (Omarchy v4).
- Uses Omarchy's official Lua bootstrap (`default.hypr.omarchy`, `default.hypr.toggles`).
- Respects Omarchy's system boundaries: `/usr/share/omarchy/` is treated as strictly read-only, and all personal overrides cleanly overlay via `~/.config/`.
- Default themes, decorations, window rules, and application launchers are inherited directly from Omarchy Quattro.

### 2. Native Hyprland Lua Configuration
- **Zero legacy `.conf` files**: Configured 100% in native Lua.
- Universal configuration (`core/.config/hypr/hyprland.lua`) cleanly bootstraps Omarchy defaults, loads personal keybinding overrides (`bindings-common.lua`), and dynamically loads active profile modules via `pcall(require, ...)`:
  - `hypr.monitors`
  - `hypr.input`
  - `hypr.bindings-profile`
  - `hypr.autostart`

### 3. Modular Hardware Profiles
| Profile | Hardware Focus | Included Overrides |
| :--- | :--- | :--- |
| **`surface`** | Microsoft Surface Book 3 / Pro | 3000x2000 @ 2.0 integer scaling, Intel Precise Touch (`iptsd`), clipboard detach daemon (`surface-dtx-daemon`), tablet mode & OSK bindings. |
| **`desktop`** | Standard Workstations | Multi-head display templates, mouse input profiles, audio routing (`pavucontrol`), gaming mode (`gamemode`). |

### 4. Self-Improving System Personalization Skill
Located in `agents/.agents/skills/system-personalization/` and symlinked directly to `~/.agents/`:
- **Dynamic Hardware Probing**: Automatically detects CPU, GPU, monitors, and active profiles to personalize `SKILL.md` and `references/hardware.md`.
- **Modular Gotchas Architecture**: Core universal guardrails live in `agents/.../gotchas/` with [`HOW_TO_WRITE_A_GOTCHA.md`](agents/.agents/skills/system-personalization/references/gotchas/HOW_TO_WRITE_A_GOTCHA.md). Hardware-specific gotchas travel inside `profiles/<profile>/gotchas/` and are symlinked dynamically.
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
1. **Hardware Detection**: Probes DMI, chassis type, and PCI devices to identify your machine profile (`surface` or `desktop`).
2. **Package Synchronization**: Installs missing core tools (`stow`, `ripgrep`, `fd`, `wl-clipboard`, `fastfetch`, `starship`) and profile-specific utilities.
3. **Non-Destructive Backup**: Detects any existing non-symlink configuration files in `~/.config/` or `~/.local/bin/` and safely moves them to `~/.dotfiles_backup_<timestamp>/`.
4. **Deployment**: Links `core/`, the active profile, and `agents/` into your `$HOME` directory using GNU Stow (with native symlink fallback).
5. **Post-Install Setup**: Runs profile setup scripts (enabling daemons like `surface-dtx-daemon` or `iptsd`), symlinks profile gotchas, and initializes the AI system personalization skill.

---

## 🎛️ Command-Line Options

The installer supports flexible flags for testing and targeted updates:

```bash
# Preview actions without modifying the filesystem or installing packages
./install.sh --dry-run

# Manually force a specific hardware profile
./install.sh --profile surface
./install.sh --profile desktop
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

Adding support for a new laptop or workstation is simple:

1. **Create the profile folder**:
   ```bash
   mkdir -p profiles/my-laptop/.config/hypr
   mkdir -p profiles/my-laptop/gotchas
   ```

2. **Add display and input overrides** (optional):
   - `profiles/my-laptop/.config/hypr/monitors.lua`:
     ```lua
     local hl = require("hyprland")
     hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "auto", scale = 1 })
     ```
   - `profiles/my-laptop/.config/hypr/input.lua`:
     ```lua
     local hl = require("hyprland")
     hl.config({ input = { touchpad = { natural_scroll = true } } })
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
     ^gotchas
     ^\.stow-local-ignore$
     ```

5. **Deploy**:
   ```bash
   ./install.sh --profile my-laptop
   ```

---

## ⌨️ Custom Keybindings Quick Reference

Default window management, applications, and workspace controls are provided out-of-the-box by **Omarchy Quattro** (`/usr/share/omarchy/default/hypr/bindings/`).

### Personal Overrides (`core/.config/hypr/bindings-common.lua`)
| Shortcut | Action | Description |
| :--- | :--- | :--- |
| **`Ctrl + Left / Right / Up / Down`** | Window Focus | Move focus across tiled windows |
| **`Super + Left`** | Line Start | Move cursor to start of line (`Home`) |
| **`Super + Right`** | Line End | Move cursor to end of line (`End`) |
| **`Super + Up`** | Document Start | Jump to top of document (`Ctrl + Home`) |
| **`Super + Down`** | Document End | Jump to bottom of document (`Ctrl + End`) |
| **`Alt + Left / Right`** | Word Jump | Move cursor one word backward / forward |
| **`Alt + Shift + Left / Right`** | Word Select | Select text word by word |
| **`Alt + BackSpace`** | Delete Word | Delete previous word |
| **`Super + BackSpace`** | Delete Line | Delete entire line (`Ctrl + U` in terminal, `Shift + Home + BackSpace` in GUI) |
| **`Super + Z`** | Undo | Undo last edit (`Ctrl + Z`) |
| **`Super + Shift + Z`** | Redo | Redo edit (`Ctrl + Shift + Z`) |
| **`Super + Alt + K`** | Layout Swap | Toggle Alt / Super key positions (Mac vs PC layout) |
| **`Super + Alt + BackSpace`** | Window Transparency | Toggle active window opacity |

### Surface Profile Shortcuts (`profiles/surface/.config/hypr/bindings-profile.lua`)
| Shortcut | Action | Description |
| :--- | :--- | :--- |
| **`Super + D`** | Detach Tablet | Request hardware clipboard release (`surface dtx request`) |
| **`Super + R`** | Rotate Screen | Cycle display transform orientation (0° → 90° → 270° → 0°) |
| **`Super + Shift + U`** | On-Screen Keyboard | Toggle Fcitx5 virtual keyboard panel |

---

## 🛠️ Validation & Troubleshooting

After modifying configuration files, always validate your compositor:

```bash
# Check Hyprland Lua syntax errors (journalctl does NOT log Lua errors)
hyprctl configerrors

# Reload compositor without restarting session
hyprctl reload

# Check status of Surface hardware daemons
systemctl status surface-dtx-daemon iptsd
```

---

## 📄 License & Credits

Crafted for Omarchy Linux with Hyprland. Licensed under the MIT License.
