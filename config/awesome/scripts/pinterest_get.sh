#!/bin/bash

theme="$HOME/.config/awesome/theme/rofi.rasi"
dir_fondos="$HOME/fondos"
mkdir -p "$dir_fondos"

url=$(xclip -o -selection clipboard 2>/dev/null)

if [ -z "$url" ]; then
    notify-send -u critical "Error" "No hay URL en el portapapeles"
    exit 1
fi

if ! echo "$url" | grep -qiE '^https?://'; then
    notify-send -u critical "Error" "El portapapeles no contiene una URL válida"
    exit 1
fi

ext=$(echo "$url" | sed 's/.*\(\.[a-zA-Z0-9]*\).*/\1/' | head -1)
[ -z "$ext" ] || [ "${#ext}" -gt 5 ] && ext=".jpg"

file="$dir_fondos/fondo_$(date +%s)$ext"

if ! curl -sLo "$file" "$url"; then
    notify-send -u critical "Error" "No se pudo descargar la imagen"
    rm -f "$file"
    exit 1
fi

if [ ! -s "$file" ]; then
    notify-send -u critical "Error" "La imagen descargada está vacía"
    rm -f "$file"
    exit 1
fi

feh --scale-down --geometry 1200x800 "$file" &
feh_pid=$!

aplicar=$(printf "si\nno" | rofi -dmenu -theme "$theme" -p "Aplicar fondo?")
kill "$feh_pid" 2>/dev/null

if echo "$aplicar" | grep -qi "si"; then
    feh --bg-fill "$file"
    notify-send "Fondo cambiado" "$(basename "$file")"
else
    rm -f "$file"
    notify-send "Descartado"
fi
