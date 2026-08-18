#!/bin/bash
# Restart touchegg daemon if it dies or gestures stop working
pkill -u "$(whoami)" -f 'touchegg --daemon' 2>/dev/null
sleep 0.5
nohup touchegg > /dev/null 2>&1 &
