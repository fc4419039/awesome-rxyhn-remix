#!/usr/bin/env bash
# Setup script for system_sink and notifications sinks + loopbacks
# Also manages the notification-router.sh process
# NEVER exits with error - always tries to recover

set -uo pipefail

SYSTEM_SINK_NAME="system_sink"
SYSTEM_SINK_DESC="Sistema"
NOTIF_SINK_NAME="notifications"
NOTIF_SINK_DESC="Notificaciones"

ROUTER_SCRIPT="${HOME}/.config/awesome/scripts/notification-router.sh"
ROUTER_PID_FILE="/tmp/notification-router.pid"

# Function to kill existing router process
kill_existing_router() {
    if [ -f "$ROUTER_PID_FILE" ]; then
        local old_pid=$(cat "$ROUTER_PID_FILE" 2>/dev/null || true)
        if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
            kill "$old_pid" 2>/dev/null
            sleep 0.5
            if kill -0 "$old_pid" 2>/dev/null; then
                kill -9 "$old_pid" 2>/dev/null
            fi
        fi
    fi
    pkill -f "notification-router.sh" 2>/dev/null || true
}

# Helper: log with timestamp
log() { echo "[$(date '+%H:%M:%S')] $*"; }

# Helper: retry a command with exponential backoff
retry_cmd() {
    local max_attempts=3
    local attempt=1
    local delay=1
    while [ $attempt -le $max_attempts ]; do
        if eval "$1" 2>/dev/null; then
            return 0
        fi
        log "Intento $attempt/$max_attempts falló, reintentando en ${delay}s..."
        sleep $delay
        delay=$((delay * 2))
        attempt=$((attempt + 1))
    done
    return 1
}

# 1. Obtener el sink físico (hardware) - con retry
log "Buscando sink de hardware..."
HARDWARE_SINK=$(pactl list sinks short 2>/dev/null | awk '/alsa_output/ || /bluez/ || /alsa_/ {print $2; exit}')

if [ -z "$HARDWARE_SINK" ]; then
    log "Sink no encontrado, esperando a PipeWire/PulseAudio..."
    if retry_cmd 'pactl list sinks short 2>/dev/null | awk '"'"'/alsa_output/ || /bluez/ || /alsa_/ {print $2; exit}'"'"' >/dev/null'; then
        HARDWARE_SINK=$(pactl list sinks short 2>/dev/null | awk '/alsa_output/ || /bluez/ || /alsa_/ {print $2; exit}')
    fi
fi

if [ -z "$HARDWARE_SINK" ]; then
    log "WARN: No hay sink de hardware disponible. Reintentará notification-router.sh"
    # No exit 1 - let router handle recreation
else
    log "Hardware sink: $HARDWARE_SINK"
fi

# 2. Crear system_sink si no existe
if ! pactl list sinks short 2>/dev/null | awk '{print $2}' | grep -qx "$SYSTEM_SINK_NAME"; then
    if pactl load-module module-null-sink \
        sink_name="$SYSTEM_SINK_NAME" \
        sink_properties="device.description=$SYSTEM_SINK_DESC" 2>/dev/null; then
        log "Creado $SYSTEM_SINK_NAME"
    else
        log "WARN: No se pudo crear $SYSTEM_SINK_NAME"
    fi
fi

# 3. Loopback system_sink → hardware
if [ -n "${HARDWARE_SINK:-}" ] && ! pactl list modules short 2>/dev/null | \
  grep "module-loopback" | \
  grep -q "source=${SYSTEM_SINK_NAME}.monitor.*sink=${HARDWARE_SINK}"; then
    if pactl load-module module-loopback \
        source="${SYSTEM_SINK_NAME}.monitor" \
        sink="$HARDWARE_SINK" \
        latency_msec=25 2>/dev/null; then
        log "Creado loopback $SYSTEM_SINK_NAME → $HARDWARE_SINK"
    else
        log "WARN: No se pudo crear loopback system_sink"
    fi
fi

# 4. Elegir system_sink como default
if pactl list sinks short 2>/dev/null | awk '{print $2}' | grep -qx "$SYSTEM_SINK_NAME"; then
    pactl set-default-sink "$SYSTEM_SINK_NAME" 2>/dev/null || true
fi

# 4b. Fijar también el default de WirePlumber
SYS_PW_ID=$(wpctl status 2>/dev/null | grep -m1 "[0-9]*[.] $SYSTEM_SINK_DESC" | sed -E 's/^[^0-9]*([0-9]+).*/\1/')
if [ -n "$SYS_PW_ID" ] && [ "$SYS_PW_ID" -eq "$SYS_PW_ID" ] 2>/dev/null; then
    wpctl set-default "$SYS_PW_ID" 2>/dev/null && log "Default WirePlumber: $SYSTEM_SINK_DESC ($SYS_PW_ID)"
fi

# 5. Mover streams existentes del hardware a system_sink
if [ -n "${HARDWARE_SINK:-}" ]; then
    pactl list sink-inputs short 2>/dev/null | awk '{print $1}' | while read -r id; do
        [ -z "$id" ] && continue
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
fi

# 6. Crear notifications sink si no existe
if ! pactl list sinks short 2>/dev/null | awk '{print $2}' | grep -qx "$NOTIF_SINK_NAME"; then
    if pactl load-module module-null-sink \
        sink_name="$NOTIF_SINK_NAME" \
        sink_properties="device.description=$NOTIF_SINK_DESC" 2>/dev/null; then
        log "Creado $NOTIF_SINK_NAME"
    else
        log "WARN: No se pudo crear $NOTIF_SINK_NAME"
    fi
fi

# 7. Loopback notifications → hardware
if [ -n "${HARDWARE_SINK:-}" ]; then
    pactl list modules short 2>/dev/null | \
      grep "module-loopback" | \
      grep "source=${NOTIF_SINK_NAME}.monitor" | \
      while read -r mod_id rest; do
        if echo "$rest" | grep -qv "sink=${HARDWARE_SINK}"; then
            pactl unload-module "$mod_id" 2>/dev/null || true
            log "Limpiado loopback viejo de $NOTIF_SINK_NAME (module $mod_id)"
        fi
      done

    EXISTING_NOTIF_LOOPBACK=$(pactl list modules short 2>/dev/null | \
      grep "module-loopback" | \
      grep "source=${NOTIF_SINK_NAME}.monitor.*sink=${HARDWARE_SINK}" | \
      wc -l)

    if [ "$EXISTING_NOTIF_LOOPBACK" -eq 0 ]; then
        if pactl load-module module-loopback \
            source="${NOTIF_SINK_NAME}.monitor" \
            sink="$HARDWARE_SINK" \
            latency_msec=25 2>/dev/null; then
            log "Creado loopback $NOTIF_SINK_NAME → $HARDWARE_SINK"
        else
            log "WARN: No se pudo crear loopback notifications"
        fi
    fi
fi

# 8. Asegurar volumen del hardware al maximo
if [ -n "${HARDWARE_SINK:-}" ]; then
    pactl set-sink-volume "$HARDWARE_SINK" 100% 2>/dev/null || true
fi

# 9. Matar router anterior y lanzar uno nuevo
kill_existing_router

if [ -x "$ROUTER_SCRIPT" ]; then
    nohup "$ROUTER_SCRIPT" > /dev/null 2>&1 &
    ROUTER_PID=$!
    echo "$ROUTER_PID" > "$ROUTER_PID_FILE"
    log "Lanzado notification-router.sh (PID: $ROUTER_PID)"
else
    log "WARN: notification-router.sh no encontrado o sin permisos"
fi

log "notif-sink-setup completado"
exit 0