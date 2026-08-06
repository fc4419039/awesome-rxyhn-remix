#!/bin/bash
# Clipboard manager using cliphist + rofi

source "$HOME/.config/awesome/scripts/i18n.sh"

# Capturar contenido actual del portapapeles en cliphist antes de listar
xclip -selection clipboard -o 2>/dev/null | cliphist store 2>/dev/null

selected=$(cliphist list | rofi -dmenu -theme ~/.config/awesome/theme/clipboard.rasi -p "$(t cb.prompt)")

if [ -n "$selected" ]; then
    echo "$selected" | cliphist decode | xclip -selection clipboard
fi
