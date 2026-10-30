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

-- Unbind default window swap from SUPER + SHIFT + Arrows so macOS text selection works
hl.unbind("SUPER + SHIFT + LEFT")
hl.unbind("SUPER + SHIFT + RIGHT")
hl.unbind("SUPER + SHIFT + UP")
hl.unbind("SUPER + SHIFT + DOWN")

-- Move window swap to CTRL + SHIFT + Arrows (matching CTRL + Arrows for window focus)
o.bind("CTRL + SHIFT + LEFT",  "Swap window to the left",  hl.dsp.window.swap({ direction = "l" }))
o.bind("CTRL + SHIFT + RIGHT", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))
o.bind("CTRL + SHIFT + UP",    "Swap window up",           hl.dsp.window.swap({ direction = "u" }))
o.bind("CTRL + SHIFT + DOWN",  "Swap window down",         hl.dsp.window.swap({ direction = "d" }))

-- macOS-style cursor navigation on SUPER + Arrows (instant, repeating)
o.bind("SUPER + LEFT",  "Line start (Home)", hl.dsp.send_shortcut({ mods = "", key = "Home", window = "activewindow" }), { repeating = true })
o.bind("SUPER + RIGHT", "Line end (End)",    hl.dsp.send_shortcut({ mods = "", key = "End",  window = "activewindow" }), { repeating = true })
o.bind("SUPER + UP",    "Document start",    hl.dsp.send_shortcut({ mods = "CTRL", key = "Home", window = "activewindow" }), { repeating = true })
o.bind("SUPER + DOWN",  "Document end",      hl.dsp.send_shortcut({ mods = "CTRL", key = "End",  window = "activewindow" }), { repeating = true })

-- macOS-style text selection on SUPER + SHIFT + Arrows (instant, repeating)
o.bind("SUPER + SHIFT + LEFT",  "Select to line start",     hl.dsp.send_shortcut({ mods = "SHIFT", key = "Home", window = "activewindow" }), { repeating = true })
o.bind("SUPER + SHIFT + RIGHT", "Select to line end",       hl.dsp.send_shortcut({ mods = "SHIFT", key = "End",  window = "activewindow" }), { repeating = true })
o.bind("SUPER + SHIFT + UP",    "Select to document start", hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "Home", window = "activewindow" }), { repeating = true })
o.bind("SUPER + SHIFT + DOWN",  "Select to document end",   hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "End",  window = "activewindow" }), { repeating = true })

-- macOS-style word navigation on ALT + Arrows (Option + Arrows)
o.bind("ALT + LEFT",  "Word left",  hl.dsp.send_shortcut({ mods = "CTRL", key = "Left",  window = "activewindow" }), { repeating = true })
o.bind("ALT + RIGHT", "Word right", hl.dsp.send_shortcut({ mods = "CTRL", key = "Right", window = "activewindow" }), { repeating = true })
o.bind("ALT + SHIFT + LEFT",  "Select word left",  hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "Left",  window = "activewindow" }), { repeating = true })
o.bind("ALT + SHIFT + RIGHT", "Select word right", hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "Right", window = "activewindow" }), { repeating = true })
o.bind("ALT + BackSpace", "Delete word backward",  hl.dsp.send_shortcut({ mods = "CTRL", key = "BackSpace", window = "activewindow" }), { repeating = true })
o.bind("ALT + Delete",    "Delete word forward",   hl.dsp.send_shortcut({ mods = "CTRL", key = "Delete",    window = "activewindow" }), { repeating = true })

-- macOS-style Undo & Redo (Cmd+Z / Cmd+Shift+Z)
o.bind("SUPER + Z", "Undo", hl.dsp.send_shortcut({ mods = "CTRL", key = "z", window = "activewindow" }), { repeating = true })
o.bind("SUPER + SHIFT + Z", "Redo", hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "z", window = "activewindow" }), { repeating = true })

-- Move Window Transparency to SUPER + ALT + BACKSPACE (previously: SUPER + BACKSPACE)
hl.unbind("SUPER + BACKSPACE")
o.bind("SUPER + ALT + BACKSPACE", "Toggle window transparency", "omarchy-hyprland-window-transparency-toggle")

-- macOS-style Line Deletion (Cmd + BackSpace / Cmd + Delete)
-- In terminals: CTRL+U (backward), CTRL+K (forward). In GUI applications: SHIFT+Home/End followed by BackSpace.
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

o.bind("SUPER + Delete", "Delete line forward", function()
  if active_is_terminal() then
    hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = "k", window = "activewindow" }))
  else
    hl.dispatch(hl.dsp.send_shortcut({ mods = "SHIFT", key = "End", window = "activewindow" }))
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

-- Interactive Window Resize Mode (Keyboard & Touchscreen / Mouse)
-- Enter with SUPER + R. Use Arrow keys / HJKL or mouse drag. Exit with Escape, Return, or SUPER + R.
local function resize_dir(dx, dy, ratio)
  local win = hl.get_active_window()
  if win and win.floating then
    hl.dispatch(hl.dsp.exec_raw("resizeactive", dx .. " " .. dy))
  else
    hl.dispatch(hl.dsp.layout("splitratio " .. ratio))
  end
end

local function exit_resize()
  hl.dispatch(hl.dsp.submap("reset"))
end

hl.define_submap("resize", function()
  o.bind("mouse:272", "Resize window with mouse drag", hl.dsp.window.resize(), { mouse = true })
  o.bind("mouse:273", "Resize window with right-click drag", hl.dsp.window.resize(), { mouse = true })
  o.bind("SUPER + mouse:272", "Resize window with mouse drag", hl.dsp.window.resize(), { mouse = true })
  o.bind("SUPER + mouse:273", "Resize window with right-click drag", hl.dsp.window.resize(), { mouse = true })

  local function do_right() resize_dir(40, 0, "+0.05") end
  local function do_left()  resize_dir(-40, 0, "-0.05") end
  local function do_up()    resize_dir(0, -40, "-0.05") end
  local function do_down()  resize_dir(0, 40, "+0.05") end

  o.bind("RIGHT", "Expand width right", do_right, { repeating = true })
  o.bind("LEFT",  "Shrink width left",  do_left,  { repeating = true })
  o.bind("UP",    "Shrink height up",   do_up,    { repeating = true })
  o.bind("DOWN",  "Expand height down", do_down,  { repeating = true })

  o.bind("SUPER + RIGHT", "Expand width right", do_right, { repeating = true })
  o.bind("SUPER + LEFT",  "Shrink width left",  do_left,  { repeating = true })
  o.bind("SUPER + UP",    "Shrink height up",   do_up,    { repeating = true })
  o.bind("SUPER + DOWN",  "Expand height down", do_down,  { repeating = true })

  o.bind("l", "Expand width right", do_right, { repeating = true })
  o.bind("h", "Shrink width left",  do_left,  { repeating = true })
  o.bind("k", "Shrink height up",   do_up,    { repeating = true })
  o.bind("j", "Expand height down", do_down,  { repeating = true })

  o.bind("equal", "Reset split to 50/50", function()
    hl.dispatch(hl.dsp.layout("splitratio 1.0 exact"))
  end)

  o.bind("ESCAPE", "Exit resize mode", exit_resize)
  o.bind("RETURN", "Exit resize mode", exit_resize)
  o.bind("r",      "Exit resize mode", exit_resize)
  o.bind("SUPER + R", "Exit resize mode", exit_resize)
  o.bind("SUPER + ESCAPE", "Exit resize mode", exit_resize)
end)

o.bind("SUPER + R", "Enter window resize mode", function()
  hl.dispatch(hl.dsp.submap("resize"))
  hl.dispatch(hl.dsp.exec_cmd("notify-send -t 2500 -a 'Hyprland' 'Resize Mode' 'Active: Use Arrows/HJKL or drag (Esc or Super+R to exit)'"))
end)




