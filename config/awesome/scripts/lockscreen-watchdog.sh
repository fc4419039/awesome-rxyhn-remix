#!/bin/sh
# Watchdog del lockscreen de AwesomeWM
#
# Mientras el bloqueo está activo (existe el archivo de estado), vigila que
# AwesomeWM siga vivo. Si AwesomeWM muere (crash, Ctrl+Super+R, kill, etc.)
# mientras la pantalla está bloqueada:
#
#  1. Primero espera unos segundos a que SDDM reinicie la sesión.
#  2. Si Awesome vuelve, deja que el nuevo proceso maneje el lockscreen.
#  3. Si Awesome NO vuelve (SDDM no reinicia), lanza un locker externo
#     (i3lock/slock/xsecurelock) como fail-secure.
#
# Uso: lockscreen-watchdog.sh start|stop

set -u

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"
STATE_FILE="$CACHE/lockscreen/awesome-locked"
ENV_FILE="$CACHE/lockscreen/x-session-env"
XAUTH_CACHE="$CACHE/lockscreen/xauth-cache"
PIDFILE="/tmp/lockscreen-watchdog.pid"
LOG="/tmp/lockscreen-watchdog.log"

log() { echo "[lockscreen-watchdog $(date '+%F %T')] $*" >> "$LOG"; }

find_locker() {
    for l in xsecurelock i3lock slock swaylock physlock; do
        if command -v "$l" >/dev/null 2>&1; then
            echo "$l"
            return 0
        fi
    done
    return 1
}

# Busca un XAUTHORITY válido en este orden:
#  1. Cache de Awesome (copiado al bloquear, antes del crash)
#  2. Archivo indicado en el env file
#  3. Buscar en /tmp/xauth_* (para el caso de que SDDM cree uno nuevo)
find_xauth() {
    # 1. Cache de Awesome
    if [ -r "$XAUTH_CACHE" ]; then
        export XAUTHORITY="$XAUTH_CACHE"
        log "XAUTHORITY desde cache: $XAUTH_CACHE"
        return 0
    fi

    # 2. Env file
    if [ -f "$ENV_FILE" ]; then
        while IFS='=' read -r key value; do
            [ "$key" = "XAUTHORITY" ] && [ -n "$value" ] && [ -r "$value" ] && {
                export XAUTHORITY="$value"
                log "XAUTHORITY desde env: $XAUTHORITY"
                return 0
            }
        done < "$ENV_FILE"
    fi

    # 3. /tmp/xauth_*
    for f in /tmp/xauth_*; do
        [ "$f" = "/tmp/xauth_*" ] && break
        if [ -r "$f" ]; then
            export XAUTHORITY="$f"
            log "XAUTHORITY desde /tmp: $XAUTHORITY"
            return 0
        fi
    done

    return 1
}

# Lanza el locker externo UNA VEZ
launch_locker_once() {
    locker="$1"

    # Obtener DISPLAY
    if [ -f "$ENV_FILE" ]; then
        while IFS='=' read -r key value; do
            [ "$key" = "DISPLAY" ] && [ -n "$value" ] && export DISPLAY="$value"
        done < "$ENV_FILE"
    fi
    [ -z "${DISPLAY:-}" ] && export DISPLAY=:0

    # Obtener XAUTHORITY
    if ! find_xauth; then
        log "ADVERTENCIA: no se encontró XAUTHORITY, intentando sin él"
    fi

    # Construir comando
    case "$locker" in
        i3lock) cmd="$locker -n -e" ;;
        slock)  cmd="$locker" ;;
        *)      cmd="$locker" ;;
    esac

    log "ejecutando: $cmd (DISPLAY=${DISPLAY:-:0} XAUTHORITY=${XAUTHORITY:-none})"

    # Ejecutar el locker. Si el usuario se desbloquea correctamente (exit 0),
    # se limpia el estado. Cualquier otro código de salida se considera fallo
    # y no se reintenta para evitar bucles.
    $cmd
    rc=$?
    if [ "$rc" -eq 0 ]; then
        log "$locker: desbloqueado con éxito"
        rm -f "$STATE_FILE"
    else
        log "$locker: salida con código $rc"
    fi
    return $rc
}

start() {
    mkdir -p "$(dirname "$STATE_FILE")"

    # Si el estado ya existe (bloqueado), no recrear el archivo
    # solo asegurar que el PID file esté actualizado
    if [ ! -f "$STATE_FILE" ]; then
        : > "$STATE_FILE"          # marca: el bloqueo está activo
    fi
    echo $$ > "$PIDFILE"

    AWESOME_PID=$(pgrep -x awesome | head -n1)

    if [ -z "${AWESOME_PID:-}" ]; then
        log "WARNING: no se encontró awesome, pero se inicia vigilancia"
    fi

    LOCKER=$(find_locker) || LOCKER=""

    # Fail-closed: si awesome ni siquiera está corriendo, bloquear de inmediato
    if [ -n "${AWESOME_PID:-}" ] && ! kill -0 "$AWESOME_PID" 2>/dev/null; then
        log "awesome no está corriendo -> lanzando locker de inmediato"
        launch_locker_once "$LOCKER"
        exit $?
    fi

    log "vigilando awesome (PID $AWESOME_PID)..."

    # Loop principal: vigila hasta que el lock se libere o awesome muera
    while :; do
        if [ ! -f "$STATE_FILE" ]; then
            log "pantalla desbloqueada, terminando watchdog"
            rm -f "$PIDFILE"
            exit 0
        fi

        if ! kill -0 "${AWESOME_PID:-0}" 2>/dev/null; then
            log "awesome murió -> esperando 5s a que SDDM reinicie la sesión"
            sleep 5

            # ¿SDDM reinició awesome?
            NEW_AWE=$(pgrep -x awesome | head -n1)
            if [ -n "$NEW_AWE" ]; then
                log "SDDM reinició awesome (PID $NEW_AWE), dejando que maneje el lock"
                rm -f "$STATE_FILE"
                exit 0
            fi

            # No volvió: lanzar el locker externo como fail-secure
            log "awesome no volvió después de 5s -> lanzando locker externo"
            launch_locker_once "$LOCKER"
            exit $?
        fi

        sleep 0.5
    done
}

stop() {
    rm -f "$STATE_FILE"
    if [ -f "$PIDFILE" ]; then
        PID=$(cat "$PIDFILE" 2>/dev/null || echo "")
        [ -n "${PID:-}" ] && kill "$PID" 2>/dev/null
        rm -f "$PIDFILE"
    fi
}

case "${1:-}" in
    start) start ;;
    stop)  stop ;;
    *) echo "uso: $0 start|stop" >&2; exit 2 ;;
esac
