#!/bin/bash
MUSIC_DIR="$HOME/Music"
TMPDIR="${XDG_RUNTIME_DIR:-/tmp}"
TMP_COVER="$TMPDIR/ncmpcpp-cover.jpg"

FILE=$(mpc --format "%file%" | head -1)
if [ -z "$FILE" ]; then
    echo "No hay canción reproduciéndose"
    exit 1
fi

FULL_PATH="$MUSIC_DIR/$FILE"
if [ ! -f "$FULL_PATH" ]; then
    echo "Archivo no encontrado: $FULL_PATH"
    exit 1
fi

ffmpeg -y -i "$FULL_PATH" -an -vcodec copy "$TMP_COVER" -loglevel quiet 2>/dev/null

if [ -f "$TMP_COVER" ]; then
    clear
    art=$(mpc --format "[[%artist%]]" | head -1)
    tit=$(mpc --format "[%title%]" | head -1)
    alb=$(mpc --format "[%album%]" | head -1)
    TERM_W=$(tput cols)
    TERM_H=$(tput lines)
    IMG_W=$((TERM_W - 2))
    IMG_H=$((TERM_H - 6))
    kitty +kitten icat --align center --place "${IMG_W}x${IMG_H}@1x1" "$TMP_COVER"
    tput cup $((TERM_H - 3)) 0
    echo -e "  $(tput setaf 081)●$(tput sgr0) $(tput setaf 255)$tit$(tput sgr0)"
    echo -e "  $(tput setaf 081)│$(tput sgr0)  $(tput setaf 081)$art$(tput sgr0)"
    read -p "  $(tput setaf 081)└$(tput sgr0) Presiona Enter para volver..."
else
    echo "No se encontró carátula"
fi
