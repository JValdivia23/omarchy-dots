-- Standard Desktop Workstation Input Configuration
-- Precision mouse controls, standard scroll wheel behavior, no touchpad gestures

hl.config({
  input = {
    -- Mouse settings
    follow_mouse = 1,
    sensitivity = 0.0,
    accel_profile = "flat",

    -- Standard mouse wheel scrolling (not inverted)
    natural_scroll = false,

    -- Enable numlock by default on full desktop keyboards
    numlock_by_default = true,
  },
})
