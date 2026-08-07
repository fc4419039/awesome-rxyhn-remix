#!/bin/bash

source "$HOME/.config/awesome/scripts/i18n.sh"

theme="$HOME/.config/awesome/theme/powermenu.rasi"
confirm_theme="$HOME/.config/awesome/theme/powermenu-confirm.rasi"

now="<span foreground='#06b6d4'>󰔔</span>  $(date '+%A %d %B · %H:%M')"

opt_power=$(t pm.power "Apagar")
opt_reboot=$(t pm.reboot "Reiniciar")
opt_lock=$(t pm.lock "Bloquear")
opt_suspend=$(t pm.suspend "Suspender")
opt_logout=$(t pm.logout "Cerrar sesión")
opt_hibernate=$(t pm.hibernate "Hibernar")

options=$(printf \
"<span foreground='#ef4444'></span>   %s
<span foreground='#f97316'></span>   %s
<span foreground='#06b6d4'></span>   %s
<span foreground='#3b82f6'></span>   %s
<span foreground='#a855f7'></span>   %s
<span foreground='#eab308'></span>   %s" \
"$opt_power" "$opt_reboot" "$opt_lock" "$opt_suspend" "$opt_logout" "$opt_hibernate")

choice=$(echo "$options" | rofi -dmenu -markup-rows -theme "$theme" \
    -theme-str 'mainbox { children: [message, listview]; } message { enabled: true; padding: 18px 16px 0 16px; horizontal-align: 0.5; background-color: transparent; text-color: #e2e8f0; font: "JetBrainsMono Nerd Font 11"; }' \
    -mesg "$now" \
    -selected-row 0)

confirm() {
    local msg="$1" ans
    ans=$(printf "󰄰 %s\n󰄱 %s" "$(t pm.no "No")" "$(t pm.yes "Si")" | rofi -dmenu -theme "$confirm_theme" -mesg "$msg" -selected-row 0)
    [[ "$ans" == "󰄱 $(t pm.yes "Si")" ]]
}

case "$choice" in
    *"$opt_power"*)
        if confirm "$(t pm.confirm_power '¿Apagar el sistema?')"; then
            systemctl poweroff
        fi ;;
    *"$opt_reboot"*)
        if confirm "$(t pm.confirm_reboot '¿Reiniciar el sistema?')"; then
            systemctl reboot
        fi ;;
    *"$opt_lock"*)
        echo 'lock_screen_show()' | awesome-client ;;
    *"$opt_suspend"*)
        systemctl suspend ;;
    *"$opt_logout"*)
        if confirm "$(t pm.confirm_logout '¿Cerrar sesión?')"; then
            echo 'awesome.quit()' | awesome-client
        fi ;;
    *"$opt_hibernate"*)
        if confirm "$(t pm.confirm_hibernate '¿Hibernar el sistema?')"; then
            systemctl hibernate
        fi ;;
esac
