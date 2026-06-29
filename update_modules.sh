#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
MODULE_DIR="$DIR/config/awesome/module"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

update_module() {
    local name="$1" repo="$2" subdir="$3"
    echo "=== Actualizando $name ==="
    git clone --depth 1 "$repo" "$TMPDIR/$name" 2>/dev/null
    local src="$TMPDIR/$name/${subdir:+$subdir}"
    local dst="$MODULE_DIR/$name"
    if [ -d "$dst" ]; then
        echo "Cambios:"
        diff -rq "$src" "$dst" 2>/dev/null | grep -v "^Only in $dst/.git" || echo "  (sin cambios)"
    fi
    rm -rf "$dst"
    cp -r "$src" "$dst"
    rm -rf "$TMPDIR/$name"
    echo ""
}

update_module "bling"     "https://github.com/BlingCorp/bling.git"             ""
update_module "rubato"    "https://github.com/andOrlando/rubato.git"          ""
update_module "layout-machi" "https://github.com/xinhaoyuan/layout-machi.git" ""

echo "=== Todos los módulos actualizados ==="
echo "Revisa los cambios con: git diff"
