-- Omarchy Quattro Hyprland Look & Feel
-- Universal layout, decorations, and animations across all machines

hl.config({
  general = {
    gaps_in = 3,
    gaps_out = 8,
    border_size = 2,
    resize_on_border = true,
    extend_border_grab_area = 10,
    layout = "dwindle",
  },

  decoration = {
    rounding = 8,
    active_opacity = 0.98,
    inactive_opacity = 0.90,
    fullscreen_opacity = 1.0,
    dim_inactive = false,
    dim_special = 0.3,

    blur = {
      enabled = true,
      size = 5,
      passes = 3,
      special = true,
    },
  },
})

-- Smooth workspace slide animations
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "quick", style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 2, bezier = "quick", style = "slide top" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2, bezier = "quick", style = "slide bottom" })
