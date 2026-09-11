# AGENTS.md — Repository Architecture & AI Assistant Guide

Welcome to the **Omarchy Quattro Dotfiles Repository** (`~/dotfiles`). This repository is designed for multi-machine Linux desktop automation, featuring Omarchy Quattro (Omarchy v4), Hyprland Lua configuration, Omarchy shell (Quickshell), GNU Stow orchestration, and a self-improving system personalization skill.

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
│   │   │   └── bindings-common.lua # Personal shortcuts (macOS nav, undo/redo, delete, altwin)
│   │   └── git/                # Global Git configuration
│   ├── .local/bin/             # Universal CLI utilities (hypr-toggle-altwin, mac-key-helper, etc.)
│   ├── packages.txt            # Baseline packages not bundled by Omarchy (stow, ripgrep, fd, etc.)
│   └── .stow-local-ignore      # Prevents metadata (packages.txt) from stowing to $HOME
│
├── profiles/                   # ─── TIER 2: MODULAR HARDWARE PROFILES ────────────────────
│   ├── surface/                # Microsoft Surface devices (Surface Book 3 / Surface Pro)
│   │   ├── .config/hypr/
│   │   │   ├── monitors.lua    # 3000x2000 @ 60Hz with 2.0 integer scaling
│   │   │   ├── input.lua       # Touchscreen calibration, touchpad, stylus rules
│   │   │   └── bindings-profile.lua # Tablet mode shortcuts, virtual keyboard toggle
│   │   ├── gotchas/            # Surface-specific hardware gotchas (scaling, detach, OSK)
│   │   ├── packages.txt        # surface-dtx-daemon, iptsd
│   │   ├── services.txt        # surface-dtx-daemon.service, iptsd.service
│   │   ├── setup.sh            # Enables hardware daemons via systemctl
│   │   └── .stow-local-ignore
│   │
│   └── desktop/                # Multi-Monitor Workstations & Generic PCs
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
    │       └── gotchas/        # Universal guardrails + HOW_TO_WRITE_A_GOTCHA.md
    └── .stow-local-ignore
```

---

## 🤝 Coexistence: Built-in `omarchy` Skill vs. `system-personalization` Skill

Omarchy Quattro includes an official, system-maintained skill at `~/.agents/skills/omarchy/`. Both skills work together with a clean division of responsibility:

| Skill | Primary Role | When to Consult |
|---|---|---|
| **`omarchy`** (Built-in) | **OS & Tooling Authority** | Consult for **HOW** to interact with Omarchy Linux:<br>• `omarchy theme set <theme>` (theme engine)<br>• `omarchy pkg add <pkg>` (package management)<br>• `omarchy webapp install <name> <url>` (PWA creation)<br>• `omarchy bar` & `omarchy plugin` (status bar layout)<br>• `omarchy hook install` (automation)<br>• `omarchy refresh <component>` (safe resets) |
| **`system-personalization`** (This Repo) | **Machine & Preference Authority** | Consult for **WHO** this machine is and **WHAT** the user prefers:<br>• Live hardware specifications ([`references/hardware.md`](references/hardware.md))<br>• Active profile (`surface`, etc.) and hardware daemons<br>• User macOS text navigation bindings & custom shortcuts<br>• Touchpad scroll speed and gesture preferences<br>• Hardware gotchas ([`references/gotchas/`](references/gotchas/INDEX.md))<br>• Machine change history ([`references/changelog.md`](references/changelog.md)) |

**Rule for AI Agents**:
- When performing actions on the operating system, **always defer to the `omarchy` skill** for the proper command patterns.
- Do not reinvent package installation, theme switching, or bar customization; use Omarchy's native CLI tools.
- Use `system-personalization` to know what hardware you are running on, what display scaling to use, and what personal shortcuts the user expects.

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

3. **Privilege Escalation & Password Prompts (`pkexec` & Floating Windows)**:
   - Follow Omarchy's official privilege escalation protocol:
     - **Non-interactive / Agent background commands**: Use `pkexec <command>`. Omarchy’s Quickshell Polkit agent triggers a centered, graphical floating password dialog on the user's screen.
     - **Interactive terminal commands**: Use `omarchy-launch-floating-terminal-with-presentation "<command>"`. Hyprland window rules automatically float this centered with the active theme.
   - Never run blocking `sudo` commands directly in headless agent processes without a TTY or graphical prompt.

---

## 🧪 Hyprland Lua Validation Protocol

Omarchy Quattro configures Hyprland entirely in **Lua** (`~/.config/hypr/hyprland.lua`).

1. **No Legacy `.conf` Syntax**: Never write legacy Hyprland `.conf` syntax into `~/.config/hypr/config/` or `core/.config/hypr/`. Always use native Lua APIs.
2. **Modular Dynamic Loading**: The universal entrypoint `core/.config/hypr/hyprland.lua` uses protected calls (`pcall`) to load hardware profile modules if present:
   ```lua
   dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")
   require("default.hypr.omarchy")
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
   - For **Universal Guardrails** (all machines): create a new markdown document in `agents/.agents/skills/system-personalization/references/gotchas/<category-or-num>-<slug>.md`.
   - For **Hardware Quirks**: create the document in `profiles/<profile>/gotchas/<category-or-num>-<slug>.md`.
   - Follow the comprehensive guide in [`HOW_TO_WRITE_A_GOTCHA.md`](agents/.agents/skills/system-personalization/references/gotchas/HOW_TO_WRITE_A_GOTCHA.md) and use `templates/gotcha-entry.md`.
3. Active Universal Guardrails:
   - `01-hyprland-lua-validation.md`: Hyprland error diagnostics via `hyprctl configerrors`.
   - `02-omarchy-read-only-safety.md`: Read-only protection of `/usr/share/omarchy/`.
   - `03-elevated-password-prompts.md`: Interactive `kitty -e` wrapper for sudo password prompts.
   - `HOW_TO_WRITE_A_GOTCHA.md`: Comprehensive authoring and troubleshooting guide.
4. Active Profile Gotchas (dynamically linked during `./install.sh`):
   - `profiles/surface/gotchas/03-surface-scaling-and-touch.md`: Surface Book 3 HiDPI 2.0 integer scaling and iptsd touchscreen.
   - `profiles/surface/gotchas/04-surface-dtx-tablet-detach.md`: Surface Book 3 clipboard detachment and surface-dtx-daemon.
   - `profiles/surface/gotchas/07-fcitx5-wayland-virtual-keyboard.md`: Wayland on-screen touch keyboard and IME handling.

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
