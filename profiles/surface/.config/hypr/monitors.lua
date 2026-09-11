-- Surface Book 3 High-DPI 3:2 display configuration
-- Primary internal screen: 3000x2000@60Hz with 2x scaling
-- External displays: fallback to preferred mode and auto scale

hl.env("GDK_SCALE", "2")
hl.monitor({ output = "eDP-1", mode = "3000x2000@60", position = "auto", scale = 2 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
