#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "==> Setting up Surface Go 3 profile..."
echo "    Surface Go 3 uses ELAN9038 I2C-HID touch/stylus, kernel surface_aggregator modules, and CDC-MBIM LTE."

run_root() {
    if (( EUID == 0 )); then
        "$@"
    else
        sudo "$@"
    fi
}

install_root_file() {
    local mode="$1"
    local dest="$2"
    local tmp
    tmp="$(mktemp)"
    cat > "$tmp"
    run_root install -d -m 755 "$(dirname "$dest")"
    if [ ! -f "$dest" ] || ! cmp -s "$tmp" "$dest"; then
        echo "--> Installing $dest..."
        run_root install -m "$mode" "$tmp" "$dest"
        rm -f "$tmp"
        return 0
    fi
    rm -f "$tmp"
    return 1
}

# Deploy Surface Go 3 LTE (045e:09a5) initialization workaround:
# 1. NCM rx_max/tx_max must be 16383 before MBIM OPEN (16384 causes OPEN Failure 0x02).
# 2. If physical SIM (slot 1) and eUICC (slot 2) are both active, power off slot 2 so
#    ModemManager 1.24 does not loop on "SIM identifier has changed" reprobing.
udev_changed=false
systemd_changed=false

install_root_file 755 /usr/local/bin/surface-go3-lte-init <<'EOF' || true
#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-full}"
QMICLI_BIN="$(command -v qmicli || true)"

for usbdev in /sys/bus/usb/devices/*; do
    [ -f "$usbdev/idVendor" ] && [ -f "$usbdev/idProduct" ] || continue
    [ "$(cat "$usbdev/idVendor" 2>/dev/null || true)" = "045e" ] || continue
    [ "$(cat "$usbdev/idProduct" 2>/dev/null || true)" = "09a5" ] || continue

    for ncm_dir in "$usbdev"/*:1.*/net/*/cdc_ncm; do
        [ -d "$ncm_dir" ] || continue
        for attr in rx_max tx_max; do
            [ -w "$ncm_dir/$attr" ] && echo 16383 > "$ncm_dir/$attr" 2>/dev/null || true
        done
    done

    [ "$MODE" = "--net-only" ] && continue
    [ -n "$QMICLI_BIN" ] || continue

    wdm_dev=""
    for wdm in "$usbdev"/*:1.*/usbmisc/cdc-wdm*; do
        [ -e "$wdm" ] || continue
        wdm_dev="/dev/$(basename "$wdm")"
        break
    done
    [ -c "$wdm_dev" ] || continue

    slot_status="$("$QMICLI_BIN" -d "$wdm_dev" --device-open-mbim --uim-get-slot-status 2>/dev/null || true)"
    if printf '%s\n' "$slot_status" | awk '
        /Physical slot 1:/ { s=1; next }
        /Physical slot 2:/ { s=2; next }
        /Physical slot [0-9]+:/ { s=0; next }
        s==1 && /Card status: present/ { s1=1 }
        s==2 && /Card status: present/ { s2=1 }
        s==2 && /Is eUICC: yes/ { e2=1 }
        END { exit !(s1 && s2 && e2) }
    '; then
        "$QMICLI_BIN" -d "$wdm_dev" --device-open-mbim --uim-sim-power-off=2 >/dev/null 2>&1 || true
    fi
done
EOF

if install_root_file 644 /etc/udev/rules.d/78-surface-go3-lte.rules <<'EOF'; then
# Ensure Surface Go 3 LTE (045e:09a5) uses 16383-byte NCM buffers on bind/reset
ACTION=="add|change", SUBSYSTEM=="net", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="09a5", RUN+="/usr/local/bin/surface-go3-lte-init --net-only"
EOF
    udev_changed=true
fi

if install_root_file 644 /etc/systemd/system/ModemManager.service.d/surface-go3-lte.conf <<'EOF'; then
[Service]
ExecStartPre=-/usr/local/bin/surface-go3-lte-init
EOF
    systemd_changed=true
fi

if [ "$udev_changed" = true ]; then
    echo "--> Reloading udev rules..."
    run_root udevadm control --reload-rules || true
fi

if [ "$systemd_changed" = true ]; then
    echo "--> Reloading systemd daemon..."
    run_root systemctl daemon-reload || true
fi

# Enable and start hardware services if available
if [ -f "$SCRIPT_DIR/services.txt" ]; then
    while IFS= read -r service || [ -n "$service" ]; do
        service="${service%%#*}"
        service="$(echo "$service" | xargs)"
        [ -z "$service" ] && continue
        echo "--> Checking service: $service"
        if systemctl is-active --quiet "$service"; then
            if [ "$systemd_changed" = true ]; then
                echo "    Restarting $service to apply drop-in changes..."
                run_root systemctl restart "$service" || true
            else
                echo "    $service is already active."
            fi
        elif systemctl list-unit-files "$service" &>/dev/null; then
            echo "    Enabling and starting $service..."
            run_root systemctl enable --now "$service" || true
        else
            echo "    Notice: $service unit not found on this system. Skipping."
        fi
    done < "$SCRIPT_DIR/services.txt"
fi

echo "==> Surface Go 3 profile setup complete."
