-- Desktop Multi-Monitor Configuration Template
-- To view active outputs, connectors, and supported modes, run:
--   hyprctl monitors all

-- Global fallback for any newly connected display:
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

--------------------------------------------------------------------------------
-- Dual Monitor Template Example:
-- DP-1: Primary 27" 1440p 144Hz landscape centered at (0, 0)
-- DP-2: Secondary 24" 1080p 60Hz landscape to the right at (2560, 0)
--------------------------------------------------------------------------------
-- hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0", scale = 1 })
-- hl.monitor({ output = "DP-2", mode = "1920x1080@60",  position = "2560x0", scale = 1 })

--------------------------------------------------------------------------------
-- Triple Monitor Template Example:
-- HDMI-A-1: Left vertical/portrait coding monitor (transform 1 = 90 deg clockwise)
-- DP-1:     Center primary 1440p high-refresh gaming/main monitor
-- DP-2:     Right horizontal secondary monitor
--------------------------------------------------------------------------------
-- hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60",  position = "-1080x-300", scale = 1, transform = 1 })
-- hl.monitor({ output = "DP-1",     mode = "2560x1440@144", position = "0x0",        scale = 1 })
-- hl.monitor({ output = "DP-2",     mode = "2560x1440@144", position = "2560x0",     scale = 1 })

--------------------------------------------------------------------------------
-- Workspace assignments across monitors (optional):
--------------------------------------------------------------------------------
-- hl.workspace({ name = "1", monitor = "DP-1", default = true })
-- hl.workspace({ name = "2", monitor = "DP-1" })
-- hl.workspace({ name = "3", monitor = "DP-2", default = true })
-- hl.workspace({ name = "4", monitor = "HDMI-A-1", default = true })
