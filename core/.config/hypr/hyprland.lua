-- Omarchy Quattro Hyprland Master Configuration
-- Universal entrypoint deployed across all machine profiles

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Core cursor, desktop, and input behaviors.
hl.config({
  cursor = {
    inactive_timeout = 3, -- Hide cursor after 3 seconds of inactivity (e.g. watching video)
  },
  input = {
    repeat_rate = 0, -- Disable keyboard auto-repeat when holding keys
  },
})

-- Inhibit idle (screensaver & sleep) when any window is fullscreen (e.g. YouTube, Netflix, media players, games)
o.window(".*", { idle_inhibit = "fullscreen" })

-- Float zbar barcode/QR reader window
o.window("^zbar$", { float = true, center = true })

-- Load core personal keybinding overrides.
require("hypr.bindings-common")

-- Dynamically and safely load machine profile overrides if present.
pcall(require, "hypr.monitors")
pcall(require, "hypr.input")
pcall(require, "hypr.bindings-profile")
pcall(require, "hypr.bindings")
pcall(require, "hypr.omacast")
pcall(require, "hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")



