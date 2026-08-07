#!/bin/bash
# Menu de zona horaria (rofi): marca la activa, agrupa por region
# y muestra el offset UTC de cada zona.

source "$HOME/.config/awesome/scripts/i18n.sh"

theme="$HOME/.config/awesome/theme/rofi-menu.rasi"

GREEN="#22c55e"
DIM="#64748b"
SLATE="#94a3b8"
CYAN="#06b6d4"
CLOCK="󰔔"
CHECK="󰁄"

current=$(timedatectl show --property=Timezone --value 2>/dev/null)

frequent="America/Mexico_City
America/Argentina/Buenos_Aires
America/Bogota
America/Lima
America/Santiago
America/Los_Angeles
America/New_York
Europe/Madrid
Europe/London
Europe/Paris
Asia/Tokyo"

all_zones=$(timedatectl list-timezones 2>/dev/null)
if [ -z "$all_zones" ]; then
    notify-send "$(t common.error)" "$(t tz.error_failed)" -i dialog-error
    exit 1
fi

map=$(mktemp /tmp/tz-map.XXXXXX 2>/dev/null) || map="/tmp/tz-map.tmp"
offf=$(mktemp /tmp/tz-off.XXXXXX 2>/dev/null) || offf="/tmp/tz-off.tmp"
trap 'rm -f "$map" "$offf"' EXIT

if command -v python3 >/dev/null 2>&1; then
    printf '%s\n' "$all_zones" | python3 -c '
import sys, datetime, zoneinfo
now = datetime.datetime.now(datetime.timezone.utc)
for line in sys.stdin:
    z = line.strip()
    if not z:
        continue
    try:
        sec = int(zoneinfo.ZoneInfo(z).utcoffset(now).total_seconds())
    except Exception:
        print(z + "\t")
        continue
    sign = "+" if sec >= 0 else "-"
    sec = abs(sec)
    print("%s\t%s%02d%02d" % (z, sign, sec // 3600, sec % 3600 // 60))
' > "$offf" 2>/dev/null
else
    printf '%s\n' "$all_zones" | xargs -P "$(nproc)" -I{} bash -c \
        'printf "%s\t%s\n" "{}" "$(TZ="{}" date +%z 2>/dev/null)"' > "$offf" 2>/dev/null
fi

declare -A OFF
while IFS=$'\t' read -r z o; do
    [ -n "$z" ] && OFF["$z"]="$o"
done < "$offf"

fmt_utc() {
    local o="$1"
    if [[ "$o" =~ ^([+-])([0-9]{2})([0-9]{2})$ ]]; then
        printf 'UTC%s%s:%s' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
    fi
}

is_current() { [ "$1" = "$current" ] && printf 1 || printf 0; }

zone_row() {
    local z="$1" city region
    city="${z##*/}"; city="${city//_/ }"
    region="${z%%/*}"
    if [ "$(is_current "$z")" = 1 ]; then
        printf "<span foreground='%s'>%s</span>  %s  <span foreground='%s' size='small'>%s · %s</span>  <span foreground='%s'>%s</span>\t%s" \
            "$GREEN" "$CLOCK" "$city" "$DIM" "$region" "$(fmt_utc "${OFF[$z]:-}")" "$GREEN" "$CHECK" "$z"
    else
        printf "<span foreground='%s'>%s</span>  %s  <span foreground='%s' size='small'>%s · %s</span>\t%s" \
            "$SLATE" "$CLOCK" "$city" "$DIM" "$region" "$(fmt_utc "${OFF[$z]:-}")" "$z"
    fi
}

printf "<span foreground='%s' weight='bold' size='small'>── %s ──</span>\tHEADER\n" \
    "$CYAN" "$(t tz.frequent)" >> "$map"

while IFS= read -r z; do
    [ -n "$z" ] && zone_row "$z" >> "$map" && printf '\n' >> "$map"
done <<< "$frequent"

prev=""
declare -A FREQ
while IFS= read -r z; do FREQ["$z"]=1; done <<< "$frequent"
while IFS= read -r z; do
    [ -z "$z" ] && continue
    [[ -n "${FREQ[$z]:-}" ]] && continue
    region="${z%%/*}"
    if [ "$region" != "$prev" ]; then
        printf "<span foreground='%s' weight='bold' size='small'>── %s ──</span>\tHEADER\n" \
            "$DIM" "$region" >> "$map"
        prev="$region"
    fi
    zone_row "$z" >> "$map" && printf '\n' >> "$map"
done <<< "$all_zones"

curline=$(grep -Fn $'\t'"$current" "$map" | head -1 | cut -d: -f1)
preselect=$(( ${curline:-0} > 0 ? curline - 1 : 0 ))

while :; do
    selected=$(cut -f1 "$map" | rofi -dmenu -markup-rows -theme "$theme" -no-custom -i -selected-row "$preselect")
    [ -z "$selected" ] && exit 0
    line=$(grep -F "$selected" "$map" | head -1)
    zone=$(printf '%s' "$line" | cut -f2)
    [ "$zone" = "HEADER" ] && continue
    [ -z "$zone" ] && exit 0
    break
done

sudo timedatectl set-timezone "$zone" 2>/dev/null
result=$?
if [ $result -eq 0 ]; then
    new_tz=$(timedatectl show --property=Timezone --value 2>/dev/null)
    notify-send "$(t tz.updated_title)" "$(tsub tz.updated_body "$new_tz")" -i preferences-system-time
else
    notify-send "$(t common.error)" "$(t tz.error_failed)" -i dialog-error
fi
