#!/bin/bash

theme="$HOME/.config/awesome/theme/bluetooth.rasi"

get_status() {
    bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}'
}

get_devices() {
    local devs
    devs=$(bluetoothctl devices 2>/dev/null)
    [ -z "$devs" ] && return

    echo "$devs" | while read -r _ mac rest; do
        local name="${rest}"
        local info
        info=$(bluetoothctl info "$mac" 2>/dev/null)
        local connected
        connected=$(echo "$info" | grep "Connected:" | awk '{print $2}')
        local paired
        paired=$(echo "$info" | grep "Paired:" | awk '{print $2}')
        local icon=""
        [ "$connected" = "yes" ] && icon=""
        local label=""
        [ "$paired" != "yes" ] && label=" (unpaired)"
        echo "$icon $name$label"
    done
}

get_device_mac() {
    local target="$1"
    bluetoothctl devices 2>/dev/null | while read -r _ mac rest; do
        if [ "$rest" = "$target" ]; then
            echo "$mac"
            return 0
        fi
    done
    return 1
}

main_menu() {
    local status
    status=$(get_status)

    if [ "$status" = "yes" ]; then
        printf " Status: On\n Turn Off\n Devices\n Quit"
    else
        printf " Status: Off\n Turn On\n Devices\n Quit"
    fi
}

devices_menu() {
    local devs
    devs=$(get_devices)
    [ -z "$devs" ] && devs=" No devices found"
    printf " Back\n Scan\n Refresh\n%s" "$devs"
}

handle_device_action() {
    local name="$1"
    name=$(echo "$name" | sed 's/^[^ ]* //' | sed 's/ (unpaired)//')
    local mac
    mac=$(get_device_mac "$name")
    [ -z "$mac" ] && return

    local info
    info=$(bluetoothctl info "$mac" 2>/dev/null)
    local connected
    connected=$(echo "$info" | grep "Connected:" | awk '{print $2}')

    if [ "$connected" = "yes" ]; then
        bluetoothctl disconnect "$mac" >/dev/null 2>&1
        notify-send -i bluetooth "Bluetooth" "Disconnected from $name"
    else
        local paired
        paired=$(echo "$info" | grep "Paired:" | awk '{print $2}')
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
}

while true; do
    choice=$(main_menu | rofi -dmenu -theme "$theme")
    [ -z "$choice" ] && exit 0

    case "$choice" in
        *"Turn Off"*)
            bluetoothctl power off >/dev/null 2>&1
            notify-send -i bluetooth "Bluetooth" "Turned off"
            continue
            ;;
        *"Turn On"*)
            rfkill unblock bluetooth >/dev/null 2>&1
            sleep 0.5
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

    while true; do
        choice=$(devices_menu | rofi -dmenu -theme "$theme")
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

        handle_device_action "$choice"
    done
done
