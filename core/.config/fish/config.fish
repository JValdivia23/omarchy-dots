# Source CachyOS fish configuration if present
test -f /usr/share/cachyos-fish-config/cachyos-config.fish && source /usr/share/cachyos-fish-config/cachyos-config.fish

# Custom greeting with fastfetch
function fish_greeting
    if type -q fastfetch-custom
        fastfetch-custom
    else if type -q fastfetch
        fastfetch
    end
end

# Opencode CLI
test -d "$HOME/.opencode/bin" && fish_add_path "$HOME/.opencode/bin"

# Environment variables
set -gx EDITOR nvim
set -gx VISUAL nvim

# Local bin path
fish_add_path "$HOME/.local/bin"

# Starship prompt initialization
if type -q starship
    starship init fish | source
end
