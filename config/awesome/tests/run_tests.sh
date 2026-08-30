#!/usr/bin/env bash
# run_tests.sh - Ejecuta la suite de tests con busted

set -e

export PATH="$HOME/.luarocks/bin:$PATH"
CONFIG_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v busted &> /dev/null; then
    echo "busted no está instalado. Instálalo con: luarocks install --local busted"
    exit 1
fi

echo "Ejecutando tests..."
# .busted usa rutas relativas (helper, paths) → ejecutar desde la raíz de la config
cd "$CONFIG_DIR"
busted -f "$CONFIG_DIR/.busted" -o utfTerminal "$CONFIG_DIR/tests/spec/"
