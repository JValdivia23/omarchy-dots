# AGENTS.md — Repository Architecture & AI Assistant Guide

Welcome to the **Omarchy Quattro Dotfiles Repository** (`~/dotfiles`). This repository is designed for multi-machine Linux desktop automation, featuring Omarchy Quattro (Omarchy v4), Hyprland Lua configuration, Noctalia shell, GNU Stow orchestration, and a self-improving system personalization skill.

All AI coding assistants and developers modifying this repository MUST strictly follow the rules, architecture, and validation protocols detailed in this document.

---

## 🏛️ 3-Tier Repository Architecture

This repository organizes configuration into three decoupled, modular tiers to ensure clean separation of universal defaults, machine-specific hardware quirks, and dynamic AI knowledge:

```
~/dotfiles/
├── install.sh                  # Master orchestrator (hardware detection, packages, stow, skill init)
├── AGENTS.md                   # AI Assistant instructions & architectural rules (this file)
├── README.md                   # User-facing guide & quick reference
│
├── core/                       # ─── TIER 1: UNIVERSAL CONFIGURATIONS ──────────────────────
│   ├── .config/
│   │   ├── hypr/
│   │   │   ├── hyprland.lua    # Master Hyprland Lua entrypoint (loads common + pcalls profiles)
│   │   │   ├── bindings-common.lua # Universal desktop shortcuts (apps, window ops, macOS nav)
│   │   │   └── looknfeel.lua   # Window decorations, gaps, borders, animations
│   │   ├── fish/               # Fish shell configuration, environment variables, aliases
│   │   ├── kitty/              # Kitty terminal configuration & color schemes
│   │   ├── alacritty/          # Alacritty terminal fallback configuration
│   │   ├── btop/               # Resource monitor configuration & themes
│   │   └── git/                # Global Git configuration
│   ├── .local/bin/             # Universal CLI utilities (hypr-toggle-altwin, mac-key-helper, etc.)
│   ├── packages.txt            # Baseline packages (stow, fish, kitty, alacritty, btop, ripgrep, etc.)
│   └── .stow-local-ignore      # Prevents metadata (packages.txt) from stowing to $HOME
│
├── profiles/                   # ─── TIER 2: MODULAR HARDWARE PROFILES ────────────────────
│   ├── surface/                # Microsoft Surface devices (Surface Book 3 / Surface Pro)
│   │   ├── .config/hypr/
│   │   │   ├── monitors.lua    # 3000x2000 @ 60Hz with 2.0 integer scaling
│   │   │   ├── input.lua       # Touchscreen calibration, touchpad, stylus rules
│   │   │   └── bindings-profile.lua # Tablet mode shortcuts, virtual keyboard toggle
│   │   ├── packages.txt        # surface-dtx-daemon, iptsd
│   │   ├── services.txt        # surface-dtx-daemon.service, iptsd.service
│   │   ├── setup.sh            # Enables hardware daemons via systemctl
│   │   └── .stow-local-ignore
│   │
│   ├── asus-rog/               # ASUS ROG / Zephyrus Gaming Laptops
│   │   ├── .config/hypr/
│   │   │   └── bindings-profile.lua # ROG Key, Aura RGB toggles, supergfxctl mode switcher
│   │   ├── .local/bin/         # AniMatrix lid charging script
│   │   ├── .local/share/       # Desktop entries and application icons
│   │   ├── packages.txt        # asusctl, supergfxctl
│   │   ├── services.txt        # asusd.service, supergfxd.service
│   │   ├── setup.sh            # Enables ASUS services, registers AniMatrix webapps
│   │   └── .stow-local-ignore
│   │
│   └── desktop/                # Multi-Monitor Workstation & Non-Specialized Laptops
│       ├── .config/hypr/
│       │   ├── monitors.lua    # Multi-head layout template
│       │   └── input.lua       # Full desktop mouse sensitivity & keyboard layout
│       ├── packages.txt        # pavucontrol, nvtop, smartmontools, gamemode
│       ├── setup.sh            # Baseline desktop initialization
│       └── .stow-local-ignore
│
└── agents/                     # ─── TIER 3: DYNAMIC AI SYSTEM PERSONALIZATION SKILL ──────
    ├── .agents/skills/system-personalization/
    │   ├── SKILL.md.template   # Machine-agnostic template with {{HOSTNAME}}, {{CPU}}, etc.
    │   ├── SKILL.md            # Live rendered skill for the currently active machine
    │   ├── scripts/
    │   │   ├── init-skill.sh   # Probes hardware and generates SKILL.md + hardware.md
    │   │   └── snapshot.sh     # Captures live diagnostic state to stdout
    │   ├── templates/          # Standard templates for change-entry.md and gotcha-entry.md
    │   └── references/
    │       ├── hardware.md     # Probed hardware specs (CPU, GPU, RAM, displays, batteries)
    │       ├── current-state.md# Active packages, daemons, compositor health
    │       ├── config-paths.md # Reference of Omarchy Quattro configuration files
    │       ├── keybindings.md  # Active shortcuts reference
    │       ├── changelog.md    # Dated change log of all configuration modifications
    │       └── gotchas/        # Single-file modular gotcha documentation + INDEX.md
    └── .stow-local-ignore
```

---

## ⚠️ Omarchy Quattro Critical Safety Rules

1. **NEVER Edit `/usr/share/omarchy/` (Omarchy Quattro System Space)**:
   - This directory is managed exclusively by the `omarchy` package.
   - Any modifications made inside `/usr/share/omarchy/` will be **wiped without warning** on the next `omarchy update`.
   - **Reading is safe and encouraged**: Agents should read files in `/usr/share/omarchy/` to inspect official command implementations (`cat $(which omarchy-theme-set)`), read default config templates, or reference stock themes.
   - User customizations **MUST ALWAYS** live in `~/.config/` or `~/dotfiles/`.

2. **Symlink Awareness**:
   - Files in `~/.config/` and `~/.local/bin/` are symlinks managed by GNU Stow pointing to `~/dotfiles/`.
   - Editing files in either location updates the underlying Git repository.
   - When creating new configuration files, place them in the appropriate tier (`core/`, `profiles/<name>/`, or `agents/`) and run `./install.sh --only-stow` or `stow` to link them.

3. **Privilege Escalation & Password Prompts (`kitty -e`)**:
   - Omarchy restricts passwordless sudo for security.
   - When executing commands requiring user password authentication (e.g. `sudo pacman`), launch an interactive terminal window:
     ```bash
     kitty -e bash -c "sudo <command>; echo 'Done! Press Enter to close...'; read"
     ```
   - Never run blocking elevated commands directly in headless agent processes without user interaction capability.

---

## 🧪 Hyprland Lua Validation Protocol

Omarchy Quattro configures Hyprland entirely in **Lua** (`~/.config/hypr/hyprland.lua`).

1. **No Legacy `.conf` Syntax**: Never write legacy Hyprland `.conf` syntax into `~/.config/hypr/config/` or `core/.config/hypr/`. Always use native Lua APIs.
2. **Modular Dynamic Loading**: The universal entrypoint `core/.config/hypr/hyprland.lua` uses protected calls (`pcall`) to load hardware profile modules if present:
   ```lua
   dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")
   require("default.hypr.omarchy")
   require("hypr.looknfeel")
   require("hypr.bindings-common")

   -- Dynamically load profile overrides
   pcall(require, "hypr.monitors")
   pcall(require, "hypr.input")
   pcall(require, "hypr.bindings-profile")
   pcall(require, "hypr.autostart")

   require("default.hypr.toggles")
   ```
3. **MANDATORY Validation Step**:
   - **`journalctl` does NOT capture Hyprland Lua syntax errors!**
   - Whenever an agent creates or edits any Hyprland Lua file, the agent **MUST** run:
     ```bash
     hyprctl configerrors
     hyprctl reload
     ```
   - Verify that `hyprctl configerrors` returns empty/clean output (exit code 0). If syntax errors exist, fix them immediately.

---

## 🧩 Modular Gotchas Protocol (Single-File Architecture)

To keep agent context concise and prevent bloated prompt windows:

1. **NEVER create or append to a monolithic `gotchas.md` file.**
2. When discovering a bug, hardware workaround, API change, or environment quirk:
   - Create a new focused markdown document in:
     `agents/.agents/skills/system-personalization/references/gotchas/<category-or-num>-<slug>.md`
   - Use `templates/gotcha-entry.md` as the format template:
     - Clear title and tags
     - Symptom (exact error or unexpected behavior)
     - Root cause analysis
     - Verified fix / solution
     - Preventive rules for agents
3. Update `agents/.agents/skills/system-personalization/references/gotchas/INDEX.md`:
   - Add a 1-line link with description and trigger tags.
4. Existing Gotchas:
   - `01-hyprland-lua-validation.md`: Config errors not logged to journalctl.
   - `02-omarchy-read-only-safety.md`: Protection of `/usr/share/omarchy/`.
   - `03-surface-scaling-and-touch.md`: Surface Book 3 HiDPI 2.0 integer scaling and iptsd touchscreen.
   - `04-surface-dtx-tablet-detach.md`: Surface Book 3 clipboard detachment and surface-dtx-daemon.
   - `05-asus-supergfxctl-hybrid.md`: ASUS ROG GPU switching and supergfxd modes.
   - `06-elevated-password-prompts.md`: Interactive kitty -e wrapper for sudo password prompts.
   - `07-fcitx5-wayland-virtual-keyboard.md`: Wayland on-screen touch keyboard and IME handling.

---

## 🤖 Hardware Personalization Protocol (`init-skill.sh`)

The system personalization skill is dynamic and automatically configured for each machine:

1. **Template Rendering**:
   - `agents/.agents/skills/system-personalization/SKILL.md.template` contains placeholders:
     `{{HOSTNAME}}`, `{{PRODUCT_NAME}}`, `{{OS}}`, `{{KERNEL}}`, `{{CPU}}`, `{{GPU}}`, `{{PRIMARY_DISPLAY}}`, `{{ACTIVE_PROFILES}}`.
2. **Probing Engine**:
   - `agents/.../scripts/init-skill.sh` probes DMI information, CPU cores, GPU models via `lspci`, connected monitors via `hyprctl monitors -j`, battery status, and active systemd daemons.
   - It outputs:
     - `references/hardware.md`: Complete hardware inventory.
     - `references/current-state.md`: Live system snapshot (packages, daemons, compositor health).
     - `SKILL.md`: Rendered skill for the current machine.
3. **Execution**:
   - Ran automatically during `./install.sh`.
   - Can be run manually anytime:
     ```bash
     bash agents/.agents/skills/system-personalization/scripts/init-skill.sh --profiles "surface, laptop"
     ```

---

## ➕ Creating a New Profile for a New Computer

When provisioning dotfiles for a new computer (e.g. a Lenovo ThinkPad, Framework 16, or Desktop PC):

### Step 1: Create the Profile Directory
```bash
mkdir -p profiles/<profile-name>/.config/hypr
```

### Step 2: Add Hardware-Specific Hyprland Overrides (Optional)
Add only the files needed for this specific hardware:
- `profiles/<profile-name>/.config/hypr/monitors.lua`:
  ```lua
  local hl = require("hyprland")
  -- Define primary and external monitor resolution and scaling
  hl.monitor("eDP-1, 2560x1600@165, 0x0, 1.25")
  ```
- `profiles/<profile-name>/.config/hypr/input.lua`:
  ```lua
  local hl = require("hyprland")
  hl.input.touchpad.natural_scroll = true
  ```
- `profiles/<profile-name>/.config/hypr/bindings-profile.lua`:
  ```lua
  local hl = require("hyprland")
  local o = require("default.hypr.binds")
  -- Add machine-specific function key bindings
  ```

### Step 3: Specify Required Packages & Services
- `profiles/<profile-name>/packages.txt`: List packages needed for this hardware (e.g. `tlp`, `framework-system`).
- `profiles/<profile-name>/services.txt`: List systemd services to enable.

### Step 4: Write `setup.sh`
Create an executable `profiles/<profile-name>/setup.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "==> Setting up <profile-name> profile..."

if [ -f "$SCRIPT_DIR/services.txt" ]; then
    while IFS= read -r service || [ -n "$service" ]; do
        [[ -z "$service" || "$service" =~ ^# ]] && continue
        if systemctl list-unit-files "$service" &>/dev/null; then
            sudo systemctl enable --now "$service" || true
        fi
    done < "$SCRIPT_DIR/services.txt"
fi
echo "==> Profile setup complete."
```
Make it executable: `chmod +x profiles/<profile-name>/setup.sh`.

### Step 5: Add `.stow-local-ignore`
Create `profiles/<profile-name>/.stow-local-ignore`:
```
^packages\.txt$
^services\.txt$
^setup\.sh$
^\.stow-local-ignore$
```

### Step 6: Test & Deploy
```bash
# Preview deployment
./install.sh --profile <profile-name> --dry-run

# Apply deployment
./install.sh --profile <profile-name>
```

---

## 📝 Changelog Maintenance Rule

Whenever you make any system configuration change, install a new key package, or tune hardware settings:
1. Open `agents/.agents/skills/system-personalization/references/changelog.md`.
2. Add a new entry using the format from `agents/.../templates/change-entry.md`:
   - Date, change title, category, rationale, files modified, and verification commands.
3. Commit the changes to the repository.
