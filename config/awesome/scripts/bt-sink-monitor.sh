#!/usr/bin/env bash
# Monitor de sink Bluetooth.
# Vigila la aparición/desaparición de sinks bluez_output y, cuando cambia
# el estado, re-ejecuta notif-sink-setup.sh para que los loopbacks apunten
# al parlante Bluetooth (si está conectado) o vuelvan al analógico.
set -uo pipefail

SETUP_SCRIPT="${HOME}/.config/awesome/scripts/notif-sink-setup.sh"
PID_FILE="/tmp/bt-sink-monitor.pid"
LAST=""   # estado anterior: nombre del sink bluez activo o "none"

# Evitar instancias duplicadas
if [ -f "$PID_FILE" ]; then
    old=$(cat "$PID_FILE" 2>/dev/null || true)
    if [ -n "$old" ] && [ "$old" != "$$" ] && kill -0 "$old" 2>/dev/null; then
        exit 0
    fi
fi
echo "$$" > "$PID_FILE"
trap 'rm -f "$PID_FILE"' EXIT

repair() {
    if [ -x "$SETUP_SCRIPT" ]; then
        setsid "$SETUP_SCRIPT" >/dev/null 2>&1 &
    fi
}

while true; do
    bt=$(pactl list sinks short 2>/dev/null | awk '/bluez_output/ {print $2; exit}')
    curr="${bt:-none}"
    if [ "$curr" != "$LAST" ]; then
        repair
        LAST="$curr"
    fi
    sleep 2
done
