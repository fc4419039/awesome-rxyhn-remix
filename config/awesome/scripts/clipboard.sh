#!/bin/bash
# Gestor del portapapeles (cliphist + rofi).
#  - Lista con iconos según el tipo (texto, imagen, enlace, archivo, código)
#  - Acciones por elemento: copiar, borrar, volver
#  - Acción global: limpiar todo el historial

source "$HOME/.config/awesome/scripts/i18n.sh"

theme="$HOME/.config/awesome/theme/clipboard.rasi"
confirm_theme="$HOME/.config/awesome/theme/powermenu-confirm.rasi"

# ─── Colores ───
CYAN="#06b6d4"; GREEN="#22c55e"; AMBER="#eab308"; RED="#ef4444"
PURPLE="#a855f7"; BLUE="#3b82f6"; SLATE="#94a3b8"; DARK="#64748b"

xml_escape() {
    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

# Icono según el tipo del contenido (por el preview de cliphist)
item_icon() {
    case "$1" in
        "[["*"binary data"*) echo "<span foreground='$PURPLE'>󰄡</span>" ;;
        http*|*"://"*)        echo "<span foreground='$CYAN'>󰄀</span>" ;;
        /*)                   echo "<span foreground='$BLUE'>󰁰</span>" ;;
        "{"*|"function "*|"const "*|"def "*|"class "*|"#include"*)
                              echo "<span foreground='$AMBER'>󰆆</span>" ;;
        *)                    echo "<span foreground='$SLATE'>󰁆</span>" ;;
    esac
}

confirm() {
    local msg="$1" ans
    ans=$(printf "󰄬 %s\n󰅖 %s" "$(t pm.no "No")" "$(t pm.yes "Si")" | rofi -dmenu -theme "$confirm_theme" -mesg "$msg" -selected-row 0)
    [ "$ans" = "󰅖 $(t pm.yes "Si")" ]
}

# Capturar el contenido actual del portapapeles antes de listar
xclip -selection clipboard -o 2>/dev/null | cliphist store 2>/dev/null

map_file=$(mktemp /tmp/cb_map.XXXXXX 2>/dev/null) || map_file="/tmp/cb_map.tmp"
trap 'rm -f "$map_file"' EXIT

build_list() {
    : > "$map_file"
    local raw preview display
    while IFS= read -r raw; do
        [ -z "$raw" ] && continue
        preview=$(printf '%s' "$raw" | cut -f2-)
        [ -z "$preview" ] && preview=$(printf '%s' "$raw" | cut -f1)
        display="$(item_icon "$preview")   $(printf '%s' "$preview" | xml_escape)"
        printf '%s\t%s\n' "$display" "$raw" >> "$map_file"
    done < <(cliphist list 2>/dev/null)
}

list_menu() {
    printf "<span foreground='%s'>󰂐</span>   %s\n" "$AMBER" "$(t cb.clear)"
    local rows
    rows=$(cut -f1 "$map_file")
    if [ -z "$rows" ]; then
        printf "<span foreground='%s'>󰁆   %s</span>\n" "$DARK" "$(t cb.empty)"
    else
        printf '%s\n' "$rows"
    fi
    printf "<span foreground='%s'>󰁔</span>   %s" "$SLATE" "$(t cb.exit)"
}

# Menú de acciones de un elemento: devuelve 0=copiado, 2=borrado, otro=atrás
action_menu() {
    local preview="$1" raw="$2" fmt choice
    choice=$(printf "<span foreground='%s'>󰁴</span>   %s\n<span foreground='%s'>󰂐</span>   %s\n<span foreground='%s'>󰁔</span>   %s" \
        "$CYAN" "$(t cb.copy)" "$RED" "$(t cb.delete)" "$SLATE" "$(t cb.back)" |
        rofi -dmenu -markup-rows -theme "$theme" -i \
        -theme-str "window { height: 240px; } mainbox { children: [ message, listview ]; } message { enabled: true; padding: 14px 20px 4px 20px; horizontal-align: 0.5; text-color: #94a3b8; font: 'JetBrainsMono Nerd Font 10'; } listview { padding: 6px 14px 14px 14px; }" \
        -mesg "$(printf '%s' "$preview" | xml_escape)")
    [ -z "$choice" ] && return 1
    if echo "$choice" | grep -qF "$(t cb.copy)"; then
        if [[ "$preview" == *"binary data"* ]]; then
            fmt=$(printf '%s' "$preview" | sed -nE 's/.*binary data [0-9]+ B ([a-z0-9]+) .*/\1/p')
            [ -z "$fmt" ] && fmt=png
            cliphist decode <<< "$raw" 2>/dev/null | xclip -selection clipboard -t "image/$fmt" -i
        else
            cliphist decode <<< "$raw" 2>/dev/null | xclip -selection clipboard
        fi
        notify-send -i x-office-clipboard "$(t cb.prompt)" "$(t cb.copied)"
        return 0
    fi
    if echo "$choice" | grep -qF "$(t cb.delete)"; then
        cliphist delete <<< "$raw" 2>/dev/null
        return 2
    fi
    return 1
}

while true; do
    build_list
    choice=$(list_menu | rofi -dmenu -markup-rows -theme "$theme" -i)
    [ -z "$choice" ] && exit 0
    echo "$choice" | grep -qF "$(t cb.exit)" && exit 0
    echo "$choice" | grep -qF "$(t cb.empty)" && exit 0

    if echo "$choice" | grep -qF "$(t cb.clear)"; then
        if confirm "$(t cb.clear_confirm)"; then
            cliphist wipe 2>/dev/null
            notify-send -i edit-clear "$(t cb.prompt)" "$(t cb.cleared)"
        fi
        continue
    fi

    line=$(grep -F "$choice" "$map_file" | head -1)
    raw=$(echo "$line" | cut -f2-)
    [ -z "$raw" ] && continue
    preview=$(echo "$raw" | cut -f2-)
    [ -z "$preview" ] && preview=$(echo "$raw" | cut -f1)

    action_menu "$preview" "$raw"
    [ $? -eq 0 ] && exit 0
done
