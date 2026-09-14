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

# Ensure Surface kernel is the default in Limine bootloader
if [ -d "/etc/limine-entry-tool.d" ]; then
    if grep -q "linux-surface" /etc/limine-entry-tool.d/zz-surface-kernel.conf 2>/dev/null; then
        echo "--> Limine boot order already prioritizes Surface kernel."
    else
        echo "--> Configuring Limine boot order for Surface kernel..."
        if (( EUID == 0 )); then
            cat > /etc/limine-entry-tool.d/zz-surface-kernel.conf << 'EOF'
# Prioritize Surface kernel as default boot entry in Limine bootloader
BOOT_ORDER="linux-surface*, *, *fallback, Snapshots"
EOF
            command -v limine-update &>/dev/null && limine-update || true
        else
            sudo tee /etc/limine-entry-tool.d/zz-surface-kernel.conf >/dev/null << 'EOF'
# Prioritize Surface kernel as default boot entry in Limine bootloader
BOOT_ORDER="linux-surface*, *, *fallback, Snapshots"
EOF
            command -v limine-update &>/dev/null && sudo limine-update || true
        fi
    fi
fi

echo "==> Surface profile setup complete."
