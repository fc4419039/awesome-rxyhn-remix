#!/bin/bash
# Change timezone

current_tz=$(timedatectl show --property=Timezone --value 2>/dev/null)

selected=$(echo "$current_tz" | rofi -dmenu -p "Zona Horaria" \
    -theme "$HOME/.config/awesome/theme/rofi-menu.rasi" \
    -no-custom \
    <<< "$(timedatectl list-timezones 2>/dev/null)")

if [ -n "$selected" ]; then
    sudo timedatectl set-timezone "$selected" 2>/dev/null
    result=$?
    if [ $result -eq 0 ]; then
        new_tz=$(timedatectl show --property=Timezone --value 2>/dev/null)
        notify-send "Hora actualizada" "Zona horaria: $new_tz" -i preferences-system-time
    else
        notify-send "Error" "No se pudo cambiar la zona horaria" -i dialog-error
    fi
fi
