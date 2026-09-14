#!/usr/bin/env bash
# ==============================================================================
# Surface Profile Pre-Installation Hook
# Bootstraps the linux-surface pacman repository and signing keys
# ==============================================================================
set -euo pipefail

echo "==> [Surface Profile] Checking Linux-Surface kernel repository..."

# 1. Check if linux-surface repository is already configured in /etc/pacman.conf
if ! grep -q "^\[linux-surface\]" /etc/pacman.conf 2>/dev/null; then
    echo "--> Configuring linux-surface repository in /etc/pacman.conf..."

    # Import and sign the linux-surface repository key
    echo "    Importing linux-surface repository GPG key (56C464BAAC421453)..."
    if (( EUID == 0 )); then
        curl -sSfL --connect-timeout 10 --retry 3 https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc | pacman-key --add -
        pacman-key --finger 56C464BAAC421453
        pacman-key --lsign-key 56C464BAAC421453
    else
        curl -sSfL --connect-timeout 10 --retry 3 https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc | sudo pacman-key --add -
        sudo pacman-key --finger 56C464BAAC421453
        sudo pacman-key --lsign-key 56C464BAAC421453
    fi

    # Append [linux-surface] repository block
    echo "    Appending [linux-surface] repository to /etc/pacman.conf..."
    if (( EUID == 0 )); then
        cat >> /etc/pacman.conf <<'EOF'

[linux-surface]
Server = https://pkg.surfacelinux.com/arch/
EOF
        echo "    Refreshing pacman repository databases..."
        pacman -Sy
    else
        sudo tee -a /etc/pacman.conf >/dev/null <<'EOF'

[linux-surface]
Server = https://pkg.surfacelinux.com/arch/
EOF
        echo "    Refreshing pacman repository databases..."
        sudo pacman -Sy
    fi

    echo "    linux-surface repository configured successfully."
else
    echo "    linux-surface repository is already configured in /etc/pacman.conf."
fi
