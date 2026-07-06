#!/bin/sh
# Temperatura fría solo en monitor secundario
xrandr --output eDP-1 --gamma 1:1:1 2>/dev/null
xrandr --output HDMI-1 --gamma 0.872:0.933:1.128 2>/dev/null
