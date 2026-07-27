#!/bin/bash

SDDM_THEME_DIR="/usr/share/sddm/themes/sugar-candy"
DIR_FONDOS="$HOME/fondos"
SDDM_CONF="$SDDM_THEME_DIR/theme.conf"

[ ! -d "$DIR_FONDOS" ] && notify-send -u critical "Error" "No existe $DIR_FONDOS" && exit 1

WALLPAPER=$(find "$DIR_FONDOS" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" -o -name "*.gif" \) \
    | sed "s|$DIR_FONDOS/||" \
    | sort \
    | rofi -dmenu -p "Fondo SDDM" \
        -theme "$HOME/.config/awesome/theme/rofi-menu.rasi" \
        -no-custom)

[ -z "$WALLPAPER" ] && exit 0

FULL_PATH="$DIR_FONDOS/$WALLPAPER"
sudo cp "$FULL_PATH" "$SDDM_THEME_DIR/" && sudo sed -i "s/^Background=.*/Background=\"$WALLPAPER\"/" "$SDDM_CONF"

notify-send -i wallpaper "Fondo SDDM" "Cambiado a $WALLPAPER (requiere reinicio)"
