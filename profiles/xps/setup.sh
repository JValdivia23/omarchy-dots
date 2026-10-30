#!/usr/bin/env bash
set -euo pipefail

echo "==> Setting up Dell XPS (xps) profile..."
echo "    Display: 2560x1600@120Hz (scale 1.25, 2048x1280)"
echo "    Input:   Natural scroll + 3/4-finger touchpad gestures enabled"

# Align GTK / GNOME interface text scaling with 1.25x display scale (size 13)
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 13' || true
    gsettings set org.gnome.desktop.interface document-font-name 'Adwaita Sans 13' || true
    gsettings set org.gnome.desktop.interface text-scaling-factor 1.0 || true
fi

# Ensure active session user has read/grab access to internal I2C HID touchscreen (/dev/input/event*)
UDEV_TOUCH_RULE="/etc/udev/rules.d/70-touchscreen-uaccess.rules"
if [ ! -f "$UDEV_TOUCH_RULE" ]; then
    echo "--> Configuring udev uaccess rule for internal touchscreen..."
    RULE_CONTENT='# Grant active local session user access to touchscreen evdev nodes (e.g. SideQuest touch bridges)
SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT_TOUCHSCREEN}=="1", TAG+="uaccess"'
    if (( EUID == 0 )); then
        printf '%s\n' "$RULE_CONTENT" > "$UDEV_TOUCH_RULE"
        udevadm control --reload-rules && udevadm trigger --subsystem-match=input --action=change || true
    elif [ -t 0 ] || sudo -n true 2>/dev/null; then
        printf '%s\n' "$RULE_CONTENT" | sudo tee "$UDEV_TOUCH_RULE" >/dev/null
        sudo udevadm control --reload-rules && sudo udevadm trigger --subsystem-match=input --action=change || true
    elif command -v pkexec &>/dev/null; then
        pkexec bash -c "printf '%s\n' '$RULE_CONTENT' > '$UDEV_TOUCH_RULE' && udevadm control --reload-rules && udevadm trigger --subsystem-match=input --action=change" || true
    fi
fi

echo "==> XPS profile setup complete."
