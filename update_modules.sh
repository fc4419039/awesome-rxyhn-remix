#!/bin/bash
# IMPORTANTE: no usar `set -e`. Cada módulo se actualiza de forma independiente
# y un fallo de red NO debe abortar el script.

DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
MODULE_DIR="$DIR/config/awesome/module"
TMPDIR=$(mktemp -d 2>/dev/null || true)
trap 'rm -rf "$TMPDIR"' EXIT

update_module() {
    local name="$1" repo="$2" subdir="$3"
    echo "=== Actualizando $name ==="
    if ! git clone --depth 1 "$repo" "$TMPDIR/$name" 2>/dev/null; then
        echo -e "  ⚠ Fallo al clonar $name, se mantiene la version existente"
        return 1
    fi
    local src="$TMPDIR/$name/${subdir:+$subdir}"
    local dst="$MODULE_DIR/$name"
    if [ ! -d "$src" ]; then
        echo "  ⚠ Subdirectorio '$subdir' no encontrado en $name"
        rm -rf "$TMPDIR/$name"
        return 1
    fi
    if [ -d "$dst" ]; then
        echo "Cambios:"
        diff -rq "$src" "$dst" 2>/dev/null | grep -v "^Only in $dst/.git" || echo "  (sin cambios)"
    fi
    rm -rf "$dst"
    cp -r "$src" "$dst"
    rm -rf "$TMPDIR/$name"
    echo ""
}

# rubato: NO se actualiza automáticamente.
# El repo incluye fixes cross-Lua (lgi pcall fallback, preprocess_pos,
# math.floor en timeout_add, generación de IDs en subscribable) que el
# upstream de andOrlando/rubato aún no tiene. Sobrescribirlo reintroduce
# el error de rubato en clones/instalaciones limpias.
echo "=== rubato ==="
echo "  ⚠ rubato se mantiene en la versión corregida del repo (upstream sin fixes cross-Lua)"
echo "  Para actualizarlo manualmente, vuelve a aplicar los fixes de commit 1777115"

update_module "layout-machi" "https://github.com/xinhaoyuan/layout-machi.git" ""

# bling: NO se actualiza automáticamente.
# El upstream rompió layout/init.lua (bucle que asigna a variable 'const' en Lua 5.4:
# "attempt to assign to const variable 'p'"). Se mantiene la versión que funciona.
echo "=== bling ==="
echo "  ⚠ bling se mantiene en la versión del repo (upstream roto en Lua 5.4)"
echo "  Para actualizarlo manualmente, arregla config/awesome/module/bling/layout/init.lua"

echo "=== Todos los módulos actualizados ==="
echo "Revisa los cambios con: git diff"
