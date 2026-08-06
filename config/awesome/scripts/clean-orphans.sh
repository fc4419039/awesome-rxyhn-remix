#!/bin/bash
# Remove orphaned packages on Arch Linux

source "$HOME/.config/awesome/scripts/i18n.sh"

orphans=$(pacman -Qdtq 2>/dev/null)

if [ -z "$orphans" ]; then
    notify-send "$(t co.title)" "$(t co.none)" -i edit-clear
    exit 0
fi

count=$(echo "$orphans" | wc -l)
orphan_list=$(echo "$orphans" | head -20)

confirm=$(printf '%s\n%s' "$(t co.yes)" "$(t co.no)" | rofi -dmenu -p "$(tsub co.confirm "$count")" \
    -theme "$HOME/.config/awesome/theme/rofi-menu.rasi" \
    -no-custom)

if [ "$confirm" = "$(t co.yes)" ]; then
    kitty --class floating -e bash -c "echo '$(t co.list_title)' && pacman -Qdtq && echo '' && sudo pacman -Rns \$(pacman -Qdtq) && notify-send '$(t co.done_title)' '$(tsub co.removed "$count")' -i edit-clear || notify-send '$(t common.error)' '$(t co.error_failed)' -i dialog-error; read -p '$(t co.press_enter)'" &
fi
