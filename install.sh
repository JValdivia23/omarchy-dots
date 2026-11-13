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
  ./install.sh --profile surface         # Force Surface profile deployment
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
    # Check for Dell XPS
    if [[ "${SYS_PRODUCT_NAME,,}" =~ xps ]]; then
        DETECTED+=("xps")
    fi

    # Check for Surface Go 3 vs general Surface
    if [[ "${SYS_PRODUCT_NAME,,}" =~ surface\ go\ 3 ]]; then
        DETECTED+=("surface-go3")
    elif [[ "${SYS_PRODUCT_NAME,,}" =~ surface ]] || [[ "${SYS_VENDOR,,}" =~ microsoft && "${SYS_PRODUCT_NAME,,}" =~ surface ]] || [[ "${KERNEL_RELEASE,,}" =~ surface ]]; then
        DETECTED+=("surface")
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
        echo "    Generic laptop detected without specialty profile. Suggesting 'xps' laptop profile."
        DETECTED=("xps" "laptop")
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
ELEVATE_MODE=""
ELEVATE_DIR=""
SUDO_KEEPALIVE_PID=""
ELEVATE_WORKER_PID=""

cleanup_privilege_session() {
    if [ -n "$SUDO_KEEPALIVE_PID" ]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
        SUDO_KEEPALIVE_PID=""
    fi
    if [ -n "$ELEVATE_DIR" ] && [ -d "$ELEVATE_DIR" ]; then
        local wstate=""
        if [ -n "$ELEVATE_WORKER_PID" ] && [ -r "/proc/$ELEVATE_WORKER_PID/stat" ]; then
            wstate=$(awk '{print $3}' "/proc/$ELEVATE_WORKER_PID/stat" 2>/dev/null || true)
        fi
        if [ -p "$ELEVATE_DIR/req.fifo" ] && [ -n "$wstate" ] && [ "$wstate" != "Z" ]; then
            printf 'EXIT\n' > "$ELEVATE_DIR/req.fifo" 2>/dev/null || true
            wait "$ELEVATE_WORKER_PID" 2>/dev/null || true
        fi
        rm -rf "$ELEVATE_DIR"
        ELEVATE_DIR=""
    fi
}
trap cleanup_privilege_session EXIT INT TERM

# Authenticate at most once per installer run (sudo keepalive in TTY, single pkexec worker otherwise)
ensure_privilege_session() {
    if [ -n "$ELEVATE_MODE" ]; then
        [ "$ELEVATE_MODE" != "none" ]
        return $?
    fi

    if (( EUID == 0 )); then
        ELEVATE_MODE="root"
        return 0
    fi

    if [ -t 0 ] || sudo -n true 2>/dev/null; then
        if sudo -v; then
            (
                while kill -0 $$ 2>/dev/null; do
                    sudo -n true 2>/dev/null || exit 0
                    sleep 50
                done
            ) &
            SUDO_KEEPALIVE_PID=$!
            ELEVATE_MODE="sudo"
            return 0
        fi
        ELEVATE_MODE="none"
        return 1
    fi

    if command -v pkexec &>/dev/null; then
        ELEVATE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/omarchy-elevate.XXXXXX")"
        chmod 700 "$ELEVATE_DIR"
        mkdir -p "$ELEVATE_DIR/bin"
        mkfifo -m 600 "$ELEVATE_DIR/req.fifo" "$ELEVATE_DIR/ack.fifo" "$ELEVATE_DIR/out.fifo" "$ELEVATE_DIR/err.fifo"
        : > "$ELEVATE_DIR/lock"

        cat > "$ELEVATE_DIR/worker.sh" <<'EOF'
#!/usr/bin/env bash
set -u
DIR="$1"
exec 3<>"$DIR/req.fifo"
touch "$DIR/ready"
while IFS= read -r cmd <&3; do
    case "$cmd" in
        EXIT)
            break
            ;;
        RUN)
            mapfile -d '' -t args < "$DIR/argv.dat"
            cwd="${args[0]:-/}"
            if [ "${#args[@]}" -gt 1 ]; then
                (
                    cd "$cwd" 2>/dev/null || cd /
                    "${args[@]:1}"
                ) < "$DIR/stdin.dat" > "$DIR/out.fifo" 2> "$DIR/err.fifo"
                rc=$?
            else
                : > "$DIR/out.fifo"
                : > "$DIR/err.fifo"
                rc=0
            fi
            printf '%s\n' "$rc" > "$DIR/ack.fifo"
            ;;
    esac
done
EOF
        chmod 700 "$ELEVATE_DIR/worker.sh"

        cat > "$ELEVATE_DIR/bin/sudo" <<EOF
#!/usr/bin/env bash
set -u
DIR="$ELEVATE_DIR"
validate=false
while [[ \$# -gt 0 ]]; do
    case "\$1" in
        -v) validate=true; shift ;;
        -n|-E|-H|-S|-i|-s|-b|-A|-P|-k|-K) shift ;;
        -u|-g|-p|-C|-T|-D|-r|-t) shift 2 ;;
        --) shift; break ;;
        -*) shift ;;
        *) break ;;
    esac
done
if [ "\$validate" = true ] && [ \$# -eq 0 ]; then
    exit 0
fi
if [ \$# -eq 0 ]; then
    exit 0
fi
exec 9<>"\$DIR/lock"
flock 9
if [ -t 0 ]; then
    : > "\$DIR/stdin.dat"
else
    cat > "\$DIR/stdin.dat"
fi
printf '%s\0' "\$PWD" "\$@" > "\$DIR/argv.dat"
cat "\$DIR/out.fifo" &
out_pid=\$!
cat "\$DIR/err.fifo" >&2 &
err_pid=\$!
printf 'RUN\n' > "\$DIR/req.fifo"
IFS= read -r rc < "\$DIR/ack.fifo" || rc=1
wait "\$out_pid" "\$err_pid" 2>/dev/null || true
exit "\${rc:-1}"
EOF
        chmod 700 "$ELEVATE_DIR/bin/sudo"

        pkexec bash "$ELEVATE_DIR/worker.sh" "$ELEVATE_DIR" </dev/null >/dev/null 2>"$ELEVATE_DIR/worker.err" &
        ELEVATE_WORKER_PID=$!

        while true; do
            if [ -f "$ELEVATE_DIR/ready" ]; then
                export PATH="$ELEVATE_DIR/bin:$PATH"
                ELEVATE_MODE="pkexec_worker"
                return 0
            fi
            local wstate=""
            if [ -r "/proc/$ELEVATE_WORKER_PID/stat" ]; then
                wstate=$(awk '{print $3}' "/proc/$ELEVATE_WORKER_PID/stat" 2>/dev/null || true)
            fi
            if [ -z "$wstate" ] || [ "$wstate" = "Z" ]; then
                break
            fi
            sleep 0.1
        done

        if [ -f "$ELEVATE_DIR/ready" ]; then
            export PATH="$ELEVATE_DIR/bin:$PATH"
            ELEVATE_MODE="pkexec_worker"
            return 0
        fi

        echo "    Error: Privilege elevation cancelled or failed." >&2
        if [ -s "$ELEVATE_DIR/worker.err" ]; then
            cat "$ELEVATE_DIR/worker.err" >&2
        fi
        wait "$ELEVATE_WORKER_PID" 2>/dev/null || true
        rm -rf "$ELEVATE_DIR"
        ELEVATE_DIR=""
        ELEVATE_WORKER_PID=""
        ELEVATE_MODE="none"
        return 1
    fi

    ELEVATE_MODE="none"
    return 1
}

run_elevated() {
    ensure_privilege_session || return 1
    if [ "$ELEVATE_MODE" = "root" ]; then
        "$@"
    else
        sudo "$@"
    fi
}

# Non-destructive backup handler for conflicting paths
check_and_backup_path() {
    local target="$1"
    local rel_path="${target#$HOME/}"

    # If the target doesn't exist and isn't a broken symlink, nothing to do
    [ ! -e "$target" ] && [ ! -L "$target" ] && return 0

    # If target is already a symlink resolving inside our dotfiles repository:
    # If it is an absolute symlink, remove it so GNU Stow can recreate its managed relative link cleanly.
    # If it is already a relative symlink, leave it intact to prevent transient inotify file deletion errors.
    local target_real
    target_real=$(realpath -q "$target" 2>/dev/null || true)
    if [ -n "$target_real" ] && [[ "$target_real" == "$DOTFILES_DIR"* ]]; then
        if [ -L "$target" ]; then
            local link_dest
            link_dest=$(readlink "$target" 2>/dev/null || true)
            if [[ "$link_dest" == /* ]]; then
                if [ "$DRY_RUN" = false ]; then
                    rm -f "$target"
                fi
            fi
        fi
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
        if [[ "$rel_d" =~ ^(webapps|\.stow)($|/) ]] || [[ "$rel_d" =~ ^(packages\.txt|services\.txt|setup\.sh|pre-install\.sh|gotchas)($|/) ]] || [[ "$rel_d" =~ ^\.config/omarchy/plugins($|/) ]] || [[ "$rel_d" =~ __pycache__|\.seed$ ]]; then
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
        # Exclude ignored metadata files, pycache, non-dotfile trees, and omarchy plugins (synced as real files)
        if [[ "$rel_item" =~ ^(packages\.txt|services\.txt|setup\.sh|pre-install\.sh|webapps|gotchas)($|/) ]] || [[ "$rel_item" =~ ^\.stow ]] || [[ "$rel_item" =~ ^\.config/omarchy/plugins($|/) ]] || [[ "$rel_item" =~ __pycache__|\.pyc$|\.seed$ ]]; then
            continue
        fi

        local target="$HOME/$rel_item"

        # Check if the target is an existing real file or conflicting symlink
        if [ -e "$target" ] || [ -L "$target" ]; then
            check_and_backup_path "$target"
        fi
    done < <(find "$pkg_dir" -mindepth 1 \( -type f -o -type l \) -print0)
}

# Collect missing repo and AUR packages across one or more package files, then install in one batch
install_packages_from_files() {
    local missing_repo_pkgs=()
    local missing_aur_pkgs=()
    local -A seen_pkgs=()

    for pkg_file in "$@"; do
        [ ! -f "$pkg_file" ] && continue

        local pkgs=()
        while IFS= read -r line || [ -n "$line" ]; do
            line=$(echo "$line" | sed 's/#.*//' | xargs)
            [ -z "$line" ] && continue
            pkgs+=("$line")
        done < "$pkg_file"

        [ ${#pkgs[@]} -eq 0 ] && continue

        local rel_path="${pkg_file#$DOTFILES_DIR/}"
        echo "--> Checking packages from $rel_path (${#pkgs[@]} items)..."

        local file_missing=0
        for pkg in "${pkgs[@]}"; do
            if [ -n "${seen_pkgs[$pkg]:-}" ]; then
                continue
            fi
            seen_pkgs["$pkg"]=1

            if pacman -Q "$pkg" &>/dev/null; then
                continue
            fi
            file_missing=$((file_missing + 1))
            if pacman -Si "$pkg" &>/dev/null; then
                missing_repo_pkgs+=("$pkg")
            else
                missing_aur_pkgs+=("$pkg")
            fi
        done

        if [ "$file_missing" -eq 0 ]; then
            echo "    All packages from $rel_path are already installed."
        fi
    done

    if [ ${#missing_repo_pkgs[@]} -eq 0 ] && [ ${#missing_aur_pkgs[@]} -eq 0 ]; then
        return 0
    fi

    if [ "$DRY_RUN" = false ]; then
        ensure_privilege_session || {
            echo "    Warning: Skipping privileged package installation (authentication unavailable)." >&2
            return 0
        }
    fi

    # 1. Install missing official repository packages in one batch
    if [ ${#missing_repo_pkgs[@]} -gt 0 ]; then
        echo "    Installing repository packages: ${missing_repo_pkgs[*]}..."
        if [ "$DRY_RUN" = true ]; then
            echo "    [dry-run] Would install via pacman/omarchy: ${missing_repo_pkgs[*]}"
        elif [ "$ELEVATE_MODE" = "root" ]; then
            pacman -S --needed --noconfirm "${missing_repo_pkgs[@]}" || true
        elif command -v omarchy &>/dev/null; then
            omarchy pkg add "${missing_repo_pkgs[@]}" || run_elevated pacman -S --needed --noconfirm "${missing_repo_pkgs[@]}" || true
        else
            run_elevated pacman -S --needed --noconfirm "${missing_repo_pkgs[@]}" || true
        fi
    fi

    # 2. Install missing AUR packages in one batch
    if [ ${#missing_aur_pkgs[@]} -gt 0 ]; then
        echo "    Installing AUR packages: ${missing_aur_pkgs[*]}..."
        if [ "$DRY_RUN" = true ]; then
            echo "    [dry-run] Would install via AUR (omarchy pkg aur add / yay): ${missing_aur_pkgs[*]}"
        elif command -v omarchy &>/dev/null; then
            omarchy pkg aur add "${missing_aur_pkgs[@]}" || true
        elif command -v yay &>/dev/null; then
            yay -S --needed --noconfirm "${missing_aur_pkgs[@]}" || true
        else
            echo "    Warning: Neither omarchy nor yay found to install AUR packages: ${missing_aur_pkgs[*]}" >&2
        fi
    fi
}

install_omarchy_aether() {
    if command -v omarchy-aether &>/dev/null; then
        return 0
    fi

    local repo_url="${OMARCHY_AETHER_REPO:-https://github.com/JValdivia23/omarchy-aether.git}"
    local project_dir="${OMARCHY_AETHER_DIR:-$HOME/Projects/omarchy-aether}"

    echo "--> Installing omarchy-aether from $repo_url..."
    if [ "$DRY_RUN" = true ]; then
        echo "    [dry-run] Would clone/build $repo_url in $project_dir and install package"
        return 0
    fi

    if [ ! -d "$project_dir/.git" ]; then
        mkdir -p "$(dirname "$project_dir")"
        git clone --depth 1 "$repo_url" "$project_dir" || {
            echo "    Warning: Could not clone $repo_url" >&2
            return 1
        }
    fi

    if [ ! -f "$project_dir/pkgbuild/PKGBUILD" ]; then
        echo "    Warning: PKGBUILD not found in $project_dir/pkgbuild" >&2
        return 1
    fi

    local deps=(qt6-base qt6-declarative qt6-wayland xdg-desktop-portal matugen libvips gcc make)
    local missing_deps=()
    local dep
    for dep in "${deps[@]}"; do
        if ! pacman -Qi "$dep" &>/dev/null; then
            missing_deps+=("$dep")
        fi
    done
    if [ "${#missing_deps[@]}" -gt 0 ]; then
        run_elevated pacman -S --needed --noconfirm "${missing_deps[@]}" || return 1
    fi

    (
        cd "$project_dir/pkgbuild" || exit 1
        makepkg -f --noconfirm
    ) || return 1

    local pkgfile
    pkgfile=$(find "$project_dir/pkgbuild" -maxdepth 1 -type f -name 'omarchy-aether-*.pkg.tar.*' ! -name '*-debug-*' | sort -V | tail -n 1)
    if [ -n "$pkgfile" ]; then
        run_elevated pacman -U --noconfirm "$pkgfile"
    else
        echo "    Warning: Built omarchy-aether package archive not found" >&2
        return 1
    fi
}

# --- 3. Packages Installation Step ---
if [ "$DO_PACKAGES" = true ]; then
    echo "==> [2/4] Synchronizing System & Profile Packages..."

    # 0. Profile pre-install hooks (e.g. repository setup such as linux-surface)
    for p in "${STOWABLE_PROFILES[@]}"; do
        PRE_INSTALL="$DOTFILES_DIR/profiles/$p/pre-install.sh"
        if [ -f "$PRE_INSTALL" ]; then
            echo "--> Running pre-install hook for profile '$p'..."
            if [ "$DRY_RUN" = true ]; then
                echo "    [dry-run] Would execute: bash $PRE_INSTALL"
            else
                ensure_privilege_session || true
                chmod +x "$PRE_INSTALL"
                bash "$PRE_INSTALL"
            fi
        fi
    done

    # 1. Core + profile packages installed in unified repo/AUR batches
    PKG_FILES=("$DOTFILES_DIR/core/packages.txt")
    for p in "${STOWABLE_PROFILES[@]}"; do
        if [ -f "$DOTFILES_DIR/profiles/$p/packages.txt" ]; then
            PKG_FILES+=("$DOTFILES_DIR/profiles/$p/packages.txt")
        fi
    done
    install_packages_from_files "${PKG_FILES[@]}"
    install_omarchy_aether || true
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
                 "$HOME/.config/omarchy" \
                 "$HOME/.config/omarchy/plugins" \
                 "$HOME/.local/bin" \
                 "$HOME/.local/share/applications" \
                 "$HOME/.local/share/icons" \
                 "$HOME/.agents/skills/system-personalization"
    fi

    # Ensure edgepad binary is present for core touchpad gestures
    if [ ! -f "$DOTFILES_DIR/core/.local/bin/edgepad" ]; then
        echo "--> Downloading edgepad binary from GitHub Releases..."
        if [ "$DRY_RUN" = false ]; then
            mkdir -p "$DOTFILES_DIR/core/.local/bin"
            curl -fsSL https://github.com/assembledev/edgepad/releases/latest/download/edgepad-x86_64-unknown-linux-musl -o "$DOTFILES_DIR/core/.local/bin/edgepad"
            chmod +x "$DOTFILES_DIR/core/.local/bin/edgepad"
        else
            echo "    [dry-run] Would download edgepad binary to core/.local/bin/edgepad"
        fi
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
                ensure_privilege_session || true
                omarchy pkg add stow || true
            elif command -v pacman &>/dev/null; then
                run_elevated pacman -S --needed --noconfirm stow || true
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
        "--ignore=^pre-install\.sh$"
        "--ignore=^webapps"
        "--ignore=^gotchas"
        "--ignore=^\.config/omarchy/plugins"
        "--ignore=^\.stow-local-ignore$"
        "--ignore=__pycache__"
        "--ignore=\.pyc$"
        "--ignore=\.seed$"
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
                if [[ "$rel" =~ ^(packages\.txt|services\.txt|setup\.sh|pre-install\.sh|webapps|gotchas)($|/) ]] || [[ "$rel" =~ ^\.stow ]] || [[ "$rel" =~ ^\.config/omarchy/plugins($|/) ]] || [[ "$rel" =~ __pycache__|\.pyc$|\.seed$ ]]; then
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

    # Sync Omarchy shell plugins as real files (omarchy-plugin-validate rejects symlinks)
    sync_omarchy_plugins() {
        local pkg_dir="$1"
        local plugins_src="$pkg_dir/.config/omarchy/plugins"
        [ -d "$plugins_src" ] || return 0

        for plugin_src in "$plugins_src"/*/; do
            [ -d "$plugin_src" ] || continue
            local plugin_name
            plugin_name="$(basename "$plugin_src")"
            local dest_plugin="$HOME/.config/omarchy/plugins/$plugin_name"

            if [ "$DRY_RUN" = true ]; then
                echo "    [dry-run] Sync plugin $plugin_name -> $dest_plugin"
                continue
            fi

            if [ -L "$dest_plugin" ]; then
                rm -f "$dest_plugin"
            fi
            mkdir -p "$dest_plugin"
            # Remove any leftover symlinks from prior Stow runs
            find "$dest_plugin" -name .git -prune -o -type l -delete 2>/dev/null || true

            if command -v rsync &>/dev/null; then
                rsync -a --delete --copy-links --exclude='.git' --exclude='__pycache__' "$plugin_src" "$dest_plugin/"
            else
                rm -rf "$dest_plugin"
                cp -aL "$plugin_src" "$dest_plugin"
            fi
        done
    }

    echo "--> Syncing Omarchy shell plugins (real files)..."
    sync_omarchy_plugins "$DOTFILES_DIR/core"
    for p in "${STOWABLE_PROFILES[@]}"; do
        sync_omarchy_plugins "$DOTFILES_DIR/profiles/$p"
    done

    # Link custom webapp icons to standard XDG directories
    if [ -d "$DOTFILES_DIR/core/.local/share/applications/icons" ] && [ "$DRY_RUN" = false ]; then
        mkdir -p "$HOME/.local/share/icons" \
                 "$HOME/.local/share/pixmaps" \
                 "$HOME/.local/share/icons/hicolor/256x256/apps" \
                 "$HOME/.local/share/icons/hicolor/512x512/apps" \
                 "$HOME/.local/share/icons/hicolor/scalable/apps"

        for icon in "$DOTFILES_DIR"/core/.local/share/applications/icons/*; do
            if [ -f "$icon" ]; then
                filename="$(basename "$icon")"
                name="${filename%.*}"
                ext="${filename##*.}"
                lower="$(echo "$name" | tr '[:upper:]' '[:lower:]').$ext"

                ln -sf "$icon" "$HOME/.local/share/icons/$filename" 2>/dev/null || true
                ln -sf "$icon" "$HOME/.local/share/icons/$lower" 2>/dev/null || true
                ln -sf "$icon" "$HOME/.local/share/pixmaps/$filename" 2>/dev/null || true
                ln -sf "$icon" "$HOME/.local/share/pixmaps/$lower" 2>/dev/null || true

                if [ "$ext" = "png" ]; then
                    ln -sf "$icon" "$HOME/.local/share/icons/hicolor/256x256/apps/$filename" 2>/dev/null || true
                    ln -sf "$icon" "$HOME/.local/share/icons/hicolor/256x256/apps/$lower" 2>/dev/null || true
                    ln -sf "$icon" "$HOME/.local/share/icons/hicolor/512x512/apps/$filename" 2>/dev/null || true
                    ln -sf "$icon" "$HOME/.local/share/icons/hicolor/512x512/apps/$lower" 2>/dev/null || true
                elif [ "$ext" = "svg" ]; then
                    ln -sf "$icon" "$HOME/.local/share/icons/hicolor/scalable/apps/$filename" 2>/dev/null || true
                    ln -sf "$icon" "$HOME/.local/share/icons/hicolor/scalable/apps/$lower" 2>/dev/null || true
                fi
            fi
        done

        if command -v gtk-update-icon-cache &>/dev/null; then
            gtk-update-icon-cache -f -t "$HOME/.local/share/icons" 2>/dev/null || true
            gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
        fi
    fi

    # Update desktop application database
    if command -v update-desktop-database &>/dev/null && [ "$DRY_RUN" = false ]; then
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
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
                if grep -qE '\bsudo\b' "$SETUP_SCRIPT" 2>/dev/null; then
                    ensure_privilege_session || true
                fi
                chmod +x "$SETUP_SCRIPT"
                bash "$SETUP_SCRIPT"
            fi
        fi
    done

    # 2. Link profile-specific gotchas into system-personalization skill
    DEST_GOTCHAS_DIR="$HOME/.agents/skills/system-personalization/references/gotchas"
    if [ -d "$DEST_GOTCHAS_DIR" ] && [ "$DRY_RUN" = false ]; then
        # Clean up any symlinks pointing into profiles/*/gotchas before linking active profile
        find "$DEST_GOTCHAS_DIR" -maxdepth 1 -type l | while read -r existing_link; do
            link_target="$(readlink "$existing_link" 2>/dev/null || true)"
            if [[ "$link_target" == *"/profiles/"*"/gotchas/"* ]]; then
                rm -f "$existing_link"
            fi
        done
    fi
    for p in "${STOWABLE_PROFILES[@]}"; do
        PROFILE_GOTCHAS_DIR="$DOTFILES_DIR/profiles/$p/gotchas"
        if [ -d "$PROFILE_GOTCHAS_DIR" ]; then
            echo "--> Linking profile gotchas for '$p'..."
            for gotcha_file in "$PROFILE_GOTCHAS_DIR"/*; do
                [ -f "$gotcha_file" ] || continue
                gname="$(basename "$gotcha_file")"
                [ "$gname" = "README.md" ] && continue
                dest="$DEST_GOTCHAS_DIR/$gname"
                if [ "$DRY_RUN" = true ]; then
                    echo "    [dry-run] ln -sf \"$gotcha_file\" \"$dest\""
                else
                    mkdir -p "$DEST_GOTCHAS_DIR"
                    ln -sf "$gotcha_file" "$dest"
                    echo "    Linked gotcha: $gname"
                fi
            done
        fi
    done

    # 3. Run system-personalization skill initializer
    INIT_SKILL_SCRIPT="$DOTFILES_DIR/agents/.agents/skills/system-personalization/scripts/init-skill.sh"
    if [ -f "$INIT_SKILL_SCRIPT" ]; then
        echo "--> Initializing system-personalization AI skill..."
        if [ "$DRY_RUN" = true ]; then
            echo "    [dry-run] Would execute: bash $INIT_SKILL_SCRIPT --profiles \"$ACTIVE_PROFILES\""
        else
            chmod +x "$INIT_SKILL_SCRIPT"
            bash "$INIT_SKILL_SCRIPT" --profiles "$ACTIVE_PROFILES"
            if [ -d "$HOME/.gemini/config/skills" ]; then
                ln -sfn "$HOME/.agents/skills/system-personalization" "$HOME/.gemini/config/skills/system-personalization"
            fi
        fi
    fi

    # 4. Configure udev rules & kernel modules for edgepad (touchpad edge gestures)
    EDGEPAD_UDEV_RULE="/etc/udev/rules.d/70-edgepad.rules"
    if [ ! -f "$EDGEPAD_UDEV_RULE" ]; then
        echo "--> Configuring udev uaccess rule & uinput for edgepad..."
        EDGEPAD_RULE_CONTENT='# Grant the active local seat user access through systemd-logind uaccess ACLs.
SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT_TOUCHPAD}=="1", TAG+="uaccess"
SUBSYSTEM=="misc", KERNEL=="uinput", TAG+="uaccess", OPTIONS+="static_node=uinput"'
        EDGEPAD_CMD="printf '%s\n' '$EDGEPAD_RULE_CONTENT' > '$EDGEPAD_UDEV_RULE' && modprobe uinput && echo 'uinput' > /etc/modules-load.d/uinput.conf && udevadm control --reload && udevadm trigger --subsystem-match=input --action=change && udevadm trigger --subsystem-match=misc --action=change"
        if [ "$DRY_RUN" = true ]; then
            echo "    [dry-run] Would install $EDGEPAD_UDEV_RULE, load uinput, and reload udev"
        else
            run_elevated bash -c "$EDGEPAD_CMD" || true
        fi
    fi

    # 5. Enable user systemd services and daemons (edgepad, Surface Aether cycler)
    if command -v systemctl &>/dev/null; then
        if [ -f "$HOME/.config/systemd/user/edgepad.service" ]; then
            echo "--> Reloading systemd user daemon and activating edgepad daemon..."
            if [ "$DRY_RUN" = true ]; then
                echo "    [dry-run] systemctl --user daemon-reload"
                echo "    [dry-run] systemctl --user enable --now edgepad.service"
            else
                systemctl --user daemon-reload || true
                systemctl --user enable --now edgepad.service || true
                echo "    Enabled edgepad.service"
            fi
        fi
        if [ -f "$HOME/.config/systemd/user/omarchy-aether-cycler.timer" ]; then
            echo "--> Activating omarchy-aether-cycler.timer..."
            if [ "$DRY_RUN" = true ]; then
                echo "    [dry-run] systemctl --user enable --now omarchy-aether-cycler.timer"
            else
                systemctl --user enable --now omarchy-aether-cycler.timer || true
                echo "    Enabled omarchy-aether-cycler.timer"
            fi
        fi
    fi

    # 6. Ensure interactive Fish auto-launch guard exists in ~/.bashrc
    [ -f "$HOME/.bashrc" ] || touch "$HOME/.bashrc"
    if ! grep -q "Auto-launch fish shell for interactive sessions" "$HOME/.bashrc"; then
        echo "--> Adding Fish interactive auto-launch guard to ~/.bashrc..."
        if [ "$DRY_RUN" = true ]; then
            echo "    [dry-run] Would append Fish auto-launch guard to ~/.bashrc"
        else
            cat >> "$HOME/.bashrc" << 'EOF'

# Auto-launch fish shell for interactive sessions (CachyOS terminal experience)
if command -v fish &>/dev/null; then
  if [[ $(ps --no-header --pid=$PPID --format=comm) != "fish" && -z ${BASH_EXECUTION_STRING} ]]; then
    shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=''
    exec fish $LOGIN_OPTION
  fi
fi
EOF
            echo "    Added Fish auto-launch guard to ~/.bashrc"
        fi
    fi
    # 7. Sync wallpaper library & Aether index/staging
    WALLS_DIR="$HOME/Pictures/Wallpapers/walls"
    SYNC_SCRIPT="$DOTFILES_DIR/core/.local/bin/omarchy-sync-wallpapers"
    if [ -x "$SYNC_SCRIPT" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "--> [dry-run] Would run: $SYNC_SCRIPT --init"
        else
            bash "$SYNC_SCRIPT" --init || true
        fi
    elif [ ! -d "$WALLS_DIR" ]; then
        echo "--> Wallpaper collection not detected in ~/Pictures/Wallpapers/walls."
        echo "    Run 'omarchy-sync-wallpapers' anytime to fetch and index JValdivia23/walls."
    fi

    # 8. Reload Hyprland if active
    if command -v hyprctl &>/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        echo "--> Reloading Hyprland configuration..."
        if [ "$DRY_RUN" = false ]; then
            hyprctl reload &>/dev/null || true
        else
            echo "    [dry-run] hyprctl reload"
        fi
    fi

    # 9. Ensure Aether menu integration & fallback staging/sync
    if command -v omarchy-aether &>/dev/null; then
        if [ -f "$HOME/.config/omarchy-aether/menu.json" ] && \
           { [ ! -f "$HOME/.config/omarchy/extensions/omarchy-menu.jsonc" ] || ! grep -q "omarchy-aether background" "$HOME/.config/omarchy/extensions/omarchy-menu.jsonc" 2>/dev/null; }; then
            echo "--> Integrating omarchy-aether into Omarchy background menu..."
            if [ "$DRY_RUN" = false ]; then
                omarchy-aether integrate --yes --json >/dev/null || true
            else
                echo "    [dry-run] omarchy-aether integrate --yes --json"
            fi
        fi

        aether_user_dir="$HOME/.config/omarchy/themes/aether"
        aether_needs_stage=false
        if [ ! -f "$aether_user_dir/colors.toml" ] || [ ! -f "$aether_user_dir/preview.png" ] || [ ! -f "$aether_user_dir/.omarchy-aether.json" ]; then
            aether_needs_stage=true
        elif ! omarchy-aether check "$aether_user_dir/colors.toml" &>/dev/null; then
            aether_needs_stage=true
        fi

        if [ "$aether_needs_stage" = true ]; then
            aether_seed_img=""
            for p in "${STOWABLE_PROFILES[@]}"; do
                aether_profile_walls="$DOTFILES_DIR/profiles/$p/Pictures/Wallpapers"
                if [ -d "$aether_profile_walls" ]; then
                    aether_seed_img="$(find "$aether_profile_walls" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | head -n 1)"
                    [ -n "$aether_seed_img" ] && break
                fi
            done
            if [ -n "$aether_seed_img" ] && [ -f "$aether_seed_img" ]; then
                echo "--> Staging Aether theme from profile fallback $(basename "$aether_seed_img")..."
                if [ "$DRY_RUN" = false ]; then
                    if [ -L "$aether_user_dir" ] || { [ -e "$aether_user_dir" ] && [ ! -f "$aether_user_dir/.omarchy-aether.json" ]; }; then
                        mv "$aether_user_dir" "${aether_user_dir}.legacy.$(date +%Y%m%d_%H%M%S)"
                    fi
                    omarchy-aether apply --image "$aether_seed_img" --stage-only --json >/dev/null || true
                else
                    echo "    [dry-run] omarchy-aether apply --image $aether_seed_img --stage-only --json"
                fi
            fi
        fi

        if [ "$DRY_RUN" = false ] && command -v omarchy &>/dev/null && \
           [ "$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null || true)" = "aether" ] && \
           [ -f "$aether_user_dir/colors.toml" ]; then
            if [ ! -f "$HOME/.local/state/omarchy/current/theme/colors.toml" ] || \
               ! cmp -s "$aether_user_dir/colors.toml" "$HOME/.local/state/omarchy/current/theme/colors.toml"; then
                echo "--> Reloading active Aether theme..."
                omarchy theme set aether || true
            fi
        fi
    else
        # Legacy colors.toml.seed fallback (for profiles without omarchy-aether)
        for p in "${STOWABLE_PROFILES[@]}"; do
            aether_seed="$DOTFILES_DIR/profiles/$p/.config/omarchy/themes/aether/colors.toml.seed"
            if [ -f "$aether_seed" ]; then
                aether_user_dir="$HOME/.config/omarchy/themes/aether"
                mkdir -p "$aether_user_dir"
                if [ -L "$aether_user_dir/colors.toml" ]; then
                    rm -f "$aether_user_dir/colors.toml"
                fi
                if [ ! -f "$aether_user_dir/colors.toml" ]; then
                    echo "--> Seeding dynamic aether colors.toml..."
                    if [ "$DRY_RUN" = false ]; then
                        cp "$aether_seed" "$aether_user_dir/colors.toml"
                    else
                        echo "    [dry-run] cp $aether_seed $aether_user_dir/colors.toml"
                    fi
                fi

                aether_bg_dir="$aether_user_dir/backgrounds"
                aether_profile_walls="$DOTFILES_DIR/profiles/$p/Pictures/Wallpapers"
                if [ -d "$aether_profile_walls" ] && [ -z "$(find -L "$aether_bg_dir" -maxdepth 1 -type f 2>/dev/null | head -n 1)" ]; then
                    echo "--> Linking default backgrounds for aether theme selector..."
                    if [ "$DRY_RUN" = false ]; then
                        mkdir -p "$aether_bg_dir"
                        for wall in "$aether_profile_walls"/*; do
                            [ -f "$wall" ] || continue
                            ln -sf "$wall" "$aether_bg_dir/$(basename "$wall")"
                        done
                    else
                        echo "    [dry-run] ln -sf $aether_profile_walls/* $aether_bg_dir/"
                    fi
                fi
            fi
        done
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
if [[ "$ACTIVE_PROFILES" =~ surface ]] && [[ ! "$ACTIVE_PROFILES" =~ surface-go3 ]]; then
    echo "  2. Test active Surface hardware daemons:"
    echo "     systemctl status surface-dtx-daemon iptsd 2>/dev/null || true"
fi
echo "  3. Download/sync JValdivia23/walls and index for Aether:"
echo "     omarchy-sync-wallpapers"
echo "  4. Log out and log back in (or restart your session) to"
echo "     load all environment variables."
echo "======================================================="
