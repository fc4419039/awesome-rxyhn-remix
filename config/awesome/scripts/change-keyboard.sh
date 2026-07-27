#!/bin/bash
# Change keyboard layout

current=$(setxkbmap -query 2>/dev/null | grep "^layout:" | awk '{print $2}')

layouts="latam    Español Latinoamérica
us       Inglés (EE.UU.)
es       Español (España)
uk       Inglés (Reino Unido)
de       Alemán
fr       Francés
it       Italiano
pt       Portugués
br       Portugués (Brasil)
jp       Japonés
kr       Coreano
cn       Chino
ar       Árabe
ru       Ruso"

selected=$(echo "$layouts" | rofi -dmenu -p "Keyboard Layout" \
    -theme "$HOME/.config/awesome/theme/rofi-menu.rasi" \
    -no-custom)

if [ -n "$selected" ]; then
    layout=$(echo "$selected" | awk '{print $1}')

    setxkbmap "$layout" 2>/dev/null
    new_kb=$(setxkbmap -query 2>/dev/null | grep "^layout:" | awk '{print $2}')
    notify-send "Teclado cambiado" "Layout: $new_kb (sesión actual)" -i input-keyboard

    sudo localectl set-x11-keymap "$layout" 2>/dev/null
    if [ $? -eq 0 ]; then
        notify-send "Teclado guardado" "Layout: $layout guardado permanentemente" -i input-keyboard
    else
        notify-send "Error" "No se pudo guardar permanentemente" -i dialog-error
    fi
fi
