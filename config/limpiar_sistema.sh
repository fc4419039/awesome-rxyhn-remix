#!/bin/bash
set -e

echo "[$(date '+%Y-%m-%d %H:%M')] Limpieza del sistema..."

# Detectar gestor de paquetes
PM=""
if command -v pacman >/dev/null 2>&1; then PM="pacman"; fi
if command -v apt-get >/dev/null 2>&1; then PM="apt"; fi
if command -v dnf >/dev/null 2>&1; then PM="dnf"; fi
if command -v zypper >/dev/null 2>&1; then PM="zypper"; fi

case "$PM" in
    pacman)
        # Caché de paquetes: mantener últimas 2 versiones instaladas, borrar no instalados
        paccache -rk2 -q 2>/dev/null
        paccache -ruk0 -q 2>/dev/null
        echo "  ✔ Caché de pacman (últimas 2 versiones)"
        # Bases de datos de paquetes (sincronizar)
        pacman -Fy 2>/dev/null || true
        ;;
    apt)
        # Caché de paquetes: limpiar descargas viejas y listas de paquetes
        apt-get autoclean -q 2>/dev/null || true
        apt-get clean -q 2>/dev/null || true
        echo "  ✔ Caché de apt"
        apt-get update -qq 2>/dev/null || true
        ;;
    dnf)
        # Caché de paquetes: limpiar todo el caché y regenerar metadatos
        dnf clean all -q 2>/dev/null || true
        echo "  ✔ Caché de dnf"
        dnf makecache -q 2>/dev/null || true
        ;;
    zypper)
        # Caché de paquetes: limpiar descargas y actualizar listas
        zypper clean -a 2>/dev/null || true
        echo "  ✔ Caché de zypper"
        zypper refresh -q 2>/dev/null || true
        ;;
    *)
        echo "  ⚠ No se detectó gestor de paquetes conocido (pacman/apt/dnf/zypper)"
        ;;
esac

# 2. Logs del sistema: solo los últimos 7 días
journalctl --vacuum-time=7d -q 2>/dev/null
echo "  ✔ Logs del sistema (7 días)"

# 3. Thumbnails y papeleras (seguro de eliminar)
rm -rf ~/.cache/thumbnails/* ~/.local/share/Trash/* 2>/dev/null

echo "  Hecho"
