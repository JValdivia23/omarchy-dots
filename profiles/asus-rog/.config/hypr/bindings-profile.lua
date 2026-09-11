-- ASUS ROG Zephyrus G14 hardware profile keybindings

-- ROG fan profile toggle on dedicated ROG key (XF86Launch4)
o.bind("XF86Launch4", "Cycle ROG fan profile", "asusctl profile -n", { locked = true })

-- Dedicated ROG control / AniMatrix launch key (XF86Launch1) and desktop shortcut (SUPER + SHIFT + M)
o.bind("XF86Launch1", "AniMatrix Studio", "gtk-launch AniMatrix.desktop || rog-control-center", { locked = true })
o.bind("SUPER + SHIFT + M", "AniMatrix Studio", "gtk-launch AniMatrix.desktop || rog-control-center")
