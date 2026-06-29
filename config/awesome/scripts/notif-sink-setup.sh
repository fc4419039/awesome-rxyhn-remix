#!/usr/bin/env bash

SYSTEM_SINK_NAME="system_sink"
SYSTEM_SINK_DESC="🔊 Sistema"
NOTIF_SINK_NAME="notifications"
NOTIF_SINK_DESC="🔔 Notificaciones"

set -e

# 1. Obtener el sink físico (hardware)
HARDWARE_SINK=$(pactl list sinks short | awk '/alsa_output/ || /bluez/ || /alsa_/ {print $2; exit}')

if [ -z "$HARDWARE_SINK" ]; then
  echo "ERROR: No se encontró sink de hardware" >&2
  exit 1
fi

echo "Hardware sink: $HARDWARE_SINK"

# 2. Crear system_sink si no existe
if ! pactl list sinks short 2>/dev/null | awk '{print $2}' | grep -qx "$SYSTEM_SINK_NAME"; then
  pactl load-module module-null-sink \
    sink_name="$SYSTEM_SINK_NAME" \
    sink_properties="device.description=$SYSTEM_SINK_DESC"
  echo "Creado $SYSTEM_SINK_NAME"
fi

# 3. Loopback system_sink → hardware (solo si no existe)
if ! pactl list modules short 2>/dev/null | \
  grep "module-loopback" | \
  grep -q "source=${SYSTEM_SINK_NAME}.monitor.*sink=${HARDWARE_SINK}"; then
  pactl load-module module-loopback \
    source="${SYSTEM_SINK_NAME}.monitor" \
    sink="$HARDWARE_SINK" \
    latency_msec=25
  echo "Creado loopback $SYSTEM_SINK_NAME → $HARDWARE_SINK"
fi

# 4. Elegir system_sink como default
pactl set-default-sink "$SYSTEM_SINK_NAME"

# 5. Mover streams existentes del hardware a system_sink
pactl list sink-inputs short 2>/dev/null | awk '{print $1}' | while read -r id; do
  sink_id=$(pactl list sink-inputs 2>/dev/null | awk -v id="$id" '
    /^Sink Input #/ {
      s = $0; sub(/^Sink Input #/, "", s); sub(/:$/, "", s); gsub(/[ \t]/, "", s)
      found = (s == id)
    }
    found && /^[ \t]*Sink: / {
      gsub(/.*Sink: /, "", $0); print $0; exit
    }
  ')
  if [ "$sink_id" = "$HARDWARE_SINK" ]; then
    # No mover el loopback de system_sink ni de notifications
    owner_mod=$(pactl list sink-inputs 2>/dev/null | awk -v id="$id" '
      /^Sink Input #/ {
        s = $0; sub(/^Sink Input #/, "", s); sub(/:$/, "", s); gsub(/[ \t]/, "", s)
        found = (s == id)
      }
      found && /^[ \t]*Owner Module: / {
        gsub(/.*Owner Module: /, "", $0); print $0; exit
      }
    ')
    # Saltar loopbacks (no tienen clientId normal y son internos)
    is_loopback=$(pactl list sink-inputs 2>/dev/null | awk -v id="$id" '
      /^Sink Input #/ {
        s = $0; sub(/^Sink Input #/, "", s); sub(/:$/, "", s); gsub(/[ \t]/, "", s)
        found = (s == id)
      }
      found && /node\.virtual.*true/ { print "yes"; exit }
    ')
    if [ "$is_loopback" != "yes" ]; then
      pactl move-sink-input "$id" "$SYSTEM_SINK_NAME" 2>/dev/null || true
    fi
  fi
done

# 6. Crear notifications sink si no existe
if ! pactl list sinks short 2>/dev/null | awk '{print $2}' | grep -qx "$NOTIF_SINK_NAME"; then
  pactl load-module module-null-sink \
    sink_name="$NOTIF_SINK_NAME" \
    sink_properties="device.description=$NOTIF_SINK_DESC"
  echo "Creado $NOTIF_SINK_NAME"
fi

# 7. Loopback notifications → hardware (NUNCA a @DEFAULT_SINK@)
#    Primero limpiar loopbacks viejos de notifications que apunten a otro lado
pactl list modules short 2>/dev/null | \
  grep "module-loopback" | \
  grep "source=${NOTIF_SINK_NAME}.monitor" | \
  while read -r mod_id rest; do
    # Verificar si apunta al hardware o a otro sink
    if echo "$rest" | grep -qv "sink=${HARDWARE_SINK}"; then
      pactl unload-module "$mod_id" 2>/dev/null || true
      echo "Limpiado loopback viejo de $NOTIF_SINK_NAME (module $mod_id)"
    fi
  done

# Crear loopback nuevo si no existe al hardware
EXISTING_NOTIF_LOOPBACK=$(pactl list modules short 2>/dev/null | \
  grep "module-loopback" | \
  grep "source=${NOTIF_SINK_NAME}.monitor.*sink=${HARDWARE_SINK}" | \
  wc -l)

if [ "$EXISTING_NOTIF_LOOPBACK" -eq 0 ]; then
  pactl load-module module-loopback \
    source="${NOTIF_SINK_NAME}.monitor" \
    sink="$HARDWARE_SINK" \
    latency_msec=25
  echo "Creado loopback $NOTIF_SINK_NAME → $HARDWARE_SINK"
fi

# 8. Lanzar el router de notificaciones si no está corriendo
ROUTER_SCRIPT="${HOME}/.config/awesome/scripts/notification-router.sh"
if [ -x "$ROUTER_SCRIPT" ]; then
  if ! pgrep -f "$ROUTER_SCRIPT" > /dev/null 2>&1; then
    nohup "$ROUTER_SCRIPT" > /dev/null 2>&1 &
    echo "Lanzado notification-router.sh"
  fi
fi
