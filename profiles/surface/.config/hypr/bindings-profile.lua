-- Surface Book 3 tablet helpers (verified free: SUPER+D, SUPER+R, SUPER+SHIFT+U not bound).
-- Hardware detach button always works; SUPER+D requests latch-open via surface-dtx-daemon.
o.bind("SUPER + D", "Detach Surface base", "sh -c 'surface dtx request 2>/dev/null && omarchy notification send \"Surface detach\" \"Latch opening - pull the tablet.\" || omarchy notification send \"Surface detach\" \"Hold the hardware detach key.\"'")

-- Manual rotate fallback until iio-sensor-proxy auto-rotate is installed. Cycles eDP-1 transform 0 -> 1 -> 3 -> 0.
o.bind("SUPER + R", "Rotate display", "sh -c 'cur=$(hyprctl monitors -j | python3 -c \"import json,sys; m=[x for x in json.load(sys.stdin) if x[\"name\"]==\"eDP-1\"]; print(m[0].get(\"transform\",0) if m else 0)\"); case \"$cur\" in 0) nxt=1;; 1) nxt=3;; *) nxt=0;; esac; hyprctl keyword monitor eDP-1,preferred,auto,2,$nxt >/dev/null && omarchy notification send \"Rotate\" \"eDP-1 transform $nxt\"'")

-- Toggle virtual keyboard input method panel (fcitx5). Touchscreen typing after iptsd + surface kernel.
-- Note: SUPER+SHIFT+O was already Obsidian, so U is used instead.
o.bind("SUPER + SHIFT + U", "On-screen keyboard", "fcitx5-remote -t")
