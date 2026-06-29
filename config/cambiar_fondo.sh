#!/bin/bash

# RUTA A TU CARPETA DE FOTOS
# Cambia esto por la ruta real donde guardas tus fondos
DIR_FONDOS="$HOME/fondos"

# Selecciona una imagen al azar y la aplica con feh
# --bg-fill estira la imagen llenando la pantalla sin deformarla
feh --bg-fill "$(find "$DIR_FONDOS" -type f | shuf -n 1)"
