#!/bin/sh

MUSIC_DIR="$HOME/Music"
TMP_ART="/tmp/album_art.jpg"
CACHE_DIR="/tmp/album_art_cache"
LAST_FILE=""
cols=30
lines=28

[ -t 1 ] && cols=$(tput cols) && lines=$(tput lines)
cols=$((cols - 2))
[ "$cols" -lt 10 ] && cols=30
[ "$lines" -lt 10 ] && lines=28

mkdir -p "$CACHE_DIR"

cleanup() { kitty +kitten icat --clear --silent 2>/dev/null; exit 0; }
trap cleanup INT TERM

kitty +kitten icat --clear --silent 2>/dev/null

while true; do
    state=$(mpc status 2>/dev/null | sed -n 's/.*\[\([^]]*\)\].*/\1/p')
    if [ "$state" != "playing" ] && [ "$state" != "paused" ]; then
        kitty +kitten icat --clear --silent 2>/dev/null
        sleep 2; continue
    fi

    file=$(mpc current --format "%file%" 2>/dev/null)
    [ -z "$file" ] && { sleep 1; continue; }

    md5=$(echo "$file" | md5sum | cut -d' ' -f1)
    if [ "$md5" = "$LAST_FILE" ]; then sleep 1; continue; fi
    LAST_FILE="$md5"

    fullpath="$MUSIC_DIR/$file"
    cached="$CACHE_DIR/$(echo "$fullpath" | md5sum | cut -d' ' -f1).jpg"

    if [ ! -f "$cached" ]; then
        ffmpeg -y -i "$fullpath" -an -vcodec copy "$TMP_ART" 2>/dev/null
        if [ -s "$TMP_ART" ]; then
            cp "$TMP_ART" "$cached"
        else
            dir=$(dirname "$fullpath")
            found=""
            for cover in "cover.jpg" "cover.png" "folder.jpg" "folder.png" "Front.jpg" "AlbumArt.jpg"; do
                [ -f "$dir/$cover" ] && { cp "$dir/$cover" "$cached"; found=1; break; }
            done
            [ -z "$found" ] && touch "$cached"
        fi
    fi

    kitty +kitten icat --clear --silent 2>/dev/null

    if [ -s "$cached" ]; then
        kitty +kitten icat --hold --place "${cols}x${lines}@0x0" --align center "$cached" 2>/dev/null
    else
        pad=$(( (lines - 4) / 2 ))
        printf '\n%.0s' $(seq 1 $pad)
        printf '%*s\n' $(( (cols + 10) / 2 )) "♫ No Cover Art"
    fi

    sleep 1
done
