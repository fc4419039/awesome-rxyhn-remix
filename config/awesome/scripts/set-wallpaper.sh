#!/bin/bash

DIR_FONDOS="$HOME/fondos"
QUEUE_FILE="$HOME/.cache/fondo_queue.txt"
[ ! -d "$DIR_FONDOS" ] && notify-send -u critical "Error" "No existe $DIR_FONDOS" && exit 1

WALLPAPER=$(yad --file --add-preview --large-preview --image-filter \
    --title="Elegir fondo de pantalla" \
    --filename="$DIR_FONDOS/" \
    --width=800 --height=600)

[ -z "$WALLPAPER" ] && exit 0

feh --bg-fill "$WALLPAPER" || exit 1

MANUAL_FILE="$HOME/.cache/wallpaper_fijo.txt"
echo "$WALLPAPER" > "$MANUAL_FILE"
notify-send -i wallpaper "Fondo de pantalla" "Cambiado a $(basename "$WALLPAPER")"
