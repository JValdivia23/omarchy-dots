#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

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

# Ensure Omastorm weather radar plugin is installed and enabled for XPS profile
if [ ! -d "$HOME/.config/omarchy/plugins/com.omastorm.radar" ]; then
    echo "--> Installing Omastorm radar plugin for XPS profile..."
    omarchy plugin add https://github.com/wesleygrimes/omastorm.git --enable --yes || true
fi

# Ensure oma-cast launcher plugin is installed and enabled for XPS profile
if [ ! -d "$HOME/.config/omarchy/plugins/typecraft.omacast" ]; then
    echo "--> Installing oma-cast launcher plugin for XPS profile..."
    omarchy plugin add https://github.com/typecraft-dev/oma-cast --enable --yes || true
    if [ -x "$HOME/.config/omarchy/plugins/typecraft.omacast/bin/omacast" ]; then
        "$HOME/.config/omarchy/plugins/typecraft.omacast/bin/omacast" install || true
    fi
fi

# Ensure ~/.config/hypr/omacast.lua symlink exists for XPS profile
if [ ! -e "$HOME/.config/hypr/omacast.lua" ] && [ -f "$DOTFILES_DIR/profiles/xps/.config/hypr/omacast.lua" ]; then
    ln -sfn "$DOTFILES_DIR/profiles/xps/.config/hypr/omacast.lua" "$HOME/.config/hypr/omacast.lua"
fi

# Ensure keyd is installed and configured for Dell XPS 13 Copilot dual-role modifier (Super on hold, Menu on tap)
KEYD_CONF="/etc/keyd/default.conf"
LIBINPUT_QUIRKS="/etc/libinput/local-overrides.quirks"
if [ ! -f "$KEYD_CONF" ] || ! grep -q "leftmeta+leftshift+f23" "$KEYD_CONF" 2>/dev/null; then
    echo "--> Configuring keyd for XPS Copilot key (dual-role Super/Menu)..."
    KEYD_CONTENT='[ids]
*

[main]
leftmeta+leftshift+f23 = overload(meta, compose)
'
    QUIRKS_CONTENT='[Serial Keyboards]
MatchUdevType=keyboard
MatchName=keyd virtual keyboard
AttrKeyboardIntegration=internal
'
    SETUP_CMDS="
        pacman -S --needed --noconfirm keyd && \
        mkdir -p /etc/keyd /etc/libinput && \
        printf '%s\n' '$KEYD_CONTENT' > '$KEYD_CONF' && \
        printf '%s\n' '$QUIRKS_CONTENT' > '$LIBINPUT_QUIRKS' && \
        udevadm control --reload-rules && udevadm trigger && \
        systemctl enable --now keyd
    "
    if (( EUID == 0 )); then
        eval "$SETUP_CMDS" || true
    elif sudo -n true 2>/dev/null; then
        sudo bash -c "$SETUP_CMDS" || true
    elif command -v pkexec &>/dev/null; then
        pkexec bash -c "$SETUP_CMDS" || true
    elif [ -t 0 ]; then
        sudo bash -c "$SETUP_CMDS" || true
    fi
fi

echo "==> XPS profile setup complete."
