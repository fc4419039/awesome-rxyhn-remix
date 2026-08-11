#!/bin/bash

source "$HOME/.config/awesome/scripts/i18n.sh"

SDDM_BG_DIR="/usr/share/sddm/backgrounds"
SDDM_BG_FILE="$SDDM_BG_DIR/sddm_wallpaper.jpg"
DIR_FONDOS="$HOME/fondos"

[ ! -d "$DIR_FONDOS" ] && notify-send -u critical "$(t common.error)" "$(tsub wp.dir_missing "$DIR_FONDOS")" && exit 1

WALLPAPER=$(find "$DIR_FONDOS" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" -o -name "*.gif" \) \
    | sed "s|$DIR_FONDOS/||" \
    | sort \
    | rofi -dmenu -p "$(t sddm.prompt)" \
        -theme "$HOME/.config/awesome/theme/rofi-menu.rasi" \
        -no-custom)

[ -z "$WALLPAPER" ] && exit 0

FULL_PATH="$DIR_FONDOS/$WALLPAPER"

# Verificar si podemos escribir directamente; si no, usar pkexec (diálogo gráfico)
if touch "$SDDM_BG_DIR/.write_test" 2>/dev/null; then
    rm -f "$SDDM_BG_DIR/.write_test"
    cp -f "$FULL_PATH" "$SDDM_BG_FILE"
else
    pkexec /bin/sh -c "cp -f '$FULL_PATH' '$SDDM_BG_FILE'"
fi

notify-send -i wallpaper "$(t sddm.prompt)" "$(tsub sddm.changed "$WALLPAPER")"
