#!/bin/bash
MUSIC_DIR="$HOME/Music"
TMPDIR="${XDG_RUNTIME_DIR:-/tmp}"
TMP_COVER="$TMPDIR/ncmpcpp-cover.jpg"

show_cover() {
    TERM_W=$(tput cols)
    TERM_H=$(tput lines)

    FILE=$(mpc --format "%file%" 2>/dev/null | head -1)
    if [ -z "$FILE" ]; then
        clear
        tput setaf 235
        echo "  ╔══════════════════════════╗"
        echo "  ║    Sin reproducción      ║"
        echo "  ╚══════════════════════════╝"
        tput sgr0
        return
    fi

    ARTIST=$(mpc --format "[[%artist%]]" | head -1)
    TITLE=$(mpc --format "[%title%]" | head -1)
    ALBUM=$(mpc --format "[%album%]" | head -1)

    FULL_PATH="$MUSIC_DIR/$FILE"
    clear

    if [ -f "$FULL_PATH" ]; then
        ffmpeg -y -i "$FULL_PATH" -an -vcodec copy "$TMP_COVER" -loglevel quiet 2>/dev/null
        if [ -f "$TMP_COVER" ]; then
            IMG_W=$((TERM_W - 2))
            IMG_H=$((TERM_H - 6))
            kitty +kitten icat --align center --place "${IMG_W}x${IMG_H}@1x1" "$TMP_COVER" 2>/dev/null
        fi
    fi

    tput cup $((TERM_H - 5)) 0
    echo -e "  $(tput setaf 081)●$(tput sgr0) $(tput setaf 255)$TITLE$(tput sgr0)"
    echo -e "  $(tput setaf 081)│$(tput sgr0)  $(tput setaf 081)$ARTIST$(tput sgr0)"
    echo -e "  $(tput setaf 081)└$(tput setaf 081) $(tput setaf 121)$ALBUM$(tput sgr0)"
}

show_cover
while true; do
    mpc idle player >/dev/null 2>&1
    show_cover
done
