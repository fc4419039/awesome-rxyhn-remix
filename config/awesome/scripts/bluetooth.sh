#!/bin/sh

theme=~/.config/awesome/theme/bluetooth.rasi

get_status() {
    result=$(bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}')
    echo "${result:-off}"
}

get_devices() {
    bluetoothctl devices | while read -r _ mac rest; do
        name="${rest## }"
        info=$(bluetoothctl info "$mac" 2>/dev/null)
        paired=$(echo "$info" | grep "Paired:" | awk '{print $2}')
        connected=$(echo "$info" | grep "Connected:" | awk '{print $2}')
        icon=""
        [ "$connected" = "yes" ] && icon=""
        label=""
        [ "$paired" != "yes" ] && label=" (unpaired)"
        echo "$icon $name$label"
    done
}

while true; do
    status=$(get_status)

    # Main menu
    if [ "$status" = "yes" ]; then
        menu=" Status: On\nﴛ Turn Off\n料 Devices\n Quit"
    else
        menu=" Status: Off\nﴜ Turn On\n料 Devices\n Quit"
    fi

    choice=$(printf "$menu" | rofi -dmenu -theme "$theme")
    [ -z "$choice" ] && exit 0

    case "$choice" in
        *"Turn Off"*)
            bluetoothctl power off >/dev/null 2>&1
            notify-send -i bluetooth "Bluetooth" "Turned off"
            continue
            ;;
        *"Turn On"*)
            bluetoothctl power on >/dev/null 2>&1
            bluetoothctl agent on >/dev/null 2>&1
            bluetoothctl default-agent >/dev/null 2>&1
            notify-send -i bluetooth "Bluetooth" "Turned on"
            continue
            ;;
        *"Devices"*)
            ;;
        *)
            exit 0
            ;;
    esac

    # Devices menu
    while true; do
        devices=$(get_devices)
        [ -z "$devices" ] && devices=" No devices found"

        choice=$(printf " Back\n Scan\n Refresh\n%s" "$devices" | rofi -dmenu -theme "$theme")
        [ -z "$choice" ] && exit 0

        case "$choice" in
            " Back")
                break
                ;;
            " Scan")
                notify-send -i bluetooth "Bluetooth" "Scanning for 8 seconds..."
                bluetoothctl --timeout 8 scan on >/dev/null 2>&1
                notify-send -i bluetooth "Bluetooth" "Scan complete"
                continue
                ;;
            " Refresh")
                continue
                ;;
        esac

        name=$(echo "$choice" | sed 's/^[^ ]* //' | sed 's/ (unpaired)//')
        mac=$(bluetoothctl devices | awk -v n="$name" '{
            s=""; for(i=3;i<=NF;i++) s=s? s OFS $i: $i;
            if(s==n) print $2
        }')

        if [ -n "$mac" ]; then
            connected=$(bluetoothctl info "$mac" 2>/dev/null | grep "Connected:" | awk '{print $2}')
            if [ "$connected" = "yes" ]; then
                bluetoothctl disconnect "$mac" >/dev/null 2>&1
                notify-send -i bluetooth "Bluetooth" "Disconnected from $name"
            else
                paired=$(bluetoothctl info "$mac" 2>/dev/null | grep "Paired:" | awk '{print $2}')
                if [ "$paired" != "yes" ]; then
                    notify-send -i bluetooth "Bluetooth" "Pairing with $name..."
                    bluetoothctl agent on >/dev/null 2>&1
                    bluetoothctl default-agent >/dev/null 2>&1
                    bluetoothctl pair "$mac" >/dev/null 2>&1
                fi
                bluetoothctl trust "$mac" >/dev/null 2>&1
                notify-send -i bluetooth "Bluetooth" "Connecting to $name..."
                if bluetoothctl connect "$mac" >/dev/null 2>&1; then
                    notify-send -i bluetooth "Bluetooth" "Connected to $name"
                else
                    notify-send -u critical -i bluetooth "Bluetooth" "Failed to connect to $name"
                fi
            fi
        fi
    done
done
