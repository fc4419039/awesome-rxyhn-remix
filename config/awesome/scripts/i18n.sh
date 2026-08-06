#!/bin/bash
# i18n.sh — diccionario de idiomas para los scripts rofi.
# Uso: source "$HOME/.config/awesome/scripts/i18n.sh"
#   t <clave> [fallback]          -> traduce una clave (fallback: la propia clave)
#   tsub <clave> <arg1> [arg2..]  -> traduce y sustituye cada %s por un argumento
#   TR_FORCE=<codigo>             -> fuerza un idioma (para pruebas)

I18N_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/awesome/i18n"
I18N_FILE="$I18N_DIR/strings.tsv"

_i18n_detect() {
    local lang=""
    if [[ -r /etc/locale.conf ]]; then
        lang=$(grep -E '^LANG=' /etc/locale.conf | head -1 | cut -d= -f2 | tr -d '"')
    fi
    [[ -z "$lang" ]] && lang="$LANG"
    lang="${lang%%.*}"
    case "${lang,,}" in
        es*) echo es ;;
        en*) echo en ;;
        pt*) echo pt ;;
        fr*) echo fr ;;
        de*) echo de ;;
        it*) echo it ;;
        ja*) echo ja ;;
        ko*) echo ko ;;
        zh*) echo zh ;;
        ru*) echo ru ;;
        ar*) echo ar ;;
        *) echo en ;;
    esac
}

if [[ -n "${TR_FORCE:-}" ]]; then
    TR_LANG="$TR_FORCE"
else
    TR_LANG="$(_i18n_detect)"
fi

declare -A TR_DICT

_i18n_load() {
    TR_DICT=()
    [[ -r "$I18N_FILE" ]] || return 1
    local header=() col=-1 i row=()
    IFS=$'\t' read -r -a header < "$I18N_FILE"
    for i in "${!header[@]}"; do
        [[ "${header[$i]}" == "$TR_LANG" ]] && { col=$i; break; }
    done
    [[ $col -lt 0 ]] && col=2
    while IFS=$'\t' read -r -a row; do
        [[ -z "${row[0]:-}" ]] && continue
        [[ "${row[0]}" == \#* ]] && continue
        [[ -z "${row[$col]:-}" ]] && continue
        TR_DICT["${row[0]}"]="${row[$col]}"
    done < "$I18N_FILE"
}

_i18n_load

t() {
    local key="$1" fallback="${2:-$1}"
    if [[ -n "${TR_DICT[$key]:-}" ]]; then
        printf '%b' "${TR_DICT[$key]}"
    else
        printf '%s' "$fallback"
    fi
}

tsub() {
    local key="$1" s a
    shift
    s="$(t "$key")"
    for a in "$@"; do
        s="${s/\%s/$a}"
    done
    printf '%b' "$s"
}
