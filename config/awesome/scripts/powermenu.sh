#!/bin/bash

theme="$HOME/.config/awesome/theme/powermenu.rasi"

options=$(printf " Shutdown\n Reboot\n Lock\n Sleep\n Logout\n Hibernate")

choice=$(echo "$options" | rofi -dmenu -theme "$theme")

case "$choice" in
    " Shutdown") systemctl poweroff ;;
    " Reboot")   systemctl reboot ;;
    " Lock")     echo 'lock_screen_show()' | awesome-client ;;
    " Sleep")    systemctl suspend ;;
    " Logout")   echo 'awesome.quit()' | awesome-client ;;
    " Hibernate") systemctl hibernate ;;
esac
