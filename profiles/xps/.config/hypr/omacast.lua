-- Written for XPS profile.
-- Alt+Space is reserved for Superwhisper dictation; unbind it from Hyprland.
hl.unbind("ALT + SPACE")

-- Rebind Super+Space to oma-cast launcher instead of the default Omarchy root menu.
o.rebind("SUPER + SPACE", "omacast launcher", hl.dsp.global("omacast:toggle"))
