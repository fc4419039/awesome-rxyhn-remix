#!/bin/bash

SDDM_THEME_DIR="/usr/share/sddm/themes/sugar-candy"
DIR_FONDOS="$HOME/fondos"
SDDM_CONF="$SDDM_THEME_DIR/theme.conf"

[ ! -d "$DIR_FONDOS" ] && notify-send -u critical "Error" "No existe $DIR_FONDOS" && exit 1

WALLPAPER=$(yad --file --add-preview --large-preview \
    --file-filter="Imágenes | *.png *.jpg *.jpeg *.gif *.bmp *.tiff *.tif *.webp *.svg *.xpm" \
    --file-filter="Todos los archivos | *" \
    --title="Elegir fondo para SDDM" \
    --filename="$DIR_FONDOS/" \
    --width=800 --height=600)

[ -z "$WALLPAPER" ] && exit 0

BASENAME=$(basename "$WALLPAPER")
pkexec bash -c "cp '$WALLPAPER' '$SDDM_THEME_DIR/' && sed -i 's/^Background=.*/Background=\"$BASENAME\"/' '$SDDM_CONF'"

notify-send -i wallpaper "Fondo SDDM" "Cambiado a $BASENAME (requiere reinicio)"
