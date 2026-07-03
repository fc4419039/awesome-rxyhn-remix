#!/bin/bash

theme="$HOME/.config/awesome/theme/network.rasi"
confirm_theme="$HOME/.config/awesome/theme/powermenu-confirm.rasi"

signal_icon() {
    local sig=$1
    if   [ "$sig" -ge 80 ]; then echo "<span foreground='#22c55e'>󰤨</span>"
    elif [ "$sig" -ge 60 ]; then echo "<span foreground='#06b6d4'>󰤥</span>"
    elif [ "$sig" -ge 40 ]; then echo "<span foreground='#eab308'>󰤢</span>"
    elif [ "$sig" -ge 20 ]; then echo "<span foreground='#f97316'>󰤟</span>"
    else echo "<span foreground='#ef4444'>󰤫</span>"
    fi
}

connected_ssid=$(LC_ALL=C nmcli -t -f ACTIVE,SSID dev wifi list --rescan no 2>/dev/null | grep '^yes' | head -1 | cut -d: -f2-)

list_file=$(mktemp /tmp/wifi_list.XXXXXX 2>/dev/null) || list_file="/tmp/wifi_list.tmp"
sec_file=$(mktemp /tmp/wifi_sec.XXXXXX 2>/dev/null) || sec_file="/tmp/wifi_sec.tmp"

rm -f "$list_file" "$sec_file"

LC_ALL=C nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list --rescan no 2>/dev/null | while IFS= read -r line; do
    [ -z "$line" ] && continue
    ssid_raw=$(echo "$line" | cut -d: -f1)
    signal=$(echo "$line" | cut -d: -f2)
    security=$(echo "$line" | cut -d: -f3-)
    [ -z "$ssid_raw" ] && continue
    has_sec=0
    echo "$security" | grep -qiE "wpa|wep" && has_sec=1
    icon=$(signal_icon "$signal")
    lock=""
    [ "$has_sec" = "1" ] && lock=" <span foreground='#eab308'></span>"

    if [ "$ssid_raw" = "$connected_ssid" ]; then
        echo "$icon   $ssid_raw$lock <span foreground='#22c55e'>●</span>" >> "$list_file"
    else
        echo "$icon   $ssid_raw$lock" >> "$list_file"
    fi
    echo "${ssid_raw}|${has_sec}" >> "$sec_file"
done

build_menu() {
    local connected="$1"
    local list_file="$2"
    local networks

    networks=$(cat "$list_file" 2>/dev/null)
    [ -z "$networks" ] && networks="<span foreground='#64748b'>󰤭   Sin redes</span>"

    printf "<span foreground='#f97316'></span>   Escanear\n"
    printf "%s\n" "$networks"
    printf "<span foreground='#94a3b8'></span>   Cerrar"
}

menu=$(build_menu "$connected_ssid" "$list_file")

choice=$(echo "$menu" | rofi -dmenu -markup-rows -theme "$theme")
[ -z "$choice" ] && rm -f "$list_file" "$sec_file" && exit 0

echo "$choice" | grep -q "Cerrar" && rm -f "$list_file" "$sec_file" && exit 0

if echo "$choice" | grep -q "Escanear"; then
    nmcli dev wifi rescan 2>/dev/null &
    rm -f "$list_file" "$sec_file"
    exec "$0"
fi

if echo "$choice" | grep -q "●"; then
    ssid=$(echo "$choice" | sed 's/<[^>]*>//g' | sed 's/^[^ ]* *//' | sed 's/ *$//' | sed 's/ ●$//')
    ans=$(printf "󰄰 No\n󰄱 Si" | rofi -dmenu -theme "$confirm_theme" -mesg "Desconectar $ssid?" -selected-row 0)
    if [ "$ans" = "󰄱 Si" ]; then
        nmcli con down id "$ssid" 2>/dev/null
    fi
    rm -f "$list_file" "$sec_file"
    exit 0
fi

chosen=$(echo "$choice" | sed 's/<[^>]*>//g' | sed 's/^[^ ]* *//' | sed 's/ *$//')
[ -z "$chosen" ] && rm -f "$list_file" "$sec_file" && exit 0

has_sec=$(grep -F "${chosen}|" "$sec_file" 2>/dev/null | head -1 | cut -d'|' -f2)

if [ "$has_sec" = "1" ]; then
    password=$(rofi -dmenu -theme "$theme" \
        -theme-str "window { width: 340px; height: 140px; } mainbox { children: [message, inputbar]; } message { enabled: true; text-color: #06b6d4; font: 'JetBrainsMono Nerd Font Bold 12'; padding: 20px 20px 0 20px; } listview { enabled: false; } inputbar { enabled: true; margin: 10px 20px 20px 20px; }" \
        -mesg "Contraseña" -p "" -password)
    if [ -z "$password" ]; then
        rm -f "$list_file" "$sec_file"
        exit 0
    fi
    notify-send -i network-wireless "WiFi" "Conectando a $chosen..."
    nmcli dev wifi connect "$chosen" password "$password" 2>/dev/null
    result=$?
else
    notify-send -i network-wireless "WiFi" "Conectando a $chosen..."
    nmcli dev wifi connect "$chosen" 2>/dev/null
    result=$?
fi

rm -f "$list_file" "$sec_file"

if [ "$result" -eq 0 ]; then
    notify-send -i network-wireless "WiFi" "Conectado a $chosen"
else
    notify-send -u critical -i network-wireless "WiFi" "Error al conectar a $chosen"
fi
