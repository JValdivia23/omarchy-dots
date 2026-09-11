#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "==> Setting up ASUS ROG profile..."

# Enable and start hardware services if available
if [ -f "$SCRIPT_DIR/services.txt" ]; then
    while IFS= read -r service || [ -n "$service" ]; do
        [[ -z "$service" || "$service" =~ ^# ]] && continue
        echo "--> Checking service: $service"
        if systemctl is-active --quiet "$service"; then
            echo "    $service is already active."
        elif systemctl list-unit-files "$service" &>/dev/null; then
            echo "    Enabling and starting $service..."
            sudo systemctl enable --now "$service" || true
        else
            echo "    Notice: $service unit not found on this system. Skipping."
        fi
    done < "$SCRIPT_DIR/services.txt"
fi

# Ensure AniMatrix desktop launcher and icons are registered
if [ -d "$SCRIPT_DIR/webapps" ]; then
    echo "--> Installing AniMatrix desktop entry and icons..."
    mkdir -p "$HOME/.local/share/applications"
    mkdir -p "$HOME/.local/share/icons"
    if [ -f "$SCRIPT_DIR/webapps/AniMatrix.desktop" ]; then
        cp "$SCRIPT_DIR/webapps/AniMatrix.desktop" "$HOME/.local/share/applications/"
    fi
    if [ -f "$SCRIPT_DIR/webapps/icons/AniMatrix.png" ]; then
        cp "$SCRIPT_DIR/webapps/icons/AniMatrix.png" "$HOME/.local/share/icons/"
    fi
    if command -v update-desktop-database &>/dev/null; then
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi
fi

# Ensure anime-lid-charging has execute permissions
if [ -f "$SCRIPT_DIR/.local/bin/anime-lid-charging" ]; then
    chmod +x "$SCRIPT_DIR/.local/bin/anime-lid-charging"
fi

echo "==> ASUS ROG profile setup complete."
