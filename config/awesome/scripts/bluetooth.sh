#!/bin/bash

source "$HOME/.config/awesome/scripts/i18n.sh"

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

        if [ "$connected" = "yes" ]; then
            echo "<span foreground='#22c55e'>󰂱</span>   $name"
        elif [ "$paired" = "yes" ]; then
            echo "<span foreground='#94a3b8'>󰂲</span>   $name"
        else
            echo "<span foreground='#64748b'>󰂲</span>   $name <span foreground='#64748b'>$(t bl.unpaired)</span>"
        fi
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
        printf "<span foreground='#22c55e'>󰂯</span>   %s\n" "$(t bl.powered)"
        printf "<span foreground='#ef4444'></span>   %s\n" "$(t bl.power_off)"
    else
        printf "<span foreground='#ef4444'>󰂲</span>   %s\n" "$(t bl.powered_off)"
        printf "<span foreground='#22c55e'></span>   %s\n" "$(t bl.power_on)"
    fi
    printf "<span foreground='#06b6d4'>󰂰</span>   %s\n" "$(t bl.devices)"
    printf "<span foreground='#94a3b8'></span>   %s" "$(t bl.exit)"
}

devices_menu() {
    local devs
    devs=$(get_devices)
    [ -z "$devs" ] && devs="<span foreground='#64748b'>   $(t bl.no_devices)</span>"
    printf "<span foreground='#f97316'></span>   %s\n" "$(t bl.back)"
    printf "<span foreground='#3b82f6'>󰍉</span>   %s\n" "$(t bl.scan)"
    printf "<span foreground='#a855f7'></span>   %s\n" "$(t bl.refresh)"
    printf "%s\n" "$devs"
}

handle_device_action() {
    local name="$1"
    name=$(echo "$name" | sed 's/.*   //' | sed 's/ <.*//')
    local mac
    mac=$(get_device_mac "$name")
    [ -z "$mac" ] && return

    local info
    info=$(bluetoothctl info "$mac" 2>/dev/null)
    local connected
    connected=$(echo "$info" | grep "Connected:" | awk '{print $2}')

    if [ "$connected" = "yes" ]; then
        bluetoothctl disconnect "$mac" >/dev/null 2>&1
        notify-send -i bluetooth "$(t bl.title)" "$(tsub bl.disconnected "$name")"
    else
        local paired
        paired=$(echo "$info" | grep "Paired:" | awk '{print $2}')
        if [ "$paired" != "yes" ]; then
            notify-send -i bluetooth "$(t bl.title)" "$(tsub bl.pairing "$name")"
            bluetoothctl agent on >/dev/null 2>&1
            bluetoothctl default-agent >/dev/null 2>&1
            bluetoothctl pair "$mac" >/dev/null 2>&1
        fi
        bluetoothctl trust "$mac" >/dev/null 2>&1
        notify-send -i bluetooth "$(t bl.title)" "$(tsub bl.connecting "$name")"
        if bluetoothctl connect "$mac" >/dev/null 2>&1; then
            notify-send -i bluetooth "$(t bl.title)" "$(tsub bl.connected "$name")"
        else
            notify-send -u critical -i bluetooth "$(t bl.title)" "$(tsub bl.connect_failed "$name")"
        fi
    fi
}

while true; do
    choice=$(main_menu | rofi -dmenu -markup-rows -theme "$theme")
    [ -z "$choice" ] && exit 0

    case "$choice" in
        *"$(t bl.power_off)"*)
            bluetoothctl power off >/dev/null 2>&1
            notify-send -i bluetooth "$(t bl.title)" "$(t bl.powered_off)"
            continue
            ;;
        *"$(t bl.power_on)"*)
            rfkill unblock bluetooth >/dev/null 2>&1
            sleep 0.5
            bluetoothctl power on >/dev/null 2>&1
            bluetoothctl agent on >/dev/null 2>&1
            bluetoothctl default-agent >/dev/null 2>&1
            notify-send -i bluetooth "$(t bl.title)" "$(t bl.powered)"
            continue
            ;;
        *"$(t bl.devices)"*)
            ;;
        *)
            exit 0
            ;;
    esac

    while true; do
        choice=$(devices_menu | rofi -dmenu -markup-rows -theme "$theme")
        [ -z "$choice" ] && exit 0

        case "$choice" in
            *"$(t bl.back)"*)
                break
                ;;
            *"$(t bl.scan)"*)
                notify-send -i bluetooth "$(t bl.title)" "$(t bl.scanning)"
                bluetoothctl --timeout 8 scan on >/dev/null 2>&1
                notify-send -i bluetooth "$(t bl.title)" "$(t bl.scan_done)"
                continue
                ;;
            *"$(t bl.refresh)"*)
                continue
                ;;
        esac

        handle_device_action "$choice"
    done
done
