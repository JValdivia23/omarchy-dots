-- Omarchy Quattro Hyprland Master Configuration
-- Universal entrypoint deployed across all machine profiles

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Core cursor & desktop behaviors.
hl.config({
  cursor = {
    inactive_timeout = 3, -- Hide cursor after 3 seconds of inactivity (e.g. watching video)
  },
})

-- Load core personal keybinding overrides.
require("hypr.bindings-common")

-- Dynamically and safely load machine profile overrides if present.
pcall(require, "hypr.monitors")
pcall(require, "hypr.input")
pcall(require, "hypr.bindings-profile")
pcall(require, "hypr.bindings")
pcall(require, "hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")



