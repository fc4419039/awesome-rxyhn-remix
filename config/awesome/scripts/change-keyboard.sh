#!/bin/bash
# Menú de distribución del teclado (rofi).
# Marca la distribución activa y permite cambiar con búsqueda.

source "$HOME/.config/awesome/scripts/i18n.sh"

theme="$HOME/.config/awesome/theme/rofi-menu.rasi"

GREEN="#22c55e"

current=$(setxkbmap -query 2>/dev/null | grep "^layout:" | awk '{print $2}')

map_file=$(mktemp /tmp/kb_map.XXXXXX 2>/dev/null) || map_file="/tmp/kb_map.tmp"
trap 'rm -f "$map_file"' EXIT

# code<TAB>nombre<TAB>bandera (Noto Emoji, monocromo)
layouts=$(cat <<'EOF'
latam	Español (Latinoamérica)	🇲🇽
us	Inglés (EE.UU.)	🇺🇸
es	Español (España)	🇪🇸
uk	Inglés (Reino Unido)	🇬🇧
de	Alemán	🇩🇪
fr	Francés	🇫🇷
it	Italiano	🇮🇹
pt	Portugués	🇵🇹
br	Portugués (Brasil)	🇧🇷
jp	Japonés	🇯🇵
kr	Coreano	🇰🇷
cn	Chino	🇨🇳
ar	Árabe	🇸🇦
ru	Ruso	🇷🇺
EOF
)

while IFS=$'\t' read -r code name flag; do
    [ -z "$code" ] && continue
    row="<span font='Noto Emoji 16' foreground='#e2e8f0'>$flag</span>  $name"
    [ "$code" = "$current" ] && row="$row <span foreground='$GREEN'>󰁄</span>"
    printf '%s\t%s\n' "$row" "$code" >> "$map_file"
done <<< "$layouts"

selected=$(cut -f1 "$map_file" | rofi -dmenu -markup-rows -theme "$theme" -i -no-custom)
[ -z "$selected" ] && exit 0

line=$(grep -F "$selected" "$map_file" | head -1)
layout=$(echo "$line" | cut -f2)
[ -z "$layout" ] && exit 0

setxkbmap "$layout" 2>/dev/null
new_kb=$(setxkbmap -query 2>/dev/null | grep "^layout:" | awk '{print $2}')
notify-send "$(t kb.layout_changed)" "$(tsub kb.layout_current "$new_kb")" -i input-keyboard

sudo localectl set-x11-keymap "$layout" 2>/dev/null
if [ $? -eq 0 ]; then
    notify-send "$(t kb.layout_saved)" "$(tsub kb.layout_saved_perm "$layout")" -i input-keyboard
else
    notify-send "$(t common.error)" "$(t kb.save_failed)" -i dialog-error
fi
