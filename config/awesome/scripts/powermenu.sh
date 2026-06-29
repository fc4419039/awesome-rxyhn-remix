#!/bin/sh

options=" Shutdown\n Reboot\n Lock\n Sleep\n Logout\n Hibernate"

choice=$(echo -e "$options" | rofi -dmenu -theme ~/.config/awesome/theme/powermenu.rasi)

case "$choice" in
    " Shutdown") systemctl poweroff ;;
    " Reboot") systemctl reboot ;;
    " Lock") echo 'lock_screen_show()' | awesome-client ;;
    " Sleep") systemctl suspend ;;
    " Logout") echo 'awesome.quit()' | awesome-client ;;
    " Hibernate") systemctl hibernate ;;
esac
