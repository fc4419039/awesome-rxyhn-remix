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

# 1. Elegir el sink físico de salida (hardware)
#    Se prioriza el dispositivo de salida "activo" en este orden:
#      1) Parlante Bluetooth conectado (bluez_output)
#      2) HDMI / DisplayPort con audio
#      3) Audio USB
#      4) Analógico/integrados (fallback)
#    Para los de tipo alsa se prefiere el que esté RUNNING (reproduciendo),
#    evitando así el error de "destino fijo" que cortaba el audio al cambiar
#    de dispositivo de salida.
pick_typed_sink() {
    local pattern="$1" prefs_state="$2"
    # Primero un sink de ese tipo que esté RUNNING (activo)
    local s
    s=$(pactl list sinks short 2>/dev/null | awk -v p="$pattern" '$2 ~ p && $NF == "RUNNING" {print $2; exit}')
    [ -n "$s" ] && { echo "$s"; return 0; }
    [ "$prefs_state" = "1" ] && return 1
    # Luego cualquiera de ese tipo
    pactl list sinks short 2>/dev/null | awk -v p="$pattern" '$2 ~ p {print $2; exit}'
}

bt_sink_connected() {
    local bt mac
    bt=$(pactl list sinks short 2>/dev/null | awk '/bluez_output/ {print $2; exit}')
    [ -z "$bt" ] && return 1
    mac=$(sed -E 's/bluez_output\.([0-9A-Fa-f_]+)\..*/\1/' <<<"$bt" | tr '_' ':')
    [ -n "$mac" ] && bluetoothctl info "$mac" 2>/dev/null | grep -q '^[[:space:]]*Connected: yes'
}

pick_hardware_sink() {
    local s
    # 1) Parlante Bluetooth conectado
    if bt_sink_connected; then
        pactl list sinks short 2>/dev/null | awk '/bluez_output/ {print $2; exit}'
        return 0
    fi
    # 2) HDMI / DisplayPort
    s=$(pick_typed_sink 'alsa_output.*hdmi' 0 || pick_typed_sink 'alsa_output.*(hdmi|dp|displayport)' 0)
    [ -n "$s" ] && { echo "$s"; return 0; }
    # 3) USB
    s=$(pick_typed_sink 'alsa_output.*usb' 0)
    [ -n "$s" ] && { echo "$s"; return 0; }
    # 4) Analógico/integrados
    s=$(pick_typed_sink 'alsa_output.*analog' 0)
    [ -n "$s" ] && { echo "$s"; return 0; }
    # Fallback: cualquier sink de hardware
    pactl list sinks short 2>/dev/null | awk '/alsa_output/ || /alsa_/ {print $2; exit}'
}

# Reapuntar (recrear) los loopbacks hacia el sink de hardware deseado.
# Como module-loopback tiene destino fijo, se descarga y recarga apuntando
# al nuevo sink destino.
repoint_loopback() {
    local src="$1" target="$2"
    [ -z "$target" ] && return 1
    local old
    old=$(pactl list modules short 2>/dev/null | grep "module-loopback" | grep "source=${src}.monitor" | awk '{print $1; exit}')
    if [ -n "$old" ]; then
        pactl unload-module "$old" 2>/dev/null
    fi
    if pactl load-module module-loopback source="${src}.monitor" sink="$target" latency_msec=10 2>/dev/null; then
        log "Loopback $src → $target"
        return 0
    fi
    log "WARN: No se pudo crear loopback $src → $target"
    return 1
}

log "Buscando sink de hardware..."
HARDWARE_SINK=$(pick_hardware_sink)

if [ -z "$HARDWARE_SINK" ]; then
    log "Sink no encontrado, esperando a PipeWire/PulseAudio..."
    if retry_cmd 'pactl list sinks short 2>/dev/null | awk '"'"'/alsa_output/ || /alsa_/ {print $2; exit}'"'"' >/dev/null'; then
        HARDWARE_SINK=$(pick_hardware_sink)
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

# 3. Loopback system_sink → hardware (dinámico: BT o analógico)
if [ -n "${HARDWARE_SINK:-}" ]; then
    repoint_loopback "$SYSTEM_SINK_NAME" "$HARDWARE_SINK"
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

# 7. Loopback notifications → hardware (dinámico)
if [ -n "${HARDWARE_SINK:-}" ]; then
    # Limpiar cualquier loopback de notificaciones viejo que apunte a otro destino
    pactl list modules short 2>/dev/null | \
      grep "module-loopback" | \
      grep "source=${NOTIF_SINK_NAME}.monitor" | \
      while read -r mod_id rest; do
        if echo "$rest" | grep -qv "sink=${HARDWARE_SINK}"; then
            pactl unload-module "$mod_id" 2>/dev/null || true
            log "Limpiado loopback viejo de $NOTIF_SINK_NAME (module $mod_id)"
        fi
      done

    repoint_loopback "$NOTIF_SINK_NAME" "$HARDWARE_SINK"
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