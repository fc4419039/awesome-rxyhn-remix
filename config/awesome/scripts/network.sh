#!/bin/sh

theme=~/.config/awesome/theme/network.rasi

get_icon() {
    sig=$1
    if [ "$sig" -ge 80 ]; then echo ""
    elif [ "$sig" -ge 60 ]; then echo ""
    elif [ "$sig" -ge 40 ]; then echo ""
    elif [ "$sig" -ge 20 ]; then echo ""
    else echo ""
    fi
}

connected_ssid=$(LC_ALL=C nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes' | head -1 | cut -d: -f2-)

rm -f /tmp/wifi_sec.tmp /tmp/wifi_list.tmp

LC_ALL=C nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null | while IFS=: read -r ssid_raw signal security rest; do
    [ -z "$ssid_raw" ] && continue
    has_sec=0
    echo "$security" | grep -qi "wpa\|wep" && has_sec=1
    icon=$(get_icon "$signal")
    [ "$has_sec" = "1" ] && lock=" " || lock=""
    echo "$icon  $ssid_raw$lock" >> /tmp/wifi_list.tmp
    echo "${ssid_raw}|${has_sec}" >> /tmp/wifi_sec.tmp
done

networks=$(cat /tmp/wifi_list.tmp 2>/dev/null)
[ -z "$networks" ] && networks=" No networks found"

if [ -n "$connected_ssid" ]; then
    menu="  $connected_ssid (Connected)\n Rescan\n$networks\n Close"
    selected=0
else
    menu=" Rescan\n$networks\n Close"
    selected=0
fi

choice=$(printf "%s" "$menu" | rofi -dmenu -theme "$theme" -p "" -selected-row "$selected")
[ -z "$choice" ] && exit 0
echo "$choice" | grep -q "Close" && exit 0

if echo "$choice" | grep -q "Rescan"; then
    exec "$0"
fi

if [ -n "$connected_ssid" ] && echo "$choice" | grep -q "Connected"; then
    confirm=$(printf "No\nYes" | rofi -dmenu -theme "$theme" -theme-str "inputbar { enabled: true; }" -p "Disconnect $connected_ssid?")
    [ "$confirm" = "Yes" ] && nmcli con down id "$connected_ssid" 2>/dev/null
    exit 0
fi

chosen=$(echo "$choice" | sed 's/^[^ ]*  //' | sed 's/ $//')
[ -z "$chosen" ] && exit 0

has_sec=$(grep -F "${chosen}|" /tmp/wifi_sec.tmp 2>/dev/null | head -1 | cut -d'|' -f2)

if [ "$has_sec" = "1" ]; then
    password=$(rofi -dmenu -theme "$theme" -theme-str "inputbar { enabled: true; }" -p "Password" -password)
    [ -z "$password" ] && exit 0
    notify-send -i network-wireless "WiFi" "Connecting to $chosen..."
    nmcli dev wifi connect "$chosen" password "$password" 2>/dev/null
else
    notify-send -i network-wireless "WiFi" "Connecting to $chosen..."
    nmcli dev wifi connect "$chosen" 2>/dev/null
fi

if [ $? -eq 0 ]; then
    notify-send -i network-wireless "WiFi" "Connected to $chosen"
else
    notify-send -u critical -i network-wireless "WiFi" "Failed to connect"
fi
