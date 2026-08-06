#!/bin/bash

source "$HOME/.config/awesome/scripts/i18n.sh"

theme="$HOME/.config/awesome/theme/network.rasi"
confirm_theme="$HOME/.config/awesome/theme/powermenu-confirm.rasi"

confirm() {
    local msg="$1" ans
    ans=$(printf "󰄰 %s\n󰄱 %s" "$(t pm.no "No")" "$(t pm.yes "Si")" | rofi -dmenu -theme "$confirm_theme" -mesg "$msg" -selected-row 0)
    [ "$ans" = "󰄱 $(t pm.yes "Si")" ]
}

# --fresh fuerza un escaneo completo (espera a que termine) en la primera lista
rescan="no"
[ "$1" = "--fresh" ] && rescan="yes"

signal_icon() {
    local sig=$1 saved=${2:-0} color glyph
    if   [ "$sig" -ge 80 ]; then glyph="󰤨"
    elif [ "$sig" -ge 60 ]; then glyph="󰤥"
    elif [ "$sig" -ge 40 ]; then glyph="󰤢"
    elif [ "$sig" -ge 20 ]; then glyph="󰤟"
    else glyph="󰤫"
    fi
    if [ "$saved" = "1" ]; then
        color="#06b6d4"
    elif [ "$sig" -ge 80 ]; then color="#22c55e"
    elif [ "$sig" -ge 60 ]; then color="#eab308"
    elif [ "$sig" -ge 40 ]; then color="#f97316"
    elif [ "$sig" -ge 20 ]; then color="#f87171"
    else color="#ef4444"
    fi
    echo "<span foreground='$color'>$glyph</span>"
}

band_badge() {
    local band=$1
    case "$band" in
        "5 GHz") echo "<span foreground='#67e8f9' background='#164e63' style='italic' font='JetBrainsMono Nerd Font 9'> 5G </span>" ;;
        "2.4 GHz") echo "<span foreground='#94a3b8' background='#334155' font='JetBrainsMono Nerd Font 9'> 2.4G </span>" ;;
        *) echo "" ;;
    esac
}

# Desescapa los caracteres especiales que nmcli -t inserta en los valores
# (\:  ->  : ,  \\  ->  \ ,  \n,  \t)
nm_unescape() {
    local s="$1" out="" i=0 c n=${#1}
    while [ "$i" -lt "$n" ]; do
        c=${s:$i:1}
        if [ "$c" = "\\" ] && [ "$i" -lt $((n - 1)) ]; then
            i=$((i + 1)); c=${s:$i:1}
            case "$c" in
                n) out+=$'\n' ;;
                t) out+=$'\t' ;;
                *) out+="$c" ;;
            esac
        else
            out+="$c"
        fi
        i=$((i + 1))
    done
    printf '%s' "$out"
}

# Quita markup, el icono inicial, los badges de banda y los iconos de candado/punto
# para quedarse solo con el SSID. Los badges se eliminan SOLO al final de la línea
# (nunca dentro del nombre, p. ej. "MEGACABLE_5G_7D04" no se altera).
strip_ssid() {
    sed 's/<[^>]*>//g' \
        | sed 's/^[^ ]* *//' \
        | sed 's/ *● *$//' \
        | sed 's/ *5G *$//' \
        | sed 's/ *2\.4G *$//' \
        | sed 's/ * *$//' \
        | sed 's/ * *$//' \
        | sed 's/[[:space:]]*$//'
}

list_file=$(mktemp /tmp/wifi_list.XXXXXX 2>/dev/null) || list_file="/tmp/wifi_list.tmp"
sec_file=$(mktemp /tmp/wifi_sec.XXXXXX 2>/dev/null) || sec_file="/tmp/wifi_sec.tmp"
raw_file=$(mktemp /tmp/wifi_raw.XXXXXX 2>/dev/null) || raw_file="/tmp/wifi_raw.tmp"
saved_file=$(mktemp /tmp/wifi_saved.XXXXXX 2>/dev/null) || saved_file="/tmp/wifi_saved.tmp"

# SSID de las redes guardadas en NetworkManager (perfil wifi -> su SSID real)
declare -A saved_ssids
while IFS= read -r name; do
    ssid=$(nmcli -g 802-11-wireless.ssid connection show "$name" 2>/dev/null)
    [ -z "$ssid" ] && continue
    ssid=$(nm_unescape "$ssid")
    saved_ssids[$ssid]=1
    echo "$ssid|$name" >> "$saved_file"
done < <(nmcli -t -f TYPE,NAME connection show 2>/dev/null | grep '^802-11-wireless:' | cut -d: -f2-)

connected_ssid=$(LC_ALL=C nmcli -t -f ACTIVE,SSID dev wifi list --rescan no 2>/dev/null | grep '^yes' | head -1 | cut -d: -f2-)
connected_ssid=$(nm_unescape "$connected_ssid")

# Parsing desde la derecha: SIGNAL/SECURITY/BAND son los 3 últimos campos fijos
# y no contienen ':', así el SSID (que puede llevar ':' escapado) queda intacto.
LC_ALL=C nmcli -t -f SSID,SIGNAL,SECURITY,BAND dev wifi list --rescan "$rescan" 2>/dev/null | while IFS= read -r line; do
    [ -z "$line" ] && continue
    band=$(echo "$line" | rev | cut -d: -f1 | rev)
    security=$(echo "$line" | rev | cut -d: -f2 | rev)
    signal=$(echo "$line" | rev | cut -d: -f3 | rev)
    rest=$(echo "$line" | rev | cut -d: -f4- | rev)
    ssid_raw=$(nm_unescape "$rest")
    [ -z "$ssid_raw" ] && continue
    has_sec=0
    echo "$security" | grep -qiE "wpa|wep" && has_sec=1
    saved=0
    [ "${saved_ssids[$ssid_raw]:-}" = "1" ] && saved=1
    icon=$(signal_icon "$signal" "$saved")
    if [ "$has_sec" = "1" ]; then
        lock=" <span foreground='#eab308'></span>"
    else
        lock=" <span foreground='#94a3b8'></span>"
    fi
    badge=$(band_badge "$band")

    if [ "$ssid_raw" = "$connected_ssid" ]; then
        row="$icon   $ssid_raw$lock $badge <span foreground='#22c55e'>●</span>"
    else
        row="$icon   $ssid_raw$lock $badge"
    fi
    echo -e "$signal\t$row" >> "$raw_file"
    echo "${ssid_raw}|${has_sec}" >> "$sec_file"
done

sort -t$'\t' -k1,1rn "$raw_file" | cut -f2 > "$list_file"

build_menu() {
    local networks
    networks=$(cat "$list_file" 2>/dev/null)
    printf "<span foreground='#f97316'></span>   %s\n" "$(t wifi.scan)"
    if [ -z "$networks" ]; then
        printf "<span foreground='#64748b'>󰤭   %s</span>\n" "$(t wifi.nonetworks)"
    else
        printf "%s\n" "$networks"
    fi
    printf "<span foreground='#94a3b8'></span>   %s\n" "$(t wifi.forget)"
    printf "<span foreground='#94a3b8'>󰀍</span>   %s" "$(t wifi.close)"
}

menu=$(build_menu)

choice=$(echo "$menu" | rofi -dmenu -markup-rows -theme "$theme" -i)
[ -z "$choice" ] && rm -f "$list_file" "$sec_file" "$raw_file" "$saved_file" && exit 0

echo "$choice" | grep -qF "$(t wifi.close)" && rm -f "$list_file" "$sec_file" "$raw_file" "$saved_file" && exit 0

# "Escanear" o el aviso de "Sin redes" siempre fuerzan un escaneo nuevo
# (nunca se intenta conectar a la opción de "Sin redes").
if echo "$choice" | grep -qF "$(t wifi.scan)" || echo "$choice" | grep -qF "$(t wifi.nonetworks)"; then
    nmcli dev wifi rescan 2>/dev/null
    rm -f "$list_file" "$sec_file" "$raw_file" "$saved_file"
    exec "$0" --fresh
fi

# Red conectada -> confirmar desconexión.
# Se desconecta la conexión wifi activa por su nombre real de perfil
# (el perfil puede llamarse distinto que el SSID, p. ej. "OPTI-6303FB-5G 1").
if echo "$choice" | grep -q "●"; then
    ssid=$(echo "$choice" | strip_ssid)
    if confirm "$(tsub wifi.confirm_disconnect "$ssid")"; then
        active_con=$(LC_ALL=C nmcli -t -f TYPE,NAME connection show --active 2>/dev/null | grep '^802-11-wireless:' | cut -d: -f2- | head -1)
        [ -n "$active_con" ] && nmcli con down id "$active_con" 2>/dev/null
    fi
    rm -f "$list_file" "$sec_file" "$raw_file" "$saved_file"
    exit 0
fi

# "Olvidar red..." -> submenú con las redes guardadas para borrar el perfil
# (sirve para volver a pedir la contraseña cuando cambie en el router)
if echo "$choice" | grep -qF "$(t wifi.forget)"; then
    rm -f "$list_file" "$sec_file" "$raw_file"
    forget_menu=$(while IFS='|' read -r fssid fname; do
        printf "%s\n" "$fssid"
    done < "$saved_file" | sort -u | while IFS= read -r fssid; do
        printf "<span foreground='#06b6d4'>󰤨</span>   %s\n" "$fssid"
    done)
    [ -z "$forget_menu" ] && forget_menu="<span foreground='#64748b'>󰤭   $(t wifi.nosaved)</span>"
    fmenu=$(printf "<span foreground='#94a3b8'></span>   %s\n%s\n<span foreground='#94a3b8'>󰀍</span>   %s" "$(t wifi.back)" "$forget_menu" "$(t wifi.close)")
    fchoice=$(echo "$fmenu" | rofi -dmenu -markup-rows -theme "$theme" -i)
    [ -z "$fchoice" ] && rm -f "$saved_file" && exit 0
    echo "$fchoice" | grep -qF "$(t wifi.close)" && rm -f "$saved_file" && exit 0
    if echo "$fchoice" | grep -qF "$(t wifi.back)"; then
        rm -f "$saved_file"
        exec "$0" --fresh
    fi
    fssid=$(echo "$fchoice" | sed 's/<[^>]*>//g' | sed 's/^[^ ]* *//')
    if confirm "$(tsub wifi.confirm_forget "$fssid")"; then
        while IFS='|' read -r s n; do
            [ "$s" = "$fssid" ] && nmcli connection delete "$n" 2>/dev/null
        done < "$saved_file"
        notify-send -i network-wireless "$(t wifi.notif_title)" "$(tsub wifi.forgotten "$fssid")"
    fi
    rm -f "$saved_file"
    exec "$0" --fresh
fi

chosen=$(echo "$choice" | strip_ssid)
[ -z "$chosen" ] && rm -f "$list_file" "$sec_file" "$raw_file" "$saved_file" && exit 0

has_sec=$(grep -F "${chosen}|" "$sec_file" 2>/dev/null | head -1 | cut -d'|' -f2)
is_saved=0
[ "${saved_ssids[$chosen]:-}" = "1" ] && is_saved=1

# Diálogo de contraseña con "ojo" (Alt+1 muestra/oculta, conservando lo escrito).
# Solo si la red es segura Y no está guardada: la guardada ya tiene la contraseña.
password=""
show=0
if [ "$has_sec" = "1" ] && [ "$is_saved" = "0" ]; then
    while :; do
        if [ "$show" = "1" ]; then
            pass_args=()
            eye=""
            filter=(-filter "$password")
        else
            pass_args=(-password)
            eye=""
            filter=()
        fi
        password=$(rofi -dmenu -theme "$theme" \
            -theme-str "window { width: 440px; height: 160px; } mainbox { children: [ message, inputbar ]; } message { enabled: true; text-color: #06b6d4; font: 'JetBrainsMono Nerd Font 12'; padding: 18px 20px 0 20px; } listview { enabled: false; } inputbar { enabled: true; margin: 8px 20px 20px 20px; }" \
            -mesg $'󰖩  '"$chosen"$'\n<span size=\'smaller\' foreground=\'#64748b\'>'"$(t wifi.show_password)"$'</span>' \
            -p "$eye " "${pass_args[@]}" "${filter[@]}" -kb-custom-1 "Alt+1")
        code=$?
        [ "$code" = "10" ] && show=$((1-show)) && continue
        break
    done
    if [ -z "$password" ]; then
        rm -f "$list_file" "$sec_file" "$raw_file" "$saved_file"
        exit 0
    fi
fi

rm -f "$list_file" "$sec_file" "$raw_file" "$saved_file"

if [ "$is_saved" = "1" ]; then
    notify-send -i network-wireless "$(t wifi.notif_title)" "$(tsub wifi.connecting "$chosen")"
    nmcli dev wifi connect "$chosen" 2>/dev/null
    result=$?
elif [ "$has_sec" = "1" ]; then
    notify-send -i network-wireless "$(t wifi.notif_title)" "$(tsub wifi.connecting "$chosen")"
    nmcli dev wifi connect "$chosen" password "$password" 2>/dev/null
    result=$?
else
    notify-send -i network-wireless "$(t wifi.notif_title)" "$(tsub wifi.connecting "$chosen")"
    nmcli dev wifi connect "$chosen" 2>/dev/null
    result=$?
fi

if [ "$result" -eq 0 ]; then
    notify-send -i network-wireless "$(t wifi.notif_title)" "$(tsub wifi.connected "$chosen")"
else
    notify-send -u critical -i network-wireless "$(t wifi.notif_title)" "$(tsub wifi.error "$chosen")"
fi
