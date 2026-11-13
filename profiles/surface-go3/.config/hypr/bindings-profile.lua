-- Surface Go 3 tablet helpers (verified free: SUPER+R, SUPER+SHIFT+U not bound).
-- Manual rotate fallback until auto-rotate is enabled. Cycles eDP-1 transform 0 -> 1 -> 3 -> 0.
o.bind("SUPER + R", "Rotate display", "surface-rotate")

-- Toggle virtual keyboard input method panel (fcitx5) for touchscreen typing.
-- Note: SUPER+SHIFT+O was already Obsidian, so U is used instead.
o.bind("SUPER + SHIFT + U", "On-screen keyboard", "fcitx5-remote -t")
