#!/bin/bash
# Genera miniaturas escaladas de ~/fondos en ~/.cache/fondos_thumb
# para que el selector de wallpaper no cargue las imagenes a resolucion completa.
DIR_FONDOS="$HOME/fondos"
THUMB_DIR="$HOME/.cache/fondos_thumb"

[ -d "$DIR_FONDOS" ] || exit 0
mkdir -p "$THUMB_DIR"

find "$DIR_FONDOS" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \) \
    -print0 | while IFS= read -r -d '' img; do
    name=$(basename "$img")
    name="${name%.*}"
    name=$(printf '%s' "$name" | tr -c 'A-Za-z0-9._-' '_')
    thumb="$THUMB_DIR/$name.jpg"
    if [ ! -f "$thumb" ] || [ "$img" -nt "$thumb" ]; then
        convert "$img" -auto-orient -thumbnail 320x180 -strip -quality 82 "$thumb" 2>/dev/null
    fi
done

exit 0
