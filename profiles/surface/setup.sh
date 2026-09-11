#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "==> Setting up Surface profile..."

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
        elif [[ "$service" =~ iptsd ]] && (systemctl list-unit-files "iptsd@.service" &>/dev/null || systemctl is-active --quiet "iptsd*"); then
            echo "    Notice: iptsd is managed dynamically by udev (iptsd@.service)."
        else
            echo "    Notice: $service unit not found on this system. Skipping."
        fi
    done < "$SCRIPT_DIR/services.txt"
fi

echo "==> Surface profile setup complete."
