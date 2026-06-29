#!/bin/bash

# 1. Detectar cuál es el reproductor activo preferente
PLAYER=$(playerctl metadata --format "{{ playerName }}" 2>/dev/null)

# Si hay múltiples, priorizar el que esté en estado "Playing"
PLAYING_PLAYER=$(playerctl -l 2>/dev/null | while read -r p; do
    if [ "$(playerctl -p "$p" status 2>/dev/null)" = "Playing" ]; then
        echo "$p"
        break
    fi
done)

# Si encontramos uno reproduciendo, usamos ese. Si no, el por defecto.
TARGET_PLAYER=${PLAYING_PLAYER:-$PLAYER}

# Si no hay ningún reproductor abierto, salir
if [ -z "$TARGET_PLAYER" ]; then
    echo "/ruta/a/una/imagen/por/defecto.png"
    exit 0
fi

# 2. Obtener la carátula según el reproductor
if [[ "$TARGET_PLAYER" == *"mpd"* ]]; then
    # Para MPD, extraemos la carátula usando ffmpeg o mpc (asumiendo que está en tu música)
    # Ajusta la ruta de tu librería de música si es necesario
    MUSIC_DIR="$HOME/Música"
    FILE=$(mpc current -f "%file%" 2>/dev/null)

    if [ -n "$FILE" ]; then
        # Extrae la carátula incrustada a un archivo temporal
        ffmpeg -y -i "$MUSIC_DIR/$FILE" -an -vcodec copy /tmp/mpd_cover.jpg &>/dev/null
        echo "/tmp/mpd_cover.jpg"
    else
        echo "/ruta/a/una/imagen/por/defecto.png"
    fi
else
    # Para Spotify, Firefox (Youtube), etc., usamos la URL de mpris:artUrl
    ART_URL=$(playerctl -p "$TARGET_PLAYER" metadata mpris:artUrl 2>/dev/null)

    if [[ "$ART_URL" == file://* ]]; then
        # Si es una ruta local (como Spotify a veces)
        echo "${ART_URL#file://}"
    elif [[ "$ART_URL" == http* ]]; then
        # Si es una URL web (Firefox), la descargamos rápidamente
        curl -s "$ART_URL" -o /tmp/web_cover.jpg
        echo "/tmp/web_cover.jpg"
    else
        echo "/ruta/a/una/imagen/por/defecto.png"
    fi
fi
