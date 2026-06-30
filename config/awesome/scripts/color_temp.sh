#!/bin/sh
# Temperatura fría solo en monitor secundario
redshift -O 7500
xrandr --output eDP-1 --gamma 1:1:1 2>/dev/null
