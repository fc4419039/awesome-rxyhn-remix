#!/bin/bash
# Menú de idioma del sistema (rofi).
# Marca el idioma activo y permite cambiar con búsqueda.

source "$HOME/.config/awesome/scripts/i18n.sh"

theme="$HOME/.config/awesome/theme/rofi-menu.rasi"

GREEN="#22c55e"; DARK="#64748b"

current=$(grep "^LANG=" /etc/locale.conf 2>/dev/null | cut -d= -f2)

map_file=$(mktemp /tmp/lc_map.XXXXXX 2>/dev/null) || map_file="/tmp/lc_map.tmp"
trap 'rm -f "$map_file"' EXIT

# code<TAB>nombre<TAB>bandera (Noto Emoji)
locales=$(cat <<'EOF'
es_MX.UTF-8	Español (México)	🇲🇽
es_ES.UTF-8	Español (España)	🇪🇸
en_US.UTF-8	Inglés (EE.UU.)	🇺🇸
en_GB.UTF-8	Inglés (Reino Unido)	🇬🇧
pt_BR.UTF-8	Portugués (Brasil)	🇧🇷
pt_PT.UTF-8	Portugués (Portugal)	🇵🇹
fr_FR.UTF-8	Francés	🇫🇷
de_DE.UTF-8	Alemán	🇩🇪
it_IT.UTF-8	Italiano	🇮🇹
ja_JP.UTF-8	Japonés	🇯🇵
ko_KR.UTF-8	Coreano	🇰🇷
zh_CN.UTF-8	Chino (Simplificado)	🇨🇳
ru_RU.UTF-8	Ruso	🇷🇺
ar_SA.UTF-8	Árabe	🇸🇦
EOF
)

while IFS=$'\t' read -r code name flag; do
    [ -z "$code" ] && continue
    row="<span font='Noto Emoji 16' foreground='#e2e8f0'>$flag</span>  $name  <span foreground='$DARK'>$code</span>"
    [ "$code" = "$current" ] && row="$row <span foreground='$GREEN'>󰁄</span>"
    printf '%s\t%s\n' "$row" "$code" >> "$map_file"
done <<< "$locales"

selected=$(cut -f1 "$map_file" | rofi -dmenu -markup-rows -theme "$theme" -i -no-custom)
[ -z "$selected" ] && exit 0

line=$(grep -F "$selected" "$map_file" | head -1)
locale=$(echo "$line" | cut -f2)
[ -z "$locale" ] && exit 0

sudo localectl set-locale "LANG=$locale" 2>/dev/null
if [ $? -eq 0 ]; then
    notify-send "$(t lc.updated_title)" "$(tsub lc.updated_body "$locale")" -i preferences-desktop-locale
    sleep 1
    awesome-client 'awesome.restart()' 2>/dev/null
else
    notify-send "$(t common.error)" "$(t lc.error_failed)" -i dialog-error
fi
