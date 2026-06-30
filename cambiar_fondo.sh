#!/bin/bash

DIR_FONDOS="$HOME/fondos"
QUEUE_DIR="$HOME/.cache"
QUEUE_FILE="$QUEUE_DIR/fondo_queue.txt"
MANUAL_FILE="$QUEUE_DIR/wallpaper_fijo.txt"

# If user chose a wallpaper manually, keep using it
if [ -f "$MANUAL_FILE" ]; then
    WALLPAPER=$(<"$MANUAL_FILE")
    [ -f "$WALLPAPER" ] && feh --bg-fill "$WALLPAPER" && exit 0
    rm -f "$MANUAL_FILE"
fi

mkdir -p "$QUEUE_DIR"

if [ ! -s "$QUEUE_FILE" ]; then
    mapfile -t files < <(find "$DIR_FONDOS" -type f)
    if [ ${#files[@]} -eq 0 ]; then
        exit 1
    fi
    printf "%s\n" "${files[@]}" | shuf > "$QUEUE_FILE"
fi

WALLPAPER=$(head -n 1 "$QUEUE_FILE")
tail -n +2 "$QUEUE_FILE" > "${QUEUE_FILE}.tmp" && mv "${QUEUE_FILE}.tmp" "$QUEUE_FILE"

feh --bg-fill "$WALLPAPER"
