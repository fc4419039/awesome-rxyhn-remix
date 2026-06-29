#!/usr/bin/env bash

NOTIF_SINK_NAME="notifications"
NOTIF_SINK_DESC="🔔 Notificaciones"

set -e

# Crear null sink si no existe
if ! pactl list sinks short 2>/dev/null | awk '{print $2}' | grep -qx "$NOTIF_SINK_NAME"; then
  pactl load-module module-null-sink \
    sink_name="$NOTIF_SINK_NAME" \
    sink_properties="device.description=$NOTIF_SINK_DESC"
fi

# Contar loopbacks existentes desde notifications.monitor a @DEFAULT_SINK@
LOOPBACK_COUNT=$(pactl list modules short 2>/dev/null | \
  grep "module-loopback" | \
  grep "source=${NOTIF_SINK_NAME}.monitor" | \
  wc -l)

if [ "$LOOPBACK_COUNT" -eq 0 ]; then
  pactl load-module module-loopback \
    source="${NOTIF_SINK_NAME}.monitor" \
    sink="@DEFAULT_SINK@" \
    latency_msec=25
fi

# Lanzar el router de notificaciones si no está corriendo
ROUTER_SCRIPT="${HOME}/.config/awesome/scripts/notification-router.sh"
if [ -x "$ROUTER_SCRIPT" ]; then
  if ! pgrep -f "$ROUTER_SCRIPT" > /dev/null 2>&1; then
    nohup "$ROUTER_SCRIPT" > /dev/null 2>&1 &
  fi
fi
