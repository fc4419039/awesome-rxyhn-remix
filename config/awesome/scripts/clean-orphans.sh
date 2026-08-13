#!/bin/bash
# Elimina paquetes huerfanos de pacman con un menu rofi
# (lista ordenada por tamano, opcion "quitar todos", confirmacion rofi).

source "$HOME/.config/awesome/scripts/i18n.sh"

theme="$HOME/.config/awesome/theme/rofi-menu.rasi"
confirm_theme="$HOME/.config/awesome/theme/powermenu-confirm.rasi"

GREEN="#22c55e"
DIM="#64748b"
CYAN="#06b6d4"
RED="#ef4444"
TRASH="󰇔"
NO="󰄰"
YES="󰄱"

# Obtener huérfanos y filtrar protegidos (incluyendo qt5/qt6/pyqt y drivers de video)
all_orphans=$(pacman -Qdtq 2>/dev/null)
orphans=""
for pkg in $all_orphans; do
    is_protected=false
    # Proteger qt5, qt6, pyqt, drivers de video y los listados
    if [[ "$pkg" == qt5-* ]] || [[ "$pkg" == qt6-* ]] || [[ "$pkg" == *pyqt* ]] || [[ "$pkg" == xf86-video-* ]]; then
        is_protected=true
    else
        for p in sddm lightdm gdm lxdm awesome bspwm i3-wm networkmanager dhcpcd iwd grub efibootmgr pulseaudio pipewire; do
            if [[ "$pkg" == "$p" ]]; then
                is_protected=true
                break
            fi
        done
    fi
    if [ "$is_protected" = false ]; then
        orphans="$orphans $pkg"
    fi
done

if [ -z "$(echo $orphans | xargs)" ]; then
    notify-send "$(t co.title)" "$(t co.none)" -i edit-clear
    exit 0
fi

count=$(wc -l <<< "$orphans")

sizes=$(printf '%s\n' "$orphans" | xargs env LC_ALL=C pacman -Qi 2>/dev/null | awk '
    /^Name[ \t]*:/ { name=$3 }
    /^Installed Size[ \t]*:/ {
        sz=$0; sub(/^Installed Size[ \t]*:[ \t]*/, "", sz); human=sz
        v=sz+0
        if (sz ~ /KiB/) v*=1024
        else if (sz ~ /MiB/) v*=1048576
        else if (sz ~ /GiB/) v*=1073741824
        print v "\t" name "\t" human
    }' | sort -t$'\t' -k1,1rn)

map=$(mktemp /tmp/co-map.XXXXXX 2>/dev/null) || map="/tmp/co-map.tmp"
trap 'rm -f "$map"' EXIT

printf "<span foreground='%s'>%s</span>  %s\tALL\n" "$CYAN" "$TRASH" "$(tsub co.remove_all "$count")" >> "$map"

while IFS=$'\t' read -r _bytes name human; do
    [ -z "$name" ] && continue
    printf "<span foreground='%s'>%s</span>  %s  <span foreground='%s' size='small'>%s</span>\t%s\n" \
        "$RED" "$TRASH" "$name" "$DIM" "$human" "$name" >> "$map"
done <<< "$sizes"

selected=$(cut -f1 "$map" | rofi -dmenu -markup-rows -theme "$theme" -no-custom -i)
[ -z "$selected" ] && exit 0

line=$(grep -F "$selected" "$map" | head -1)
target=$(printf '%s' "$line" | cut -f2)
[ -z "$target" ] && exit 0

if [ "$target" = "ALL" ]; then
    pkgs="$orphans"
    msg="$(tsub co.confirm "$count")"
else
    pkgs="$target"
    msg="$(tsub co.confirm_one "$target")"
fi

confirm() {
    local msg="$1" ans
    ans=$(printf "%s %s\n%s %s" "$NO" "$(t co.no)" "$YES" "$(t co.yes)" | rofi -dmenu -theme "$confirm_theme" -mesg "$msg" -selected-row 0)
    [[ "$ans" == "$YES $(t co.yes)" ]]
}

if confirm "$msg"; then
    if sudo pacman -Rns $pkgs 2>/dev/null; then
        notify-send "$(t co.done_title)" "$(tsub co.removed "$(wc -l <<< "$pkgs")")" -i edit-clear
    else
        notify-send "$(t common.error)" "$(t co.error_failed)" -i dialog-error
    fi
fi
