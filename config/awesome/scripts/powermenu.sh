#!/bin/bash

theme="$HOME/.config/awesome/theme/powermenu.rasi"
confirm_theme="$HOME/.config/awesome/theme/powermenu-confirm.rasi"

options=$(printf \
"<span foreground='#ef4444'></span>   Apagar
<span foreground='#f97316'></span>   Reiniciar
<span foreground='#06b6d4'></span>   Bloquear
<span foreground='#3b82f6'></span>   Suspender
<span foreground='#a855f7'></span>   Cerrar sesión
<span foreground='#eab308'></span>   Hibernar")

choice=$(echo "$options" | rofi -dmenu -markup-rows -theme "$theme" -selected-row 4)

confirm() {
    local msg="$1"
    local ans=$(printf "󰄰 No\n󰄱 Si" | rofi -dmenu -theme "$confirm_theme" -mesg "$msg" -selected-row 0)
    [[ "$ans" == "󰄱 Si" ]]
}

case "$choice" in
    *"Apagar"*)
        if confirm "¿Apagar el sistema?"; then
            systemctl poweroff
        fi ;;
    *"Reiniciar"*)
        if confirm "¿Reiniciar el sistema?"; then
            systemctl reboot
        fi ;;
    *"Bloquear"*)
        echo 'lock_screen_show()' | awesome-client ;;
    *"Suspender"*)
        systemctl suspend ;;
    *"Cerrar sesión"*)
        if confirm "¿Cerrar sesión?"; then
            echo 'awesome.quit()' | awesome-client
        fi ;;
    *"Hibernar"*)
        if confirm "¿Hibernar el sistema?"; then
            systemctl hibernate
        fi ;;
esac
