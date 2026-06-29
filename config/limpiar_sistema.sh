#!/bin/bash
set -e

echo "[$(date '+%Y-%m-%d %H:%M')] Limpieza del sistema..."

# 1. Caché de paquetes: mantener últimas 2 versiones instaladas, borrar no instalados
paccache -rk2 -q 2>/dev/null
paccache -ruk0 -q 2>/dev/null
echo "  ✔ Caché de pacman (últimas 2 versiones)"

# 2. Logs del sistema: solo los últimos 7 días
journalctl --vacuum-time=7d -q 2>/dev/null
echo "  ✔ Logs del sistema (7 días)"

# 3. Thumbnails y papeleras (seguro de eliminar)
rm -rf ~/.cache/thumbnails/* ~/.local/share/Trash/* 2>/dev/null

# 4. Bases de datos de paquetes (sincronizar)
pacman -Fy 2>/dev/null || true

echo "  Hecho"
