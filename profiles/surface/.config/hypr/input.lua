-- Surface Book 3 personal input overrides
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
hl.config({
  input = {
    touchpad = {
      -- Use natural (inverse) scrolling.
      natural_scroll = true,

      -- Use two-finger clicks for right-click instead of lower-right corner.
      clickfinger_behavior = true,

      -- Control the speed of your scrolling.
      scroll_factor = 0.4,

      -- Enable the touchpad while typing.
      disable_while_typing = false,

      -- Disable 3-finger drag so 3-finger swipe gestures respond immediately without conflict.
      drag_3fg = 0,
    },
  },
})

-- Enable touchpad gestures for changing workspaces.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
-- Useful on Surface Book 3 for touchpad + touchscreen workflow.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
