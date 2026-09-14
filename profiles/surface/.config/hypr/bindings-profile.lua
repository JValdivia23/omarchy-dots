-- Surface Book 3 tablet helpers (verified free: SUPER+D, SUPER+R, SUPER+SHIFT+U not bound).
-- Hardware detach button always works; SUPER+D requests latch-open via surface-dtx-daemon.
o.bind("SUPER + D", "Detach Surface base", "surface-detach")

-- Manual rotate fallback until iio-sensor-proxy auto-rotate is installed. Cycles eDP-1 transform 0 -> 1 -> 3 -> 0.
o.bind("SUPER + R", "Rotate display", "surface-rotate")

-- Toggle virtual keyboard input method panel (fcitx5). Touchscreen typing after iptsd + surface kernel.
-- Note: SUPER+SHIFT+O was already Obsidian, so U is used instead.
o.bind("SUPER + SHIFT + U", "On-screen keyboard", "fcitx5-remote -t")

