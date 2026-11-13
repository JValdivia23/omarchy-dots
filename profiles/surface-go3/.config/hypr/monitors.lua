-- Surface Go 3 3:2 display configuration
-- Primary internal screen: 1920x1280@60Hz with 1.6x scaling (1200x800 logical)
-- External displays: fallback to preferred mode and auto scale

hl.env("GDK_SCALE", "2")
hl.monitor({ output = "eDP-1", mode = "1920x1280@60", position = "auto", scale = 1.6 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
