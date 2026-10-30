-- Dell XPS 13 (DX13260) High-DPI Display Configuration
-- Internal display: LG Display 2560x1600@120Hz with 1.25x fractional scaling (2048x1280 viewport)
-- External displays: fallback to preferred mode and auto scale

hl.monitor({ output = "eDP-1", mode = "2560x1600@120", position = "0x0", scale = 1.25 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
