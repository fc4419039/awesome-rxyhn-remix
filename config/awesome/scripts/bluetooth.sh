#!/bin/bash
# Menú Bluetooth para rofi.
#  - Estado de energía y descubrimiento del adaptador
#  - Lista de dispositivos con icono de tipo, estado de conexión y batería
#  - Acciones según el tipo: enviar archivos (teléfono/OBEX), salida de
#    audio y micrófono (audio), conectar/desconectar, olvidar dispositivo.
# Graceful degradation: si faltan dependencias, muestra warnings pero no crashea.

# Verificar dependencias críticas al inicio
check_deps() {
    local missing=()
    command -v bluetoothctl >/dev/null 2>&1 || missing+=("bluez/bluez-utils")
    command -v rofi >/dev/null 2>&1 || missing+=("rofi")
    command -v pactl >/dev/null 2>&1 || missing+=("libpulse/pipewire-pulse")
    command -v notify-send >/dev/null 2>&1 || missing+=("libnotify")
    
    # Opcionales
    BLUEMAN_AVAILABLE=false
    OBEXD_AVAILABLE=false
    UPOWER_AVAILABLE=false
    command -v blueman-sendto >/dev/null 2>&1 && BLUEMAN_AVAILABLE=true
    command -v obexd >/dev/null 2>&1 || [ -x /usr/lib/bluetooth/obexd ] || [ -x /usr/libexec/bluetooth/obexd ] && OBEXD_AVAILABLE=true
    command -v upower >/dev/null 2>&1 && UPOWER_AVAILABLE=true
    
    if [ ${#missing[@]} -gt 0 ]; then
        notify-send -u critical "Bluetooth" "Faltan deps críticas: ${missing[*]}. Instálalas para usar el menú." 2>/dev/null || true
        # No exit - leave menu to show error state
    fi
}
check_deps

source "$HOME/.config/awesome/scripts/i18n.sh"

theme="$HOME/.config/awesome/theme/bluetooth.rasi"
confirm_theme="$HOME/.config/awesome/theme/powermenu-confirm.rasi"

# ─── Iconos (Nerd Font) ───
ICON_BT="󰂯"; ICON_BT_AUDIO="󰂰"; ICON_BT_CONNECT="󰂱"; ICON_BT_OFF="󰂲"
ICON_PHONE="󰄜"; ICON_HEADPHONES="󰋋"; ICON_SPEAKER="󰓃"; ICON_COMPUTER="󰌢"
ICON_KEYBOARD="󰌌"; ICON_MOUSE="󰍽"; ICON_WATCH="󰖉"; ICON_GAMEPAD="󰊖"
ICON_DEVICE="󰂯"
ICON_BACK="󰁍"; ICON_SCAN="󰍉"; ICON_REFRESH="󰑐"; ICON_EXIT="󰈆"
ICON_DEVICES="󰾰"; ICON_SEND="󰈪"; ICON_TRASH="󰩹"
ICON_SINK="󰕾"; ICON_SOURCE="󰍬"
ICON_TOGGLE_ON="󰔡"; ICON_TOGGLE_OFF="󰔢"

# ─── Colores ───
GREEN="#22c55e"; RED="#ef4444"; SLATE="#94a3b8"; DARK="#64748b"
CYAN="#06b6d4"; AMBER="#eab308"; ORANGE="#f97316"; PURPLE="#a855f7"

confirm() {
    local msg="$1" ans
    ans=$(printf "󰄬 %s\n󰅖 %s" "$(t pm.no "No")" "$(t pm.yes "Si")" | rofi -dmenu -theme "$confirm_theme" -mesg "$msg" -selected-row 0)
    [ "$ans" = "󰅖 $(t pm.yes "Si")" ]
}

get_powered() {
    bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2; exit}'
}

get_discoverable() {
    bluetoothctl show 2>/dev/null | awk '/Discoverable:/{print $2; exit}'
}

xml_escape() {
    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

class_num() {
    local c="${1#0x}"
    [[ "$c" =~ ^[0-9a-fA-F]+$ ]] && echo "$((16#$c))" || echo 0
}

class_major() {
    echo "$(( ($(class_num "$1") >> 8) & 0x1f ))"
}

class_minor() {
    echo "$(( ($(class_num "$1") >> 2) & 0x3f ))"
}

# Icono según el tipo de dispositivo (Icon de bluetoothctl + clase)
device_icon() {
    local icon="$1" class="$2" major minor
    case "$icon" in
        phone)                echo "$ICON_PHONE"; return ;;
        computer)             echo "$ICON_COMPUTER"; return ;;
        input-keyboard)       echo "$ICON_KEYBOARD"; return ;;
        input-mouse)          echo "$ICON_MOUSE"; return ;;
        input-gaming)         echo "$ICON_GAMEPAD"; return ;;
        input-*)              echo "$ICON_KEYBOARD"; return ;;
        audio-card|audio-headset|audio-headphones|audio-speaker)
            minor=$(class_minor "$class")
            case "$minor" in
                12|20|24) echo "$ICON_SPEAKER" ;;
                *)        echo "$ICON_HEADPHONES" ;;
            esac
            return ;;
    esac
    major=$(class_major "$class")
    minor=$(class_minor "$class")
    case "$major" in
        1) echo "$ICON_COMPUTER" ;;
        2) echo "$ICON_PHONE" ;;
        4) case "$minor" in
               12|20|24) echo "$ICON_SPEAKER" ;;
               *)        echo "$ICON_HEADPHONES" ;;
           esac ;;
        5) echo "$ICON_KEYBOARD" ;;
        7) echo "$ICON_WATCH" ;;
        8) echo "$ICON_GAMEPAD" ;;
        *) echo "$ICON_DEVICE" ;;
    esac
}

device_type_label() {
    local icon="$1" class="$2" major
    case "$icon" in
        phone)      echo "$(t bl.type_phone)"; return ;;
        computer)   echo "$(t bl.type_computer)"; return ;;
        input-*)    echo "$(t bl.type_input)"; return ;;
        audio-card|audio-headset|audio-headphones) echo "$(t bl.type_audio)"; return ;;
    esac
    major=$(class_major "$class")
    case "$major" in
        1) echo "$(t bl.type_computer)" ;;
        2) echo "$(t bl.type_phone)" ;;
        4) echo "$(t bl.type_audio)" ;;
        5) echo "$(t bl.type_input)" ;;
        *) echo "$(t bl.type_unknown)" ;;
    esac
}

# true si la cadena parece una dirección MAC (p. ej. "65-40-52-1C-89-8B")
is_mac_like() {
    [[ "$1" =~ ^[0-9A-Fa-f]{2}([:-][0-9A-Fa-f]{2}){5}$ ]]
}

# Nombre amable para mostrar: si BlueZ no resolvió un nombre real, usa
# "Dispositivo desconocido" en vez de la MAC cruda.
display_name() {
    local raw="$1"
    if is_mac_like "$raw"; then
        printf '%s' "$(t bl.unnamed)"
    else
        printf '%s' "$raw"
    fi
}

supports_obex() {
    echo "$1" | grep -qi "00001105-0000-1000-8000-00805f9b34fb" || \
    echo "$1" | grep -qi "OBEX Object Push"
}

supports_audio() {
    local info="$1" class="$2" major
    major=$(class_major "$class")
    [ "$major" = "4" ] && return 0
    case "$info" in
        *"Audio Sink"*|*"Audio Source"*|*"Headset"*|*"A/V Remote Control"*) return 0 ;;
    esac
    return 1
}

# Batería de un dispositivo Bluetooth a través de upower
battery_level() {
    [ "$UPOWER_AVAILABLE" = true ] || return 1
    local mac="$1" dev addr pct
    while IFS= read -r dev; do
        case "$dev" in
            *"/bluetooth"*|*"_dev_"*) ;;
            *) continue ;;
        esac
        addr=${dev##*_dev_}
        addr=${addr//_/:}
        [[ "${addr,,}" == "${mac,,}" ]] || continue
        pct=$(upower -i "$dev" 2>/dev/null | awk '/percentage:/{gsub(/[^0-9]/, "", $2); print $2; exit}')
        [[ -n "$pct" ]] && { echo "$pct"; return 0; }
    done < <(upower -e 2>/dev/null)
    return 1
}

battery_icon() {
    local p=$1
    if   [ "$p" -ge 90 ]; then echo "󰂂"
    elif [ "$p" -ge 80 ]; then echo "󰂁"
    elif [ "$p" -ge 70 ]; then echo "󰂀"
    elif [ "$p" -ge 60 ]; then echo "󰁿"
    elif [ "$p" -ge 50 ]; then echo "󰁾"
    elif [ "$p" -ge 40 ]; then echo "󰁽"
    elif [ "$p" -ge 30 ]; then echo "󰁼"
    elif [ "$p" -ge 20 ]; then echo "󰁻"
    else echo "󰁺"; fi
}

battery_color() {
    local p=$1
    if   [ "$p" -ge 60 ]; then echo "$GREEN"
    elif [ "$p" -ge 30 ]; then echo "$AMBER"
    else echo "$RED"; fi
}

# Sink/source de PulseAudio/PipeWire que coincide con el alias del dispositivo
pactl_sink_for() {
    local alias="$1" sname="" sdesc="" line
    while IFS= read -r line; do
        case "$line" in
            "Sink #"*) sname="" ;;
            $'\t'Name:*) sname=${line#$'\t'Name: } ;;
            $'\t'Description:*)
                sdesc=${line#$'\t'Description: }
                if [ -n "$sname" ] && [[ "$sdesc" == *"$alias"* ]]; then
                    echo "$sname"; return 0
                fi
                ;;
        esac
    done < <(pactl list sinks 2>/dev/null)
    return 1
}

pactl_source_for() {
    local alias="$1" sname="" sdesc="" line
    while IFS= read -r line; do
        case "$line" in
            "Source #"*) sname="" ;;
            $'\t'Name:*) sname=${line#$'\t'Name: } ;;
            $'\t'Description:*)
                sdesc=${line#$'\t'Description: }
                if [ -n "$sname" ] && [[ "$sdesc" == *"$alias"* ]]; then
                    echo "$sname"; return 0
                fi
                ;;
        esac
    done < <(pactl list sources 2>/dev/null)
    return 1
}

# ─── Construcción de menús ───

map_file=$(mktemp /tmp/bt_map.XXXXXX 2>/dev/null) || map_file="/tmp/bt_map.tmp"
trap 'rm -f "$map_file"' EXIT

build_device_rows() {
    while read -r _ mac rest; do
        [ -z "$mac" ] && continue
        local name="${rest}" info connected paired icon class
        info=$(bluetoothctl info "$mac" 2>/dev/null)
        # `bluetoothctl devices` muestra el alias; prefiere el Name real si existe
        local realname
        realname=$(awk '/^[[:space:]]*Name:/{sub(/^[[:space:]]*Name:[[:space:]]*/, ""); print; exit}' <<<"$info")
        [ -n "$realname" ] && ! is_mac_like "$realname" && name="$realname"
        connected=$(awk '/Connected:/{print $2; exit}' <<<"$info")
        paired=$(awk '/Paired:/{print $2; exit}' <<<"$info")
        icon=$(awk '/Icon:/{print $2; exit}' <<<"$info")
        class=$(awk '/Class:/{print $2; exit}' <<<"$info")

        local ticon color row="" b=""
        ticon=$(device_icon "$icon" "$class")
        if [ "$connected" = "yes" ]; then
            color="$GREEN"
            local bp
            bp=$(battery_level "$mac")
            [ -n "$bp" ] && b="  <span foreground='$(battery_color "$bp")'>$(battery_icon "$bp") $bp%</span>"
        elif [ "$paired" = "yes" ]; then
            color="$SLATE"
        else
            color="$DARK"
        fi

        local ename dname
        dname=$(display_name "$name")
        ename=$(printf '%s' "$dname" | xml_escape)
        if [ "$dname" != "$name" ]; then
            ename="$ename <span foreground='$DARK'>$mac</span>"
        fi
        row="<span foreground='$color'>$ticon</span>   $ename$b"
        [ "$connected" = "yes" ] && row="$row <span foreground='$GREEN'>●</span>"
        [ "$paired" != "yes" ] && row="$row <span foreground='$DARK'>$(t bl.unpaired)</span>"
        printf '%s\t%s\t%s\n' "$row" "$mac" "$name" >> "$map_file"
    done < <(bluetoothctl devices 2>/dev/null)
}

main_menu() {
    if [ "$(get_powered)" = "yes" ]; then
        printf "<span foreground='%s'>%s</span>   %s\n" "$GREEN" "$ICON_BT" "$(t bl.power_off)"
    else
        printf "<span foreground='%s'>%s</span>   %s\n" "$SLATE" "$ICON_BT_OFF" "$(t bl.power_on)"
    fi
    printf "<span foreground='%s'>%s</span>   %s\n" "$CYAN" "$ICON_DEVICES" "$(t bl.devices)"
    if [ "$(get_discoverable)" = "yes" ]; then
        printf "<span foreground='%s'>%s</span>   %s\n" "$AMBER" "$ICON_TOGGLE_ON" "$(t bl.discoverable_on)"
    else
        printf "<span foreground='%s'>%s</span>   %s\n" "$SLATE" "$ICON_TOGGLE_OFF" "$(t bl.discoverable_off)"
    fi
    printf "<span foreground='%s'>%s</span>   %s" "$SLATE" "$ICON_EXIT" "$(t bl.exit)"
}

devices_menu() {
    printf "<span foreground='%s'>%s</span>   %s\n" "$ORANGE" "$ICON_BACK" "$(t bl.back)"
    printf "<span foreground='%s'>%s</span>   %s\n" "$CYAN" "$ICON_SCAN" "$(t bl.scan)"
    printf "<span foreground='%s'>%s</span>   %s\n" "$PURPLE" "$ICON_REFRESH" "$(t bl.refresh)"
    local rows
    rows=$(cut -f1 "$map_file")
    if [ -z "$rows" ]; then
        printf "<span foreground='%s'>%s   %s</span>\n" "$DARK" "$ICON_DEVICE" "$(t bl.no_devices)"
    else
        printf '%s\n' "$rows"
    fi
    printf "<span foreground='%s'>%s</span>   %s" "$SLATE" "$ICON_EXIT" "$(t bl.exit)"
}

# Menú de acciones de un dispositivo (con cabecera de información)
device_menu() {
    local mac="$1" name="$2"
    local info connected paired icon class ticon tlabel header ename bp
    info=$(bluetoothctl info "$mac" 2>/dev/null)
    connected=$(awk '/Connected:/{print $2; exit}' <<<"$info")
    paired=$(awk '/Paired:/{print $2; exit}' <<<"$info")
    icon=$(awk '/Icon:/{print $2; exit}' <<<"$info")
    class=$(awk '/Class:/{print $2; exit}' <<<"$info")

    ticon=$(device_icon "$icon" "$class")
    tlabel=$(device_type_label "$icon" "$class")
    ename=$(printf '%s' "$(display_name "$name")" | xml_escape)

    header="$ticon  $ename"
    bp=$(battery_level "$mac")
    [ -n "$bp" ] && header="$header  ·  <span foreground='$(battery_color "$bp")'>$(battery_icon "$bp") $bp%</span>"
    header="$header  ·  $tlabel"

    local rows=()
    if [ "$connected" = "yes" ]; then
        rows+=("<span foreground='$RED'>$ICON_BT_OFF</span>   $(t bl.disconnect)")
        if [ "$paired" = "yes" ] && supports_obex "$info"; then
            rows+=("<span foreground='$CYAN'>$ICON_SEND</span>   $(t bl.send_file)")
        fi
        if supports_audio "$info" "$class"; then
            local sink src
            if [ -n "$name" ]; then
                sink=$(pactl_sink_for "$name")
                src=$(pactl_source_for "$name")
            fi
            [ -n "$sink" ] && rows+=("<span foreground='$GREEN'>$ICON_SINK</span>   $(t bl.sink)")
            [ -n "$src" ] && rows+=("<span foreground='$GREEN'>$ICON_SOURCE</span>   $(t bl.source)")
        fi
    else
        rows+=("<span foreground='$GREEN'>$ICON_BT_CONNECT</span>   $(t bl.connect)")
        if [ "$paired" = "yes" ] && supports_obex "$info"; then
            rows+=("<span foreground='$CYAN'>$ICON_SEND</span>   $(t bl.send_file)")
        fi
    fi
    rows+=("<span foreground='$ORANGE'>$ICON_TRASH</span>   $(t bl.forget)")
    rows+=("<span foreground='$SLATE'>$ICON_BACK</span>   $(t bl.back)")

    printf '%s\n' "${rows[@]}" | rofi -dmenu -markup-rows -theme "$theme" \
        -theme-str "window { height: 460px; } mainbox { children: [ message, listview ]; } message { enabled: true; padding: 16px 20px 6px 20px; horizontal-align: 0.5; text-color: #cbd5e1; font: 'JetBrainsMono Nerd Font 11'; } listview { padding: 6px 14px 14px 14px; }" \
        -mesg "$header"
}

# ─── Acciones ───

# Garantiza un agente de emparejamiento automático activo
ensure_agent() {
    if ! pgrep -f 'bt_agent.py' >/dev/null 2>&1; then
        setsid "$HOME/.config/awesome/scripts/bt_agent.py" >/dev/null 2>&1 &
        sleep 0.5
    fi
}

toggle_power() {
    if [ "$(get_powered)" = "yes" ]; then
        bluetoothctl power off >/dev/null 2>&1
        notify-send -i bluetooth "$(t bl.title)" "$(t bl.off)"
    else
        rfkill unblock bluetooth >/dev/null 2>&1
        sleep 0.3
        bluetoothctl power on >/dev/null 2>&1
        ensure_agent
        notify-send -i bluetooth "$(t bl.title)" "$(t bl.on)"
    fi
}

toggle_discoverable() {
    if [ "$(get_discoverable)" = "yes" ]; then
        bluetoothctl discoverable off >/dev/null 2>&1
        bluetoothctl pairable off >/dev/null 2>&1
        notify-send -i bluetooth "$(t bl.title)" "$(t bl.discoverable_off)"
    else
        bluetoothctl discoverable on >/dev/null 2>&1
        bluetoothctl pairable on >/dev/null 2>&1
        notify-send -i bluetooth "$(t bl.title)" "$(t bl.discoverable_on)"
    fi
}

do_scan() {
    notify-send -i bluetooth "$(t bl.title)" "$(t bl.scanning)"
    bluetoothctl --timeout 8 scan on >/dev/null 2>&1
    notify-send -i bluetooth "$(t bl.title)" "$(t bl.scan_done)"
}

connect_device() {
    local mac="$1" name="$2" info paired
    info=$(bluetoothctl info "$mac" 2>/dev/null)
    paired=$(awk '/Paired:/{print $2; exit}' <<<"$info")
    if [ "$paired" != "yes" ]; then
        notify-send -i bluetooth "$(t bl.title)" "$(tsub bl.pairing "$name")"
        ensure_agent
        bluetoothctl pair "$mac" >/dev/null 2>&1
    fi
    bluetoothctl trust "$mac" >/dev/null 2>&1
    notify-send -i bluetooth "$(t bl.title)" "$(tsub bl.connecting "$name")"
    if bluetoothctl connect "$mac" >/dev/null 2>&1; then
        notify-send -i bluetooth "$(t bl.title)" "$(tsub bl.connected "$name")"
    else
        notify-send -u critical -i bluetooth "$(t bl.title)" "$(tsub bl.connect_failed "$name")"
    fi
}

disconnect_device() {
    bluetoothctl disconnect "$1" >/dev/null 2>&1
    notify-send -i bluetooth "$(t bl.title)" "$(tsub bl.disconnected "$2")"
}

forget_device() {
    local mac="$1" name="$2"
    if confirm "$(tsub bl.forget_confirm "$name")"; then
        bluetoothctl remove "$mac" >/dev/null 2>&1
        notify-send -i bluetooth "$(t bl.title)" "$(tsub bl.forgotten "$name")"
    fi
}

send_file() {
    local mac="$1" name="$2"
    if [ "$OBEXD_AVAILABLE" = true ] || [ "$BLUEMAN_AVAILABLE" = true ]; then
        notify-send -i bluetooth "$(t bl.title)" "$(tsub bl.sending "$name")" 2>/dev/null || true
        blueman-sendto -d "$mac" >/dev/null 2>&1 || true
    else
        notify-send -i bluetooth "$(t bl.title)" "$(t bl.need_obex)" 2>/dev/null || true
    fi
}

set_sink() {
    local name="$1" sink
    sink=$(pactl_sink_for "$name")
    if [ -n "$sink" ]; then
        pactl set-default-sink "$sink" 2>/dev/null
        pactl list short sink-inputs 2>/dev/null | cut -f1 | while read -r i; do
            pactl move-sink-input "$i" "$sink" 2>/dev/null
        done
        notify-send -i audio-headphones "$(t bl.title)" "$(tsub bl.sink_set "$name")"
    else
        notify-send -i audio-headphones "$(t bl.title)" "$(t bl.no_sink)"
    fi
}

set_source() {
    local name="$1" src
    src=$(pactl_source_for "$name")
    if [ -n "$src" ]; then
        pactl set-default-source "$src" 2>/dev/null
        notify-send -i audio-input-microphone "$(t bl.title)" "$(tsub bl.source_set "$name")"
    else
        notify-send -i audio-input-microphone "$(t bl.title)" "$(t bl.no_source)"
    fi
}

# ─── Flujo principal ───

while true; do
    choice=$(main_menu | rofi -dmenu -markup-rows -theme "$theme" -theme-str "window { height: 250px; }" -i)
    [ -z "$choice" ] && exit 0
    echo "$choice" | grep -qF "$(t bl.exit)" && exit 0

    if echo "$choice" | grep -qF "$(t bl.power_off)" || echo "$choice" | grep -qF "$(t bl.power_on)"; then
        toggle_power
        continue
    fi
    if echo "$choice" | grep -qF "$(t bl.discoverable_on)" || echo "$choice" | grep -qF "$(t bl.discoverable_off)"; then
        toggle_discoverable
        continue
    fi
    if ! echo "$choice" | grep -qF "$(t bl.devices)"; then
        continue
    fi

    # Menú de dispositivos
    while true; do
        : > "$map_file"
        build_device_rows
        choice=$(devices_menu | rofi -dmenu -markup-rows -theme "$theme" -i)
        [ -z "$choice" ] && exit 0
        echo "$choice" | grep -qF "$(t bl.exit)" && exit 0
        echo "$choice" | grep -qF "$(t bl.back)" && break
        echo "$choice" | grep -qF "$(t bl.scan)" && { do_scan; continue; }
        echo "$choice" | grep -qF "$(t bl.refresh)" && continue
        echo "$choice" | grep -qF "$(t bl.no_devices)" && continue

        line=$(grep -F "$choice" "$map_file" | head -1)
        mac=$(echo "$line" | cut -f2)
        name=$(echo "$line" | cut -f3)
        [ -z "$mac" ] && continue

        # Menú de acciones del dispositivo
        while true; do
            act=$(device_menu "$mac" "$name")
            [ -z "$act" ] && exit 0
            echo "$act" | grep -qF "$(t bl.exit)" && exit 0
            echo "$act" | grep -qF "$(t bl.back)" && break
            echo "$act" | grep -qF "$(t bl.disconnect)" && { disconnect_device "$mac" "$name"; break; }
            echo "$act" | grep -qF "$(t bl.connect)" && { connect_device "$mac" "$name"; break; }
            echo "$act" | grep -qF "$(t bl.send_file)" && { send_file "$mac" "$name"; break; }
            echo "$act" | grep -qF "$(t bl.sink)" && { set_sink "$name"; break; }
            echo "$act" | grep -qF "$(t bl.source)" && { set_source "$name"; break; }
            echo "$act" | grep -qF "$(t bl.forget)" && { forget_device "$mac" "$name"; break; }
            break
        done
    done
done
