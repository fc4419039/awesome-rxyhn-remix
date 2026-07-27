#!/bin/bash
# Remove orphaned packages on Arch Linux

orphans=$(pacman -Qdtq 2>/dev/null)

if [ -z "$orphans" ]; then
    notify-send "Limpieza" "No hay paquetes huérfanos" -i edit-clear
    exit 0
fi

count=$(echo "$orphans" | wc -l)
orphan_list=$(echo "$orphans" | head -20)

confirm=$(echo -e "Sí\nNo" | rofi -dmenu -p "Eliminar $count huérfanos?" \
    -theme "$HOME/.config/awesome/theme/rofi-menu.rasi" \
    -no-custom)

if [ "$confirm" = "Sí" ]; then
    kitty --class floating -e bash -c "echo 'Paquetes a eliminar:' && pacman -Qdtq && echo '' && sudo pacman -Rns \$(pacman -Qdtq) && notify-send 'Limpieza completada' '$count paquetes eliminados' -i edit-clear || notify-send 'Error' 'No se pudieron eliminar los paquetes' -i dialog-error; read -p 'Presiona Enter para cerrar...'" &
fi
