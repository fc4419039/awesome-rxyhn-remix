#!/bin/bash
# check.sh - Valida sintaxis Y runtime de la config (Lua, Shell, Python).
# Uso desde CUALQUIER directorio:
#   check.sh                    # revisa ~/.config/awesome
#   check.sh <DIR>              # revisa otro directorio
#   check.sh --watch            # modo vigilancia (cada 2s)
#   check.sh --runtime          # solo validación runtime
#   check.sh --syntax           # solo sintaxis
#   check.sh --full             # sintaxis + runtime (default)
#
# Salida: 0 = OK, 1 = errores

set -u

# Detectar directorio del script (funciona desde cualquier lugar)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default SIEMPRE a ~/.config/awesome, independientemente de dónde esté el script
CFG="${1:-$HOME/.config/awesome}"
AWESOME_CFG="$HOME/.config/awesome"
RUNTIME_SCRIPT="$AWESOME_CFG/scripts/check_runtime.lua"
WATCH=false
MODE="full"  # full | syntax | runtime

case "${1:-}" in
    --watch) WATCH=true; CFG="$AWESOME_CFG"; shift ;;
    --runtime) MODE="runtime"; shift ;;
    --syntax) MODE="syntax"; shift ;;
    --full) MODE="full"; shift ;;
esac

CFG="${1:-$AWESOME_CFG}"

# ─── Colores ───
BOLD=$'\e[1m'; RED=$'\e[31m'; GREEN=$'\e[32m'; CYAN=$'\e[36m'; YELLOW=$'\e[33m'; DIM=$'\e[2m'; RESET=$'\e[0m'

check_lua_syntax() {
    local errors=0 total=0 f out
    while IFS= read -r -d '' f; do
        total=$((total + 1))
        out=$(luac -p "$f" 2>&1)
        if [ -n "$out" ]; then
            echo -e "  ${RED}✖${RESET} ${BOLD}${f#$CFG/}${RESET}"
            echo "$out" | sed "s/^/    /"
            errors=$((errors + 1))
        fi
    done < <(find "$CFG" -name '*.lua' -not -path '*/__pycache__/*' -not -path '*/.codebak/*' -not -path '*/tests/*' -print0)
    echo -e "${CYAN}Lua (syntax)${RESET} ${DIM}($total)${RESET}"
    return "$errors"
}

check_sh_syntax() {
    local errors=0 total=0 f out
    while IFS= read -r -d '' f; do
        total=$((total + 1))
        out=$(bash -n "$f" 2>&1)
        if [ -n "$out" ]; then
            echo -e "  ${RED}✖${RESET} ${BOLD}${f#$CFG/}${RESET}"
            echo "$out" | sed "s/^/    /"
            errors=$((errors + 1))
        fi
    done < <(find "$CFG" -name '*.sh' -print0)
    echo -e "${CYAN}Shell (syntax)${RESET} ${DIM}($total)${RESET}"
    return "$errors"
}

check_py_syntax() {
    local errors=0 total=0 f out
    while IFS= read -r -d '' f; do
        total=$((total + 1))
        out=$(python3 -c "import ast,sys
for f in sys.argv[1:]:
    ast.parse(open(f).read(), f)" "$f" 2>&1)
        if [ -n "$out" ]; then
            echo -e "  ${RED}✖${RESET} ${BOLD}${f#$CFG/}${RESET}"
            echo "$out" | sed "s/^/    /"
            errors=$((errors + 1))
        fi
    done < <(find "$CFG" -name '*.py' -print0)
    echo -e "${CYAN}Python (syntax)${RESET} ${DIM}($total)${RESET}"
    return "$errors"
}

check_runtime() {
    echo -e "${CYAN}Lua (runtime)${RESET}"
    lua "$RUNTIME_SCRIPT"
    return $?
}

run() {
    local total_err=0 lua_err=0 sh_err=0 py_err=0 rt_err=0

    echo -e "${BOLD}── check.sh${RESET} ${DIM}→ $CFG${RESET} ${DIM}[$MODE]${RESET}"

    case "$MODE" in
        syntax)
            check_lua_syntax;   lua_err=$?
            check_sh_syntax;    sh_err=$?
            check_py_syntax;    py_err=$?
            ;;
        runtime)
            check_runtime;      rt_err=$?
            ;;
        full|*)
            check_lua_syntax;   lua_err=$?
            check_sh_syntax;    sh_err=$?
            check_py_syntax;    py_err=$?
            check_runtime;      rt_err=$?
            ;;
    esac

    total_err=$((lua_err + sh_err + py_err + rt_err))
    echo "────────────────────────────────"
    if [ $total_err -eq 0 ]; then
        echo -e "  ${GREEN}✔${RESET} Todo OK"
        return 0
    fi
    echo -e "  ${RED}✖ $total_err errores totales${RESET}"
    return 1
}

if [ "$WATCH" = true ]; then
    while true; do
        clear
        run
        sleep 2
    done
else
    run
    exit $?
fi