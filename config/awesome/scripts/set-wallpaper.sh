#!/bin/bash

source "$HOME/.config/awesome/scripts/i18n.sh"

DIR_FONDOS="$HOME/fondos"
QUEUE_FILE="$HOME/.cache/fondo_queue.txt"
[ ! -d "$DIR_FONDOS" ] && notify-send -u critical "$(t common.error)" "$(tsub wp.dir_missing "$DIR_FONDOS")" && exit 1

WALLPAPER=$(find "$DIR_FONDOS" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" -o -name "*.gif" \) \
    | sed "s|$DIR_FONDOS/||" \
    | sort \
    | rofi -dmenu -p "$(t wp.prompt)" \
        -theme "$HOME/.config/awesome/theme/rofi-menu.rasi" \
        -no-custom)

[ -z "$WALLPAPER" ] && exit 0

feh --bg-fill "$DIR_FONDOS/$WALLPAPER" || exit 1

MANUAL_FILE="$HOME/.cache/wallpaper_fijo.txt"
echo "$DIR_FONDOS/$WALLPAPER" > "$MANUAL_FILE"
notify-send -i wallpaper "$(t wp.prompt)" "$(tsub wp.changed "$WALLPAPER")"
