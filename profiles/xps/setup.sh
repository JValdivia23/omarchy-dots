#!/usr/bin/env bash
set -euo pipefail

echo "==> Setting up Dell XPS (xps) profile..."
echo "    Display: 2560x1600@120Hz (scale 1.25, 2048x1280)"
echo "    Input:   Natural scroll + 3/4-finger touchpad gestures enabled"

# Align GTK / GNOME interface text scaling with 1.25x display scale
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 14' || true
    gsettings set org.gnome.desktop.interface document-font-name 'Adwaita Sans 14' || true
    gsettings set org.gnome.desktop.interface text-scaling-factor 1.0 || true
fi

echo "==> XPS profile setup complete."
