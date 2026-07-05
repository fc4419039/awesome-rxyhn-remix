#!/bin/sh
# Temperatura fría en monitores conectados
for output in $(xrandr --query | grep " connected" | awk '{print $1}'); do
    xrandr --output "$output" --gamma 0.872:0.933:1.128 2>/dev/null
done
