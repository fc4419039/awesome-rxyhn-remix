#!/bin/bash
# check.sh - Valida la sintaxis de toda la config (Lua, Shell y Python).
# Es tu "CI" de dotfiles: ejecutalo antes de reiniciar awesome o de hacer push.
#
# Uso:
#   scripts/check.sh                  # revisa ~/.config/awesome (config activa)
#   scripts/check.sh <DIR>            # revisa otro directorio (ej. el repo)
#   scripts/check.sh --watch          # modo vigilancia (revisa cada 2s)
#
# Salida con codigo de error:
#   0 = todo OK, 1 = errores de sintaxis

set -u

CFG="${1:-$HOME/.config/awesome}"
WATCH=false
if [ "${1:-}" = "--watch" ]; then
    WATCH=true
    CFG="$HOME/.config/awesome"
fi

# ─── Colores ───
BOLD=$'\e[1m'; RED=$'\e[31m'; GREEN=$'\e[32m'; CYAN=$'\e[36m'; DIM=$'\e[2m'; RESET=$'\e[0m'

check_lua() {
    local errors=0 total=0 f out
    while IFS= read -r -d '' f; do
        total=$((total + 1))
        out=$(luac -p "$f" 2>&1)
        if [ -n "$out" ]; then
            echo -e "  ${RED}✖${RESET} ${BOLD}${f#$CFG/}${RESET}"
            echo "$out" | sed "s/^/    /"
            errors=$((errors + 1))
        fi
    done < <(find "$CFG" -name '*.lua' -not -path '*/__pycache__/*' -not -path '*/.codebak/*' -print0)
    echo -e "${CYAN}Lua${RESET} ${DIM}($total)${RESET}"
    return "$errors"
}

check_sh() {
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
    echo -e "${CYAN}Shell${RESET} ${DIM}($total)${RESET}"
    return "$errors"
}

check_py() {
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
    echo -e "${CYAN}Python${RESET} ${DIM}($total)${RESET}"
    return "$errors"
}

run() {
    local lua_err sh_err py_err
    echo -e "${BOLD}── check.sh${RESET} ${DIM}→ $CFG${RESET}"
    check_lua;   lua_err=$?
    check_sh;    sh_err=$?
    check_py;    py_err=$?
    echo "────────────────────────────────"
    if [ $((lua_err + sh_err + py_err)) -eq 0 ]; then
        echo -e "  ${GREEN}✔${RESET} Todo OK"
        return 0
    fi
    echo -e "  ${RED}✖ $((lua_err + sh_err + py_err)) archivos con errores${RESET}"
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
