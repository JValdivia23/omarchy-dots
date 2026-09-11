#!/usr/bin/env bash
# snapshot.sh — Capture current Omarchy Quattro system state to stdout
# Usage: bash scripts/snapshot.sh

set -euo pipefail

echo "======================================================="
echo "       Omarchy Quattro System Diagnostic Snapshot      "
echo "======================================================="

echo -e "\n=== SYSTEM & HARDWARE ==="
echo "Hostname:     $(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || echo 'Unknown')"
echo "Product:      $(cat /sys/class/dmi/id/product_name 2>/dev/null || echo 'Unknown')"
echo "Architecture: $(uname -m 2>/dev/null || echo 'Unknown')"

echo -e "\n=== OS & KERNEL ==="
if [ -f /etc/os-release ]; then
    grep -E "^(NAME|PRETTY_NAME|VERSION_ID|ID)=" /etc/os-release 2>/dev/null || true
fi
echo "Kernel:       $(uname -r)"

echo -e "\n=== CPU ==="
lscpu 2>/dev/null | grep -i "Model name" | sed -e 's/.*:[[:space:]]*//' | head -n 1 | xargs || true
echo "Cores/Threads: $(nproc 2>/dev/null || echo 'Unknown')"

echo -e "\n=== GPU(s) ==="
lspci 2>/dev/null | grep -i -E "vga|3d" | sed -e 's/.*controller: //;s/.*controller [0-9a-fA-F:]* //;s/ (rev .*//' || echo "No PCI GPU detected"

echo -e "\n=== MEMORY & SWAP ==="
free -h | awk 'NR<=2 {print $0}'

echo -e "\n=== DISPLAY & COMPOSITOR ==="
echo "Wayland Session: ${XDG_SESSION_TYPE:-unknown}"
if command -v hyprctl &>/dev/null; then
    hyprctl version 2>/dev/null | head -n 1 || echo "Hyprland not running"
    echo -e "\nMonitors:"
    hyprctl monitors 2>/dev/null | grep -E 'Monitor|[0-9]+x[0-9]+@|scale|transform|make|model|availableModes' || true
else
    echo "hyprctl command not found"
fi

echo -e "\n=== SHELL & USER ENVIRONMENT ==="
echo "User:         ${USER:-$(id -un)}"
echo "Shell:        ${SHELL:-unknown}"

echo -e "\n=== KEY PACKAGES ==="
PACKAGES=(
    hyprland
    omarchy
    kitty
    alacritty
    foot
    ghostty
    firefox
    zen-browser
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
    surface-dtx-daemon
    iptsd
    supergfxctl
    asusctl
    fcitx5
    localsend
)

for pkg in "${PACKAGES[@]}"; do
    pacman -Q "$pkg" 2>/dev/null | awk '{printf "%-24s %s\n", $1, $2}' || true
done

echo -e "\n=== HYPRLAND CONFIGURATION ERRORS ==="
if command -v hyprctl &>/dev/null; then
    ERRORS=$(hyprctl configerrors 2>/dev/null || true)
    if [ -z "$ERRORS" ] || [ "$ERRORS" = "ok" ]; then
        echo "No configuration errors found (clean)."
    else
        echo "$ERRORS"
    fi
else
    echo "hyprctl not found."
fi

echo -e "\n=== DISK MOUNTS & USAGE ==="
df -h / /home 2>/dev/null | tail -n +2 | awk '{printf "%-15s %-6s %-6s %-6s %-5s %s\n", $1, $2, $3, $4, $5, $6}' || true

echo -e "\n=== RELEVANT HARDWARE DAEMONS ==="
for unit in surface-dtx-daemon "iptsd@dev-hidraw4" supergfxd asusd bluetooth ufw; do
    if systemctl list-unit-files "$unit.service" &>/dev/null || systemctl is-active "$unit" &>/dev/null; then
        STATUS=$(systemctl is-active "$unit" 2>/dev/null || echo "inactive")
        printf "%-30s %s\n" "$unit:" "$STATUS"
    fi
done

echo -e "\n======================================================="
echo "Snapshot completed at: $(date)"
echo "======================================================="
