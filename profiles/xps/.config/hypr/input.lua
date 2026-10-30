-- Dell XPS 13 (DX13260) Touchpad & Input Configuration
-- Touchpad: gxtp7863:00-27c6:0d4c-touchpad
-- Touchscreen: lxst2024:00-1fd2:5010

hl.config({
  input = {
    touchpad = {
      -- Natural (inverse) scrolling
      natural_scroll = true,

      -- Tap to click and two-finger right-click
      tap_to_click = true,
      clickfinger_behavior = true,
      middle_button_emulation = true,

      -- Smooth touchpad scroll speed
      scroll_factor = 0.4,

      -- Keep touchpad responsive while typing
      disable_while_typing = false,

      -- Disable 3-finger drag so 3-finger swipe gestures respond immediately
      drag_3fg = 0,
    },
  },
})

-- Multi-finger Touchpad Gestures (aligned with hyprland-dots laptop profile)
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up",         action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "down",       action = "close" })
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
