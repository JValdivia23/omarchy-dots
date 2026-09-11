# Omarchy Quattro Fish Configuration
# Powered by omarchy-fish with CachyOS-style autosuggestions

if status is-interactive
    # Use default emacs keybindings for standard terminal editing and CachyOS-style autosuggestion navigation
    # (Right Arrow or Ctrl+F accepts suggestion, Alt+Right Arrow or Alt+F accepts one word)
    fish_default_key_bindings

    # Muted gray color for real-time autosuggestions
    set -g fish_color_autosuggestion 555 brblack

    # Ensure local bin is prioritized in PATH
    fish_add_path -m $HOME/.local/bin

    # Default editor and browser fallbacks if not inherited
    if not set -q EDITOR
        set -gx EDITOR "omarchy-launch-editor --inline"
    end
    if not set -q BROWSER
        set -gx BROWSER "omarchy-launch-browser"
    end
end
