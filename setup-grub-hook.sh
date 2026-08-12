#!/bin/bash
# Instala un hook de pacman que regenera /boot/grub/grub.cfg automáticamente
# tras cada actualización de kernel.
#
# Previene el boot roto tras una actualización:
#   mount: /boot/efi: unknown filesystem type 'vfat'
#   (GRUB apuntando a un kernel viejo sin módulos en /lib/modules)
#
# Uso:
#   ./setup-grub-hook.sh        # con sudo (necesita root)

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "⚠️  Ejecuta como root: sudo $0" >&2
    exit 1
fi

if ! command -v grub-mkconfig >/dev/null 2>&1; then
    echo "⚠️  grub-mkconfig no encontrado. ¿Usas GRUB como bootloader?" >&2
    exit 1
fi

DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_SRC="$DIR/misc/grub-mkconfig.hook"
HOOK_DST="/etc/pacman.d/hooks/grub-mkconfig.hook"

if [ ! -f "$HOOK_SRC" ]; then
    echo "✗ No se encontró $HOOK_SRC" >&2
    exit 1
fi

mkdir -p /etc/pacman.d/hooks
cp "$HOOK_SRC" "$HOOK_DST"
echo "✓ Hook instalado: $HOOK_DST"
echo "  grub.cfg se regenerará solo tras cada actualización/instalación de kernel."

echo ""
echo "Regenerando grub.cfg ahora..."
grub-mkconfig -o /boot/grub/grub.cfg
