#!/bin/bash

theme="$HOME/.config/awesome/theme/powermenu.rasi"
confirm_theme="$HOME/.config/awesome/theme/powermenu-confirm.rasi"

options=$(printf "\n\n\n\n\n")

choice=$(echo "$options" | rofi -dmenu -theme "$theme" -selected-row 4)

confirm() {
    local msg="$1"
    local ans=$(printf "󰄰 No\n󰄱 Si" | rofi -dmenu -theme "$confirm_theme" -mesg "$msg" -selected-row 0)
    [[ "$ans" == "󰄱 Si" ]]
}

case "$choice" in
    "")
        if confirm "¿Apagar el sistema?"; then
            systemctl poweroff
        fi ;;
    "")
        if confirm "¿Reiniciar el sistema?"; then
            systemctl reboot
        fi ;;
    "")
        echo 'lock_screen_show()' | awesome-client ;;
    "")
        systemctl suspend ;;
    "")
        if confirm "¿Cerrar sesión?"; then
            echo 'awesome.quit()' | awesome-client
        fi ;;
    "")
        if confirm "¿Hibernar el sistema?"; then
            systemctl hibernate
        fi ;;
esac
