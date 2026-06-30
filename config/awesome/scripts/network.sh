#!/bin/bash

theme="$HOME/.config/awesome/theme/network.rasi"

get_icon() {
    local sig=$1
    if   [ "$sig" -ge 80 ]; then echo ""
    elif [ "$sig" -ge 60 ]; then echo ""
    elif [ "$sig" -ge 40 ]; then echo ""
    elif [ "$sig" -ge 20 ]; then echo ""
    else echo ""
    fi
}

build_menu() {
    local connected="$1"
    local list_file="$2"
    local networks

    networks=$(cat "$list_file" 2>/dev/null)
    [ -z "$networks" ] && networks=" No networks found"

    if [ -n "$connected" ]; then
        printf "  %s (Connected)\n Rescan\n%s\n Close" "$connected" "$networks"
    else
        printf " Rescan\n%s\n Close" "$networks"
    fi
}

connected_ssid=$(LC_ALL=C nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes' | head -1 | cut -d: -f2-)

list_file=$(mktemp /tmp/wifi_list.XXXXXX 2>/dev/null) || list_file="/tmp/wifi_list.tmp"
sec_file=$(mktemp /tmp/wifi_sec.XXXXXX 2>/dev/null) || sec_file="/tmp/wifi_sec.tmp"

rm -f "$list_file" "$sec_file"

LC_ALL=C nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null | while IFS= read -r line; do
    [ -z "$line" ] && continue
    ssid_raw=$(echo "$line" | cut -d: -f1)
    signal=$(echo "$line" | cut -d: -f2)
    security=$(echo "$line" | cut -d: -f3-)
    [ -z "$ssid_raw" ] && continue
    has_sec=0
    echo "$security" | grep -qiE "wpa|wep" && has_sec=1
    icon=$(get_icon "$signal")
    lock=""
    [ "$has_sec" = "1" ] && lock=" "
    echo "$icon  $ssid_raw$lock" >> "$list_file"
    echo "${ssid_raw}|${has_sec}" >> "$sec_file"
done

menu=$(build_menu "$connected_ssid" "$list_file")

choice=$(echo "$menu" | rofi -dmenu -theme "$theme")
[ -z "$choice" ] && rm -f "$list_file" "$sec_file" && exit 0

echo "$choice" | grep -q "Close" && rm -f "$list_file" "$sec_file" && exit 0

if echo "$choice" | grep -q "Rescan"; then
    rm -f "$list_file" "$sec_file"
    exec "$0"
fi

if [ -n "$connected_ssid" ] && echo "$choice" | grep -q "(Connected)"; then
    confirm=$(printf "No\nYes" | rofi -dmenu -theme "$theme" -theme-str "inputbar { enabled: true; }" -p "Disconnect $connected_ssid?")
    if [ "$confirm" = "Yes" ]; then
        nmcli con down id "$connected_ssid" 2>/dev/null
    fi
    rm -f "$list_file" "$sec_file"
    exit 0
fi

chosen=$(echo "$choice" | sed 's/^[^ ]*  //' | sed 's/ $//')
[ -z "$chosen" ] && rm -f "$list_file" "$sec_file" && exit 0

has_sec=$(grep -F "${chosen}|" "$sec_file" 2>/dev/null | head -1 | cut -d'|' -f2)

if [ "$has_sec" = "1" ]; then
    password=$(rofi -dmenu -theme "$theme" \
        -theme-str "window { width: 340px; height: 140px; } listview { enabled: false; } inputbar { enabled: true; margin: 20px; children: [textbox-prompt, entry]; } textbox-prompt { text-color: #06b6d4; font: 'JetBrainsMono Nerd Font 10'; padding: 0 10px 0 0; }" \
        -p "Password" -password)
    if [ -z "$password" ]; then
        rm -f "$list_file" "$sec_file"
        exit 0
    fi
    notify-send -i network-wireless "WiFi" "Connecting to $chosen..."
    nmcli dev wifi connect "$chosen" password "$password" 2>/dev/null
    result=$?
else
    notify-send -i network-wireless "WiFi" "Connecting to $chosen..."
    nmcli dev wifi connect "$chosen" 2>/dev/null
    result=$?
fi

rm -f "$list_file" "$sec_file"

if [ "$result" -eq 0 ]; then
    notify-send -i network-wireless "WiFi" "Connected to $chosen"
else
    notify-send -u critical -i network-wireless "WiFi" "Failed to connect to $chosen"
fi
