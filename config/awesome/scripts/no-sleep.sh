#!/bin/bash
# Toggle: disable/enable screen blanking and sleep on idle

source "$HOME/.config/awesome/scripts/i18n.sh"

export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"

STATE_FILE="/tmp/.no-sleep-state"

if [ -f "$STATE_FILE" ]; then
    rm "$STATE_FILE"
    xset s on
    xset +dpms
    notify-send -t 3000 "$(t ns.title)" "$(t ns.off)"
else
    touch "$STATE_FILE"
    xset s off
    xset -dpms
    notify-send -t 3000 "$(t ns.title)" "$(t ns.on)"
fi
