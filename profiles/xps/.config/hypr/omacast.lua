-- Written for XPS profile.
-- Alt+Space reaches the plugin's global shortcut directly, so no process
-- starts per keypress. Omarchy's own menu stays on Super+Space.
o.bind("ALT + SPACE", "omacast launcher", hl.dsp.global("omacast:toggle"))
