-- Dell XPS 13 (DX13260) High-DPI Display Configuration
-- Internal display: LG Display 2560x1600@120Hz with 2x integer scaling
-- External displays: fallback to preferred mode and auto scale

hl.env("GDK_SCALE", "2")
hl.monitor({ output = "eDP-1", mode = "2560x1600@120", position = "0x0", scale = 2 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
