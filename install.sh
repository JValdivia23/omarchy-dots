#!/usr/bin/env bash
# ==============================================================================
# Omarchy Quattro Master Dotfiles & Environment Installer
# 3-Tier Architecture: Core (universal) + Profiles (hardware) + Agents (skill)
# ==============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Default execution switches
DO_PACKAGES=true
DO_STOW=true
DO_SETUP=true
DRY_RUN=false
MANUAL_PROFILES=""

# Display usage instructions
show_help() {
    cat << 'HELP'
Omarchy Quattro Dotfiles Installer

Usage:
  ./install.sh [OPTIONS]

Options:
  --profile <name>         Manually specify a profile (e.g. --profile surface)
  --profiles <p1,p2>       Manually specify comma-separated profiles (e.g. --profiles "surface,laptop")
  --dry-run                Simulate actions without writing files or installing packages
  --only-stow              Only backup conflicts and deploy GNU Stow symlinks
  --only-packages          Only install core and profile packages
  -h, --help               Display this help message

Examples:
  ./install.sh                           # Auto-detect hardware, install packages, stow, and configure
  ./install.sh --dry-run                 # Preview actions without changing system state
  ./install.sh --profile asus-rog        # Force ASUS ROG profile deployment
  ./install.sh --only-stow               # Refresh symlinks without touching package manager
HELP
}

# --- 1. Parse Command Line Arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile)
            if [[ -z "${2:-}" || "$2" =~ ^-- ]]; then
                echo "Error: --profile requires a profile name argument." >&2
                exit 1
            fi
            MANUAL_PROFILES="$2"
            shift 2
            ;;
        --profiles)
            if [[ -z "${2:-}" || "$2" =~ ^-- ]]; then
                echo "Error: --profiles requires a profile list argument." >&2
                exit 1
            fi
            MANUAL_PROFILES="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --only-stow)
            DO_PACKAGES=false
            DO_STOW=true
            DO_SETUP=false
            shift
            ;;
        --only-packages)
            DO_PACKAGES=true
            DO_STOW=false
            DO_SETUP=false
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Error: Unknown argument '$1'" >&2
            echo "Run './install.sh --help' for usage." >&2
            exit 1
            ;;
    esac
done

echo "======================================================="
echo "   🪐 Omarchy Quattro Dotfiles & Environment Installer "
echo "======================================================="
if [ "$DRY_RUN" = true ]; then
    echo "   [MODE: DRY-RUN SIMULATION — NO CHANGES APPLIED]     "
    echo "======================================================="
fi
echo ""

# --- 2. Hardware Detection Engine ---
echo "==> [1/4] Probing Hardware & Detecting Profiles..."

SYS_PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name 2>/dev/null || cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || true)
SYS_VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || cat /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null || true)
SYS_CHASSIS=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || cat /sys/devices/virtual/dmi/id/chassis_type 2>/dev/null || true)
LSPCI_INFO=$(lspci 2>/dev/null || true)
KERNEL_RELEASE=$(uname -r 2>/dev/null || true)

echo "    Product:  ${SYS_PRODUCT_NAME:-Generic System}"
echo "    Vendor:   ${SYS_VENDOR:-Unknown Vendor}"
echo "    Chassis:  ${SYS_CHASSIS:-Unknown Chassis}"
echo "    Kernel:   $KERNEL_RELEASE"

# Laptop detection
IS_LAPTOP=false
case "$SYS_CHASSIS" in
    8|9|10|11|12|14|30|31|32)
        IS_LAPTOP=true
        ;;
    *)
        if [ -d /sys/class/power_supply ] && ls /sys/class/power_supply/ 2>/dev/null | grep -q -E "BAT|battery"; then
            IS_LAPTOP=true
        fi
        ;;
esac

# Auto-detect or use manual profiles
ACTIVE_PROFILES=""
if [ -n "$MANUAL_PROFILES" ]; then
    ACTIVE_PROFILES="$MANUAL_PROFILES"
    echo "    Selection: Manually specified by user -> '$ACTIVE_PROFILES'"
else
    DETECTED=()
    # Check for Surface
    if [[ "${SYS_PRODUCT_NAME,,}" =~ surface ]] || [[ "${SYS_VENDOR,,}" =~ microsoft && "${SYS_PRODUCT_NAME,,}" =~ surface ]] || [[ "${KERNEL_RELEASE,,}" =~ surface ]]; then
        DETECTED+=("surface")
    # Check for ASUS ROG / Zephyrus / TUF
    elif [[ "${SYS_PRODUCT_NAME,,}" =~ (zephyrus|rog|tuf) ]] || [[ "${SYS_VENDOR,,}" =~ asus ]] || echo "$LSPCI_INFO" | grep -qi "ASUSTeK"; then
        DETECTED+=("asus-rog")
    fi

    # Include laptop trait if hardware indicates portable/battery
    if [ "$IS_LAPTOP" = true ]; then
        DETECTED+=("laptop")
    fi

    # If no specialty profiles detected
    if [ ${#DETECTED[@]} -eq 0 ]; then
        echo "    No specialty or laptop profile matched. Suggesting 'desktop' profile."
        DETECTED+=("desktop")
    elif [ ${#DETECTED[@]} -eq 1 ] && [ "${DETECTED[0]}" = "laptop" ]; then
        echo "    Generic laptop detected without specialty profile. Suggesting 'desktop' profile."
        DETECTED=("desktop" "laptop")
    fi

    ACTIVE_PROFILES=$(IFS=', '; echo "${DETECTED[*]}")
    echo "    Selection: Auto-detected -> '$ACTIVE_PROFILES'"
fi

# Parse active profiles into list of profile directories
IFS=',' read -ra RAW_PROFILES_ARRAY <<< "$ACTIVE_PROFILES"
STOWABLE_PROFILES=()
for raw in "${RAW_PROFILES_ARRAY[@]}"; do
    p="$(echo "$raw" | xargs)" # trim whitespace
    [ -z "$p" ] && continue
    if [ -d "$DOTFILES_DIR/profiles/$p" ]; then
        STOWABLE_PROFILES+=("$p")
    else
        echo "    Notice: Profile trait '$p' has no dedicated folder at profiles/$p (used for skill personalization)."
    fi
done

echo "    Active Profile Directories to Stow: [${STOWABLE_PROFILES[*]:-none}]"
echo ""

# --- Helper Functions ---
backup_needed=false

# Non-destructive backup handler for conflicting paths
check_and_backup_path() {
    local target="$1"
    local rel_path="${target#$HOME/}"

    # If the target doesn't exist and isn't a broken symlink, nothing to do
    [ ! -e "$target" ] && [ ! -L "$target" ] && return 0

    # Safety: NEVER back up or move files resolving inside our dotfiles repository
    local target_real
    target_real=$(realpath -q "$target" 2>/dev/null || true)
    if [ -n "$target_real" ] && [[ "$target_real" == "$DOTFILES_DIR"* ]]; then
        return 0
    fi

    if [ "$backup_needed" = false ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "--> [dry-run] Existing non-dotfiles configurations detected! Would create backup at:"
        else
            echo "--> Existing non-dotfiles configurations detected! Creating backup at:"
        fi
        echo "    $BACKUP_DIR"
        if [ "$DRY_RUN" = false ]; then
            mkdir -p "$BACKUP_DIR"
        fi
        backup_needed=true
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "    [dry-run] [Backup] ~/$rel_path -> $BACKUP_DIR/$rel_path"
    else
        echo "    [Backup] ~/$rel_path -> $BACKUP_DIR/$rel_path"
        mkdir -p "$BACKUP_DIR/$(dirname "$rel_path")"
        mv "$target" "$BACKUP_DIR/$rel_path"
    fi
}

# Cleanly converts directory symlinks that point into DOTFILES_DIR into real directories
# so GNU Stow and native fallback can manage individual file links without recursion/circular errors.
sanitize_directory_symlinks() {
    local pkg_dir="$1"
    [ ! -d "$pkg_dir" ] && return 0

    while IFS= read -r -d '' src_d; do
        local rel_d="${src_d#$pkg_dir/}"
        if [[ "$rel_d" =~ ^(webapps|\.stow)($|/) ]] || [[ "$rel_d" =~ ^(packages\.txt|services\.txt|setup\.sh)($|/) ]] || [[ "$rel_d" =~ __pycache__ ]]; then
            continue
        fi

        local target_d="$HOME/$rel_d"
        if [ -L "$target_d" ]; then
            local target_real
            target_real=$(realpath -q "$target_d" 2>/dev/null || true)
            if [ -n "$target_real" ] && [[ "$target_real" == "$DOTFILES_DIR"* ]]; then
                if [ "$DRY_RUN" = true ]; then
                    echo "    [dry-run] Convert directory symlink ~/$rel_d to real directory for Stow"
                else
                    rm "$target_d"
                    mkdir -p "$target_d"
                fi
            else
                check_and_backup_path "$target_d"
            fi
        fi
    done < <(find "$pkg_dir" -mindepth 1 -type d -print0)
}

# Recursively check package directory for conflicting real files/folders in $HOME
scan_and_backup_package_conflicts() {
    local pkg_dir="$1"
    [ ! -d "$pkg_dir" ] && return 0

    while IFS= read -r -d '' src_item; do
        local rel_item="${src_item#$pkg_dir/}"
        # Exclude ignored metadata files, pycache, and non-dotfile trees
        if [[ "$rel_item" =~ ^(packages\.txt|services\.txt|setup\.sh|webapps)($|/) ]] || [[ "$rel_item" =~ ^\.stow ]] || [[ "$rel_item" =~ __pycache__|\.pyc$ ]]; then
            continue
        fi

        local target="$HOME/$rel_item"

        # Check if the target is an existing real file or conflicting symlink
        if [ -e "$target" ] || [ -L "$target" ]; then
            check_and_backup_path "$target"
        fi
    done < <(find "$pkg_dir" -mindepth 1 \( -type f -o -type l \) -print0)
}

# Helper to install package lists with omarchy or pacman
install_packages_list() {
    local pkg_file="$1"
    [ ! -f "$pkg_file" ] && return 0

    local pkgs=()
    while IFS= read -r line || [ -n "$line" ]; do
        line=$(echo "$line" | sed 's/#.*//' | xargs)
        [ -z "$line" ] && continue
        pkgs+=("$line")
    done < "$pkg_file"

    [ ${#pkgs[@]} -eq 0 ] && return 0

    local rel_path="${pkg_file#$DOTFILES_DIR/}"
    echo "--> Installing packages from $rel_path (${#pkgs[@]} items)..."

    if [ "$DRY_RUN" = true ]; then
        echo "    [dry-run] Packages to install: ${pkgs[*]}"
        return 0
    fi

    if command -v omarchy &>/dev/null; then
        echo "    Using 'omarchy pkg add'..."
        omarchy pkg add "${pkgs[@]}" || {
            echo "    Notice: omarchy pkg add finished with warnings; verifying with pacman..."
            for pkg in "${pkgs[@]}"; do
                if ! pacman -Q "$pkg" &>/dev/null; then
                    if (( EUID == 0 )); then
                        pacman -S --needed --noconfirm "$pkg" || true
                    else
                        sudo pacman -S --needed --noconfirm "$pkg" || true
                    fi
                fi
            done
        }
    elif command -v pacman &>/dev/null; then
        echo "    Using 'pacman -S --needed --noconfirm'..."
        if (( EUID == 0 )); then
            pacman -S --needed --noconfirm "${pkgs[@]}"
        else
            sudo pacman -S --needed --noconfirm "${pkgs[@]}"
        fi
    else
        echo "Warning: No supported package manager found (omarchy/pacman). Skipping package installation." >&2
    fi
}

# --- 3. Packages Installation Step ---
if [ "$DO_PACKAGES" = true ]; then
    echo "==> [2/4] Synchronizing System & Profile Packages..."
    # 1. Core universal packages
    install_packages_list "$DOTFILES_DIR/core/packages.txt"

    # 2. Profile-specific packages
    for p in "${STOWABLE_PROFILES[@]}"; do
        if [ -f "$DOTFILES_DIR/profiles/$p/packages.txt" ]; then
            install_packages_list "$DOTFILES_DIR/profiles/$p/packages.txt"
        fi
    done
    echo ""
else
    echo "==> [2/4] Skipping package synchronization (--only-stow specified)."
    echo ""
fi

# --- 4. Non-Destructive Backup & Stow Step ---
if [ "$DO_STOW" = true ]; then
    echo "==> [3/4] Deploying Dotfiles with GNU Stow (Non-Destructive)..."

    # Sanitize directory symlinks that point into repo so Stow can link individual files
    sanitize_directory_symlinks "$DOTFILES_DIR/core"
    for p in "${STOWABLE_PROFILES[@]}"; do
        sanitize_directory_symlinks "$DOTFILES_DIR/profiles/$p"
    done
    sanitize_directory_symlinks "$DOTFILES_DIR/agents"

    # Ensure required destination base directories exist
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$HOME/.config" \
                 "$HOME/.config/hypr" \
                 "$HOME/.local/bin" \
                 "$HOME/.local/share/applications" \
                 "$HOME/.local/share/icons" \
                 "$HOME/.agents/skills/system-personalization"
    fi

    # Check and backup conflicts across all deployment packages
    echo "--> Checking for conflicting configurations in ~/.config/, ~/.local/bin/, and ~/.agents/..."
    scan_and_backup_package_conflicts "$DOTFILES_DIR/core"
    for p in "${STOWABLE_PROFILES[@]}"; do
        scan_and_backup_package_conflicts "$DOTFILES_DIR/profiles/$p"
    done
    scan_and_backup_package_conflicts "$DOTFILES_DIR/agents"

    if [ "$backup_needed" = false ]; then
        echo "    No file conflicts found. Safe to link directly."
    fi

    # Verify stow availability
    HAS_STOW=true
    if ! command -v stow &>/dev/null; then
        HAS_STOW=false
        if [ "$DRY_RUN" = false ]; then
            echo "    Notice: GNU Stow is not currently installed. Attempting installation via omarchy/pacman..."
            if command -v omarchy &>/dev/null; then
                omarchy pkg add stow || true
            elif command -v pacman &>/dev/null; then
                if (( EUID == 0 )); then
                    pacman -S --needed --noconfirm stow || true
                else
                    sudo pacman -S --needed --noconfirm stow || true
                fi
            fi
            if command -v stow &>/dev/null; then
                HAS_STOW=true
            fi
        else
            echo "    Notice: GNU Stow is not currently installed on this system (would be installed in Step 2 during normal run)."
        fi
    fi

    STOW_IGNORE_FLAGS=(
        "--ignore=^packages\.txt$"
        "--ignore=^services\.txt$"
        "--ignore=^setup\.sh$"
        "--ignore=^webapps"
        "--ignore=^\.stow-local-ignore$"
        "--ignore=__pycache__"
        "--ignore=\.pyc$"
    )

    if [ "$HAS_STOW" = true ]; then
        # Stow Core Package
        echo "--> Stowing 'core' package..."
        if [ "$DRY_RUN" = true ]; then
            echo "    [dry-run] stow -v -R --no-folding -d \"$DOTFILES_DIR\" -t \"$HOME\" ${STOW_IGNORE_FLAGS[*]} core"
        else
            stow -v -R --no-folding -d "$DOTFILES_DIR" -t "$HOME" "${STOW_IGNORE_FLAGS[@]}" core
        fi

        # Stow Active Profile Packages
        for p in "${STOWABLE_PROFILES[@]}"; do
            echo "--> Stowing active profile '$p'..."
            if [ "$DRY_RUN" = true ]; then
                echo "    [dry-run] stow -v -R --no-folding -d \"$DOTFILES_DIR/profiles\" -t \"$HOME\" ${STOW_IGNORE_FLAGS[*]} \"$p\""
            else
                stow -v -R --no-folding -d "$DOTFILES_DIR/profiles" -t "$HOME" "${STOW_IGNORE_FLAGS[@]}" "$p"
            fi
        done

        # Stow Dynamic AI Agents Package
        echo "--> Stowing 'agents' package..."
        if [ "$DRY_RUN" = true ]; then
            echo "    [dry-run] stow -v -R --no-folding -d \"$DOTFILES_DIR\" -t \"$HOME\" ${STOW_IGNORE_FLAGS[*]} agents"
        else
            stow -v -R --no-folding -d "$DOTFILES_DIR" -t "$HOME" "${STOW_IGNORE_FLAGS[@]}" agents
        fi
    else
        # Fallback to direct symlink linking if stow is unavailable
        echo "--> Using native symlink deployment fallback..."
        link_dir_files() {
            local src_dir="$1"
            local root_dir="$2"
            while IFS= read -r -d '' src_f; do
                local rel="${src_f#$root_dir/}"
                if [[ "$rel" =~ ^(packages\.txt|services\.txt|setup\.sh|webapps)($|/) ]] || [[ "$rel" =~ ^\.stow ]] || [[ "$rel" =~ __pycache__|\.pyc$ ]]; then
                    continue
                fi
                local dest="$HOME/$rel"
                if [ "$DRY_RUN" = true ]; then
                    echo "    [dry-run] ln -sf \"$src_f\" \"$dest\""
                else
                    mkdir -p "$(dirname "$dest")"
                    if [ -L "$dest" ] && [ "$(realpath -q "$dest" 2>/dev/null || true)" = "$(realpath -q "$src_f" 2>/dev/null || true)" ]; then
                        continue
                    fi
                    ln -sf "$src_f" "$dest"
                fi
            done < <(find "$src_dir" -mindepth 1 \( -type f -o -type l \) -print0)
        }

        link_dir_files "$DOTFILES_DIR/core" "$DOTFILES_DIR/core"
        for p in "${STOWABLE_PROFILES[@]}"; do
            link_dir_files "$DOTFILES_DIR/profiles/$p" "$DOTFILES_DIR/profiles/$p"
        done
        link_dir_files "$DOTFILES_DIR/agents" "$DOTFILES_DIR/agents"
    fi
    echo ""
else
    echo "==> [3/4] Skipping dotfile stowing (--only-packages specified)."
    echo ""
fi

# --- 5. Post-Install Setup Step ---
if [ "$DO_SETUP" = true ]; then
    echo "==> [4/4] Executing Post-Install Setup & Skill Initialization..."

    # 1. Execute each active profile's setup.sh
    for p in "${STOWABLE_PROFILES[@]}"; do
        SETUP_SCRIPT="$DOTFILES_DIR/profiles/$p/setup.sh"
        if [ -f "$SETUP_SCRIPT" ]; then
            echo "--> Running setup script for profile '$p'..."
            if [ "$DRY_RUN" = true ]; then
                echo "    [dry-run] Would execute: bash $SETUP_SCRIPT"
            else
                chmod +x "$SETUP_SCRIPT"
                bash "$SETUP_SCRIPT"
            fi
        fi
    done

    # 2. Run system-personalization skill initializer
    INIT_SKILL_SCRIPT="$DOTFILES_DIR/agents/.agents/skills/system-personalization/scripts/init-skill.sh"
    if [ -f "$INIT_SKILL_SCRIPT" ]; then
        echo "--> Initializing system-personalization AI skill..."
        if [ "$DRY_RUN" = true ]; then
            echo "    [dry-run] Would execute: bash $INIT_SKILL_SCRIPT --profiles \"$ACTIVE_PROFILES\""
        else
            chmod +x "$INIT_SKILL_SCRIPT"
            bash "$INIT_SKILL_SCRIPT" --profiles "$ACTIVE_PROFILES"
        fi
    fi
    echo ""
else
    echo "==> [4/4] Skipping post-install setup."
    echo ""
fi

# --- 6. Summary & Next Steps ---
echo "======================================================="
if [ "$DRY_RUN" = true ]; then
    echo "  🔍 Dry-run simulation finished successfully!"
else
    echo "  🎉 Omarchy Quattro Installation & Setup Complete!   "
fi
echo "======================================================="
echo "Active Profile(s):   $ACTIVE_PROFILES"
if [ "$backup_needed" = true ]; then
    if [ "$DRY_RUN" = true ]; then
        echo "Simulated Backup:    $BACKUP_DIR"
    else
        echo "Backup Location:     $BACKUP_DIR"
    fi
fi
echo ""
echo "Next Steps:"
echo "  1. Validate Hyprland Lua configuration:"
echo "     hyprctl configerrors"
echo "     hyprctl reload"
if [[ "$ACTIVE_PROFILES" =~ surface ]]; then
    echo "  2. Test active Surface hardware daemons:"
    echo "     systemctl status surface-dtx-daemon iptsd 2>/dev/null || true"
elif [[ "$ACTIVE_PROFILES" =~ asus ]]; then
    echo "  2. Test active ASUS hardware daemons:"
    echo "     systemctl status asusd supergfxd 2>/dev/null || true"
fi
echo "  3. Log out and log back in (or restart your session) to"
echo "     load all environment variables and fish shell profiles."
echo "======================================================="
