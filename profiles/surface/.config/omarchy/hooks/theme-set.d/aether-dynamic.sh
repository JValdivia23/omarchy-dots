#!/bin/bash
# Hook triggered on theme set
THEME_NAME="$1"

if [[ "$THEME_NAME" == "aether" ]]; then
  CURRENT_BG=$(readlink -f "$HOME/.local/state/omarchy/current/background" 2>/dev/null)
  if [[ -f "$CURRENT_BG" ]]; then
    # Ensure aether theme colors match current background
    "$HOME/.local/bin/omarchy-theme-extract-palette" "$CURRENT_BG" > "$HOME/.config/omarchy/themes/aether/colors.toml.tmp" && \
      mv "$HOME/.config/omarchy/themes/aether/colors.toml.tmp" "$HOME/.config/omarchy/themes/aether/colors.toml"
  fi
fi
