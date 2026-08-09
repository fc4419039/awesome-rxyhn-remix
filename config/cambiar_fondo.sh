#!/bin/bash

DIR_FONDOS="$HOME/fondos"
QUEUE_DIR="$HOME/.cache"
QUEUE_FILE="$QUEUE_DIR/fondo_queue.txt"
MANUAL_FILE="$QUEUE_DIR/wallpaper_fijo.txt"
LAST_FILE="$QUEUE_DIR/ultimo_fondo.txt"
LOCK_FILE="$QUEUE_DIR/cambiar_fondo.lock"

# Si el usuario eligio un wallpaper manual, mantenerlo
if [ -f "$MANUAL_FILE" ]; then
    WALLPAPER=$(<"$MANUAL_FILE")
    [ -f "$WALLPAPER" ] && feh --bg-fill "$WALLPAPER" && exit 0
    rm -f "$MANUAL_FILE"
fi

mkdir -p "$QUEUE_DIR"

# Evita que dos invocaciones (arranque + menú) elijan la misma foto a la vez
exec 9>"$LOCK_FILE"
flock 9

mapfile -t files < <(find "$DIR_FONDOS" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \))
if [ ${#files[@]} -eq 0 ]; then
    exit 1
fi

# Descartar entradas de la cola cuyos archivos ya no existen
while [ -s "$QUEUE_FILE" ]; do
    WALLPAPER=$(head -n 1 "$QUEUE_FILE")
    [ -f "$WALLPAPER" ] && break
    tail -n +2 "$QUEUE_FILE" > "${QUEUE_FILE}.tmp" && mv "${QUEUE_FILE}.tmp" "$QUEUE_FILE"
done

# Regenerar la cola solo cuando esta vacia, excluyendo la ultima foto mostrada
# para que no se repita hasta que hayan pasado todas las demas
if [ ! -s "$QUEUE_FILE" ]; then
    candidates=("${files[@]}")
    if [ -f "$LAST_FILE" ] && [ ${#files[@]} -gt 1 ]; then
        prev=$(<"$LAST_FILE")
        filtered=()
        for f in "${files[@]}"; do
            [ "$f" = "$prev" ] || filtered+=("$f")
        done
        [ ${#filtered[@]} -gt 0 ] && candidates=("${filtered[@]}")
    fi
    printf "%s\n" "${candidates[@]}" | shuf > "$QUEUE_FILE"
fi

WALLPAPER=$(head -n 1 "$QUEUE_FILE")
[ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ] || exit 1
tail -n +2 "$QUEUE_FILE" > "${QUEUE_FILE}.tmp" && mv "${QUEUE_FILE}.tmp" "$QUEUE_FILE"

# Guardar la ultima foto mostrada para no repetirla en el siguiente ciclo
printf "%s\n" "$WALLPAPER" > "$LAST_FILE"

feh --bg-fill "$WALLPAPER"
