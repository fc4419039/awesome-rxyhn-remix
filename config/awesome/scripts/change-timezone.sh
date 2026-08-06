#!/bin/bash
# Change timezone

source "$HOME/.config/awesome/scripts/i18n.sh"

current_tz=$(timedatectl show --property=Timezone --value 2>/dev/null)

selected=$(echo "$current_tz" | rofi -dmenu -p "$(t tz.prompt)" \
    -theme "$HOME/.config/awesome/theme/rofi-menu.rasi" \
    -no-custom \
    <<< "$(timedatectl list-timezones 2>/dev/null)")

if [ -n "$selected" ]; then
    sudo timedatectl set-timezone "$selected" 2>/dev/null
    result=$?
    if [ $result -eq 0 ]; then
        new_tz=$(timedatectl show --property=Timezone --value 2>/dev/null)
        notify-send "$(t tz.updated_title)" "$(tsub tz.updated_body "$new_tz")" -i preferences-system-time
    else
        notify-send "$(t common.error)" "$(t tz.error_failed)" -i dialog-error
    fi
fi
