#!/bin/bash

DIR_FONDOS="$HOME/fondos"
QUEUE_DIR="$HOME/.cache"
QUEUE_FILE="$QUEUE_DIR/fondo_queue.txt"

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
