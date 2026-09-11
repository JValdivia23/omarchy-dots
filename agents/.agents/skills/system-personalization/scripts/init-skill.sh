#!/usr/bin/env bash
# init-skill.sh — Initialize and personalize system-personalization skill for the current machine
# Probes hardware, OS, monitors, and active profiles to generate:
#   1. references/hardware.md
#   2. references/current-state.md
#   3. SKILL.md (rendered from SKILL.md.template)
#
# Usage:
#   bash scripts/init-skill.sh
#   bash scripts/init-skill.sh --profiles "surface, laptop"
#   bash scripts/init-skill.sh "asus, laptop"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ACTIVE_PROFILES_ARG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profiles|-p)
            ACTIVE_PROFILES_ARG="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: ./init-skill.sh [OPTIONS] [PROFILES]"
            echo ""
            echo "Options:"
            echo "  -p, --profiles <list>   Comma-separated list of active profiles (e.g. 'surface, laptop')"
            echo "  -h, --help              Show this help message"
            exit 0
            ;;
        *)
            if [ -z "$ACTIVE_PROFILES_ARG" ]; then
                ACTIVE_PROFILES_ARG="$1"
                shift
            else
                echo "Unknown argument: $1" >&2
                exit 1
            fi
            ;;
    esac
done

echo "======================================================="
echo "   Personalizing System Skill for Omarchy Quattro      "
echo "======================================================="

# --- 1. Probe Hostname ---
SYS_HOSTNAME=$(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || echo "unknown-host")
echo "-> Hostname:        $SYS_HOSTNAME"

# --- 2. Probe Product Name / Model ---
SYS_PRODUCT_NAME="Generic System"
if [ -f /sys/class/dmi/id/product_name ]; then
    SYS_PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name 2>/dev/null | xargs || echo "Generic System")
elif [ -f /sys/devices/virtual/dmi/id/product_name ]; then
    SYS_PRODUCT_NAME=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null | xargs || echo "Generic System")
fi
echo "-> Product Name:    $SYS_PRODUCT_NAME"

# --- 3. Probe OS ---
SYS_OS="Arch Linux"
if [ -f /etc/os-release ]; then
    OS_PRETTY=$(grep -E "^PRETTY_NAME=" /etc/os-release | cut -d= -f2- | tr -d '"' || true)
    OS_NAME=$(grep -E "^NAME=" /etc/os-release | cut -d= -f2- | tr -d '"' || true)
    OS_VER=$(grep -E "^VERSION_ID=" /etc/os-release | cut -d= -f2- | tr -d '"' || true)
    SYS_OS="${OS_PRETTY:-$OS_NAME}"
    if [ -n "$OS_VER" ] && [[ "$SYS_OS" != *"$OS_VER"* ]]; then
        SYS_OS="$SYS_OS $OS_VER"
    fi
fi
echo "-> Operating System: $SYS_OS"

# --- 4. Probe Kernel ---
SYS_KERNEL=$(uname -r)
echo "-> Kernel:          $SYS_KERNEL"

# --- 5. Probe CPU ---
SYS_CPU="Unknown CPU"
if command -v lscpu &>/dev/null; then
    SYS_CPU=$(lscpu 2>/dev/null | grep -i "Model name" | sed -e 's/.*:[[:space:]]*//' | head -n 1 | xargs || true)
fi
if [ -z "$SYS_CPU" ] || [ "$SYS_CPU" = "Unknown CPU" ]; then
    SYS_CPU=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | sed -e 's/.*:[[:space:]]*//' | xargs || echo "Unknown CPU")
fi
echo "-> CPU:             $SYS_CPU"

# --- 6. Probe GPU ---
SYS_GPU=""
if command -v lspci &>/dev/null; then
    SYS_GPU=$(lspci 2>/dev/null | grep -i -E "vga|3d" | sed -e 's/.*controller: //;s/.*controller [0-9a-fA-F:]* //;s/ (rev .*//' | tr '\n' ';' | sed -e 's/;$//;s/;/ \/ /g' || true)
fi
if [ -z "$SYS_GPU" ]; then
    SYS_GPU="Integrated Graphics"
fi
echo "-> GPU:             $SYS_GPU"

# --- 7. Probe RAM ---
SYS_RAM=$(free -h 2>/dev/null | awk '/Mem:/ {print $2}' || echo "Unknown")
echo "-> Memory (RAM):    $SYS_RAM"

# --- 8. Probe Primary Display ---
SYS_PRIMARY_DISPLAY=""
if command -v hyprctl &>/dev/null && command -v jq &>/dev/null; then
    SYS_PRIMARY_DISPLAY=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0] | "\(.name) (\(.width)x\(.height)@\(.refreshRate | round)Hz, scale \(.scale))"' 2>/dev/null || true)
fi
if [ -z "$SYS_PRIMARY_DISPLAY" ] || [ "$SYS_PRIMARY_DISPLAY" = "null" ]; then
    if command -v hyprctl &>/dev/null; then
        SYS_PRIMARY_DISPLAY=$(hyprctl monitors 2>/dev/null | grep -E "Monitor" | head -n 1 | awk '{print $2}' || true)
    fi
fi
if [ -z "$SYS_PRIMARY_DISPLAY" ]; then
    SYS_PRIMARY_DISPLAY="eDP-1 (Default Display)"
fi
echo "-> Primary Display: $SYS_PRIMARY_DISPLAY"

# --- 9. Determine Active Profiles ---
if [ -n "$ACTIVE_PROFILES_ARG" ]; then
    SYS_ACTIVE_PROFILES="$ACTIVE_PROFILES_ARG"
else
    DETECTED=()
    # Check for Surface
    if [[ "${SYS_PRODUCT_NAME,,}" =~ surface ]] || [[ "${SYS_KERNEL,,}" =~ surface ]]; then
        DETECTED+=("surface")
    fi
    # Check for ASUS
    if [[ "${SYS_PRODUCT_NAME,,}" =~ (rog|zephyrus|tuf|asus) ]] || command -v supergfxctl &>/dev/null || command -v asusctl &>/dev/null; then
        DETECTED+=("asus")
    fi
    # Check for Laptop vs Desktop
    if [ -d /sys/class/power_supply ] && ls /sys/class/power_supply/ 2>/dev/null | grep -q -E "BAT|battery"; then
        DETECTED+=("laptop")
    else
        DETECTED+=("desktop")
    fi

    if [ ${#DETECTED[@]} -gt 0 ]; then
        SYS_ACTIVE_PROFILES=""
        for item in "${DETECTED[@]}"; do
            if [ -z "$SYS_ACTIVE_PROFILES" ]; then
                SYS_ACTIVE_PROFILES="$item"
            else
                SYS_ACTIVE_PROFILES="$SYS_ACTIVE_PROFILES, $item"
            fi
        done
    else
        SYS_ACTIVE_PROFILES="default"
    fi
fi
echo "-> Active Profiles: $SYS_ACTIVE_PROFILES"

echo ""
echo "--> Generating references/hardware.md..."

# Precompute hardware sub-sections
LSCPU_INFO=$(lscpu 2>/dev/null | grep -E "CPU max MHz|CPU min MHz|L3 cache" | sed 's/^[ \t]*/- **/' | sed 's/:[ \t]*/**: /' || true)

LSPCI_GPU_DETAILS=""
if command -v lspci &>/dev/null; then
    LSPCI_GPU_DETAILS=$(lspci -k 2>/dev/null | grep -A 2 -i -E "vga|3d" | sed 's/^/  /' || true)
fi

DISK_INFO=$(df -h / /home 2>/dev/null || true)

MONITOR_DETAILS=$(hyprctl monitors 2>/dev/null | grep -E 'Monitor|[0-9]+x[0-9]+@|scale|transform|make|model|availableModes' || echo "Monitor details unavailable")

TOUCH_DETAILS=""
if systemctl is-active --quiet "iptsd@dev-hidraw4" 2>/dev/null || systemctl is-active --quiet iptsd 2>/dev/null; then
    TOUCH_DETAILS="- **Touchscreen**: Intel Precise Touch & Stylus Daemon (iptsd) active"
fi

DTX_DETAILS=""
if [ -f /sys/class/dmi/id/product_name ] && grep -qi "surface" /sys/class/dmi/id/product_name 2>/dev/null; then
    LATCH_STAT=$(surface dtx get-latchstatus 2>/dev/null || echo "Supported via surface-dtx-daemon")
    DTX_DETAILS="- **Surface DTX Latch**: $LATCH_STAT"
fi

BATTERY_INFO=""
if [ -d /sys/class/power_supply ]; then
    for bat in /sys/class/power_supply/BAT*; do
        if [ -d "$bat" ]; then
            bname=$(basename "$bat")
            bcap=$(cat "$bat/capacity" 2>/dev/null || echo "Unknown")
            bstat=$(cat "$bat/status" 2>/dev/null || echo "Unknown")
            BATTERY_INFO="${BATTERY_INFO}- **$bname**: ${bcap}% (${bstat})\n"
        fi
    done
fi

# --- 10. Generate references/hardware.md ---
HARDWARE_FILE="$SKILL_ROOT/references/hardware.md"
cat << EOF > "$HARDWARE_FILE"
# Hardware Specifications (\`$SYS_HOSTNAME\` - $SYS_PRODUCT_NAME)

Live physical system specifications and active peripherals probed automatically.

## System & Architecture
- **Product / Model**: $SYS_PRODUCT_NAME
- **Hostname**: \`$SYS_HOSTNAME\`
- **Architecture**: $(uname -m)
- **Active Profiles**: $SYS_ACTIVE_PROFILES

## CPU & Processing
- **Processor**: $SYS_CPU
- **Physical Cores / Threads**: $(nproc 2>/dev/null || echo 'Unknown')
$LSCPU_INFO

## Graphics Processing Units (GPUs)
- **Detected GPU(s)**: $SYS_GPU
$LSPCI_GPU_DETAILS

## Memory & Swap
- **Total System RAM**: $SYS_RAM
- **Swap Space**: $(free -h 2>/dev/null | awk '/Swap:/ {print $2}' || echo 'None')

## Storage & Filesystems
\`\`\`
$DISK_INFO
\`\`\`

## Displays & Monitors
- **Primary Display**: $SYS_PRIMARY_DISPLAY
\`\`\`
$MONITOR_DETAILS
\`\`\`

## Input Devices & Peripherals
$TOUCH_DETAILS
$DTX_DETAILS
$(if [ -n "$BATTERY_INFO" ]; then
    echo "### Batteries"
    echo -e "$BATTERY_INFO"
fi)
EOF

echo "--> Generating references/current-state.md..."

# Precompute key packages
PACKAGE_TABLE=""
PACKAGES=(
    hyprland
    omarchy
    kitty
    alacritty
    foot
    ghostty
    firefox
    zen-browser-bin
    brave-origin-bin
    grim
    slurp
    satty
    swayimg
    jq
    wl-clipboard
    brightnessctl
    btop
    dolphin
    neovim
    lazygit
    surface-dtx-daemon-bin
    iptsd
    supergfxctl
    asusctl
    fcitx5
    localsend
)
for pkg in "${PACKAGES[@]}"; do
    line=$(pacman -Q "$pkg" 2>/dev/null | awk '{printf "| %s | %s | Core Utility |\n", $1, $2}' || true)
    if [ -n "$line" ]; then
        PACKAGE_TABLE="${PACKAGE_TABLE}${line}\n"
    fi
done

DAEMON_STATUS=""
for unit in surface-dtx-daemon "iptsd@dev-hidraw4" supergfxd asusd bluetooth ufw fcitx5; do
    if systemctl is-active "$unit" &>/dev/null; then
        DAEMON_STATUS="${DAEMON_STATUS}- **$unit**: \`active\`\n"
    fi
done

HYPR_ERRS=$(hyprctl configerrors 2>/dev/null || true)
HYPR_ERR_STATUS="None (clean)"
if [ -n "$HYPR_ERRS" ] && [ "$HYPR_ERRS" != "ok" ]; then
    HYPR_ERR_STATUS="Active errors detected (run 'hyprctl configerrors')"
fi

# --- 11. Generate references/current-state.md ---
CURRENT_STATE_FILE="$SKILL_ROOT/references/current-state.md"
cat << EOF > "$CURRENT_STATE_FILE"
# Current System State

Live system snapshot automatically generated on $(date).

## Operating System & Kernel
- **OS**: $SYS_OS
- **Kernel**: \`$SYS_KERNEL\`
- **Shell**: \`${SHELL:-/usr/bin/bash}\`
- **Compositor**: $(hyprctl version 2>/dev/null | head -n 1 || echo "Hyprland (Version query unavailable)")
- **Active Profiles**: $SYS_ACTIVE_PROFILES

## System Specs & Display
- **Product**: $SYS_PRODUCT_NAME (\`$SYS_HOSTNAME\`)
- **CPU**: $SYS_CPU
- **GPU**: $SYS_GPU
- **RAM**: $SYS_RAM
- **Primary Display**: $SYS_PRIMARY_DISPLAY

## Key Installed Packages & Utilities

| Package | Version | Purpose |
|---------|---------|---------|
$(echo -e "$PACKAGE_TABLE")

## Active Hardware Daemons & Services
$(echo -e "$DAEMON_STATUS")

## Compositor Health
- **Hyprland Errors**: $HYPR_ERR_STATUS
EOF

echo "--> Generating SKILL.md from SKILL.md.template..."

# --- 12. Substitute Variables in SKILL.md.template -> SKILL.md ---
TEMPLATE_FILE="$SKILL_ROOT/SKILL.md.template"
OUTPUT_FILE="$SKILL_ROOT/SKILL.md"

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file $TEMPLATE_FILE not found!" >&2
    exit 1
fi

python3 - "$TEMPLATE_FILE" "$OUTPUT_FILE" \
    "$SYS_HOSTNAME" \
    "$SYS_PRODUCT_NAME" \
    "$SYS_OS" \
    "$SYS_KERNEL" \
    "$SYS_CPU" \
    "$SYS_GPU" \
    "$SYS_PRIMARY_DISPLAY" \
    "$SYS_ACTIVE_PROFILES" << 'PYEOF'
import sys

template_path = sys.argv[1]
output_path = sys.argv[2]

replacements = {
    "{{HOSTNAME}}": sys.argv[3],
    "{{PRODUCT_NAME}}": sys.argv[4],
    "{{OS}}": sys.argv[5],
    "{{KERNEL}}": sys.argv[6],
    "{{CPU}}": sys.argv[7],
    "{{GPU}}": sys.argv[8],
    "{{PRIMARY_DISPLAY}}": sys.argv[9],
    "{{ACTIVE_PROFILES}}": sys.argv[10],
}

with open(template_path, "r", encoding="utf-8") as f:
    content = f.read()

for placeholder, val in replacements.items():
    content = content.replace(placeholder, val)

with open(output_path, "w", encoding="utf-8") as f:
    f.write(content)
PYEOF

echo "======================================================="
echo "  🎉 Skill Personalized Successfully for $SYS_HOSTNAME! "
echo "======================================================="
echo "Files updated:"
echo "  - $SKILL_ROOT/SKILL.md"
echo "  - $HARDWARE_FILE"
echo "  - $CURRENT_STATE_FILE"
echo "======================================================="
