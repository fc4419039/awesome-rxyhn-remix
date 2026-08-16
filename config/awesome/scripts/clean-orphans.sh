#!/bin/bash
# Elimina paquetes huérfanos con menú rofi (multi-distro)
# Detecta automáticamente: pacman, apt, dnf, zypper

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

# ─── Detección de package manager ───
detect_pkg_mgr() {
    if command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

PKG_MGR=$(detect_pkg_mgr)

# ─── Funciones por package manager ───
get_orphans_pacman() {
    pacman -Qdtq 2>/dev/null
}

get_orphans_apt() {
    apt list --installed 2>/dev/null | grep 'automatic' | cut -d/ -f1
}

get_orphans_dnf() {
    dnf repoquery --unneeded --quiet 2>/dev/null
}

get_orphans_zypper() {
    zypper packages --orphaned 2>/dev/null | awk '/^i/ {print $3}'
}

get_pkg_size_pacman() {
    local pkg="$1"
    pacman -Qi "$pkg" 2>/dev/null | awk '/^Installed Size/ {print $3" "$4}'
}

get_pkg_size_apt() {
    local pkg="$1"
    dpkg-query -Wf '${Installed-Size}\t${Package}\n' "$pkg" 2>/dev/null | awk '{print $1" KB"}'
}

get_pkg_size_dnf() {
    local pkg="$1"
    rpm -qi "$pkg" 2>/dev/null | awk '/^Size/ {print $3" "$4}'
}

get_pkg_size_zypper() {
    local pkg="$1"
    rpm -qi "$pkg" 2>/dev/null | awk '/^Size/ {print $3" "$4}'
}

remove_pkgs_pacman() {
    sudo pacman -Rns "$@" 2>/dev/null
}

remove_pkgs_apt() {
    sudo apt autoremove -y "$@" 2>/dev/null
}

remove_pkgs_dnf() {
    sudo dnf remove -y "$@" 2>/dev/null
}

remove_pkgs_zypper() {
    sudo zypper remove -y "$@" 2>/dev/null
}

# ─── Dispatchers ───
get_orphans() {
    case "$PKG_MGR" in
        pacman) get_orphans_pacman ;;
        apt)    get_orphans_apt ;;
        dnf)    get_orphans_dnf ;;
        zypper) get_orphans_zypper ;;
        *)      notify-send "$(t co.title)" "$(t co.unsupported)" -i dialog-error; exit 1 ;;
    esac
}

get_pkg_size() {
    case "$PKG_MGR" in
        pacman) get_pkg_size_pacman "$1" ;;
        apt)    get_pkg_size_apt "$1" ;;
        dnf)    get_pkg_size_dnf "$1" ;;
        zypper) get_pkg_size_zypper "$1" ;;
    esac
}

remove_pkgs() {
    case "$PKG_MGR" in
        pacman) remove_pkgs_pacman "$@" ;;
        apt)    remove_pkgs_apt "$@" ;;
        dnf)    remove_pkgs_dnf "$@" ;;
        zypper) remove_pkgs_zypper "$@" ;;
    esac
}

# ─── Paquetes protegidos (nunca eliminar) ───
# Nota: nombres genéricos, cada distro puede tener variantes
is_protected() {
    local pkg="$1"
    case "$pkg" in
        qt5-*|qt6-*|*pyqt*|xf86-video-*) return 0 ;;
        sddm|lightdm|gdm|lxdm|awesome|bspwm|i3-wm|networkmanager|dhcpcd|iwd|grub|efibootmgr|pulseaudio|pipewire|wireplumber) return 0 ;;
    esac
    return 1
}

# ─── Obtener huérfanos ───
all_orphans=$(get_orphans)
orphans=""

for pkg in $all_orphans; do
    if ! is_protected "$pkg"; then
        orphans="$orphans $pkg"
    fi
done

if [ -z "$(echo $orphans | xargs)" ]; then
    notify-send "$(t co.title)" "$(t co.none)" -i edit-clear
    exit 0
fi

count=$(echo "$orphans" | wc -w)

# ─── Obtener tamaños y ordenar ───
map=$(mktemp /tmp/co-map.XXXXXX 2>/dev/null) || map="/tmp/co-map.tmp"
trap 'rm -f "$map"' EXIT

printf "<span foreground='%s'>%s</span>  %s\tALL\n" "$CYAN" "$TRASH" "$(tsub co.remove_all "$count")" >> "$map"

for pkg in $orphans; do
    size=$(get_pkg_size "$pkg")
    human=$(echo "$size" | awk '{if ($2=="MiB") printf "%.1f MiB", $1; else if ($2=="GiB") printf "%.1f GiB", $1; else printf "%.0f KiB", $1}')
    bytes=$(echo "$size" | awk '{if ($2=="MiB") print $1*1024*1024; else if ($2=="GiB") print $1*1024*1024*1024; else print $1*1024}')
    printf "%s\t<span foreground='%s'>%s</span>  %s  <span foreground='%s' size='small'>%s</span>\t%s\n" \
        "$bytes" "$RED" "$TRASH" "$pkg" "$DIM" "$human" "$pkg" >> "$map"
done

sort -t$'\t' -k1,1rn "$map" > "$map.sorted"
mv "$map.sorted" "$map"

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
    if remove_pkgs $pkgs; then
        notify-send "$(t co.done_title)" "$(tsub co.removed "$(echo $pkgs | wc -w)")" -i edit-clear
    else
        notify-send "$(t common.error)" "$(t co.error_failed)" -i dialog-error
    fi
fi