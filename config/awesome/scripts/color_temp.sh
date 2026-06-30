#!/bin/sh
redshift -O 7000

# Monitor secundario: gamma más frío (menos rojo/verde)
xrandr --output HDMI-1 --gamma 0.88:0.94:1.0 2>/dev/null
