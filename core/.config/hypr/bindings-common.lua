-- Omarchy Quattro Core Universal Keybindings
-- Universal macOS navigation shortcuts, window focus, and system helpers

-- Unbind default window focus from SUPER + Arrows (previously: Focus on left/right/above/below window)
hl.unbind("SUPER + LEFT")
hl.unbind("SUPER + RIGHT")
hl.unbind("SUPER + UP")
hl.unbind("SUPER + DOWN")

-- Move window focus to CTRL + Arrows
o.bind("CTRL + LEFT",  "Focus on left window",  hl.dsp.focus({ direction = "l" }))
o.bind("CTRL + RIGHT", "Focus on right window", hl.dsp.focus({ direction = "r" }))
o.bind("CTRL + UP",    "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.bind("CTRL + DOWN",  "Focus on below window", hl.dsp.focus({ direction = "d" }))

-- macOS-style cursor navigation on SUPER + Arrows (instant, repeating)
o.bind("SUPER + LEFT",  "Line start (Home)", hl.dsp.send_shortcut({ mods = "", key = "Home", window = "activewindow" }), { repeating = true })
o.bind("SUPER + RIGHT", "Line end (End)",    hl.dsp.send_shortcut({ mods = "", key = "End",  window = "activewindow" }), { repeating = true })
o.bind("SUPER + UP",    "Document start",    hl.dsp.send_shortcut({ mods = "CTRL", key = "Home", window = "activewindow" }), { repeating = true })
o.bind("SUPER + DOWN",  "Document end",      hl.dsp.send_shortcut({ mods = "CTRL", key = "End",  window = "activewindow" }), { repeating = true })

-- macOS-style word navigation on ALT + Arrows (Option + Arrows)
o.bind("ALT + LEFT",  "Word left",  hl.dsp.send_shortcut({ mods = "CTRL", key = "Left",  window = "activewindow" }), { repeating = true })
o.bind("ALT + RIGHT", "Word right", hl.dsp.send_shortcut({ mods = "CTRL", key = "Right", window = "activewindow" }), { repeating = true })
o.bind("ALT + SHIFT + LEFT",  "Select word left",  hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "Left",  window = "activewindow" }), { repeating = true })
o.bind("ALT + SHIFT + RIGHT", "Select word right", hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "Right", window = "activewindow" }), { repeating = true })
o.bind("ALT + BackSpace", "Delete word backward",  hl.dsp.send_shortcut({ mods = "CTRL", key = "BackSpace", window = "activewindow" }), { repeating = true })

-- macOS-style Undo & Redo (Cmd+Z / Cmd+Shift+Z)
o.bind("SUPER + Z", "Undo", hl.dsp.send_shortcut({ mods = "CTRL", key = "z", window = "activewindow" }), { repeating = true })
o.bind("SUPER + SHIFT + Z", "Redo", hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "z", window = "activewindow" }), { repeating = true })

-- Move Window Transparency to SUPER + ALT + BACKSPACE (previously: SUPER + BACKSPACE)
hl.unbind("SUPER + BACKSPACE")
o.bind("SUPER + ALT + BACKSPACE", "Toggle window transparency", "omarchy-hyprland-window-transparency-toggle")

-- macOS-style Line Deletion (Cmd + BackSpace)
-- In terminals: CTRL+U. In GUI applications: SHIFT+Home followed by BackSpace.
local function active_is_terminal()
  local win = hl.get_active_window()
  if not win then return false end
  for _, tag in ipairs(win.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then return true end
  end
  local class = (win.class or ""):lower()
  if class:match("kitty") or class:match("alacritty") or class:match("foot") or class:match("ghostty") or class:match("terminal") then
    return true
  end
  return false
end

o.bind("SUPER + BackSpace", "Delete line backward", function()
  if active_is_terminal() then
    hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = "u", window = "activewindow" }))
  else
    hl.dispatch(hl.dsp.send_shortcut({ mods = "SHIFT", key = "Home", window = "activewindow" }))
    hl.dispatch(hl.dsp.send_shortcut({ mods = "", key = "BackSpace", window = "activewindow" }))
  end
end, { repeating = true })

-- Toggle Alt/Super key swap (Mac vs PC physical layout)
-- Previously bound to: Tmux keybindings
hl.unbind("SUPER + ALT + K")
local home = os.getenv("HOME")
local altwin_cmd = home and (home .. "/.local/bin/hypr-toggle-altwin") or "hypr-toggle-altwin"
o.bind("SUPER + ALT + K", "Toggle Super/Alt layout swap", altwin_cmd)

-- Launch or focus YouTube via Brave Origin
-- Previously bound to: omarchy-launch-webapp (Chromium)
hl.unbind("SUPER + SHIFT + Y")
o.bind("SUPER + SHIFT + Y", "YouTube", {
  focus = "YouTube",
  launch = "brave-origin --new-window --ozone-platform=wayland --app=https://youtube.com --name=YouTube --class=YouTube"
})

-- Background Switcher (Native Omarchy Quickshell Carousel)
o.bind("ALT + SPACE", "Background switcher", "background=$(omarchy-theme-bg-switcher); [[ -n $background ]] && omarchy-theme-bg-set \"$background\"")



