#!/bin/bash
# clean-cache.sh — Limpia caché acumulada y basura regenerable (multi-distro)
# Detecta: pacman, apt, dnf, zypper

source "$HOME/.config/awesome/scripts/i18n.sh"

theme="$HOME/.config/awesome/theme/rofi-menu.rasi"
confirm_theme="$HOME/.config/awesome/theme/powermenu-confirm.rasi"

NO="󰄰"
YES="󰄱"

# ─── Detección de package manager ───
detect_pkg_mgr() {
    if command -v pacman >/dev/null 2>&1; then echo "pacman"
    elif command -v apt >/dev/null 2>&1; then echo "apt"
    elif command -v dnf >/dev/null 2>&1; then echo "dnf"
    elif command -v zypper >/dev/null 2>&1; then echo "zypper"
    else echo "unknown"; fi
}

PKG_MGR=$(detect_pkg_mgr)

# ─── Funciones de limpieza por PM ───
clean_pacman() {
    # paccache mantiene 3 versiones
    if command -v paccache >/dev/null 2>&1; then
        paccache -rk3 2>/dev/null || \
        command -v pkexec >/dev/null 2>&1 && pkexec paccache -rk3 2>/dev/null
    fi
    # yay cache
    command -v yay >/dev/null 2>&1 && yay -Sc --noconfirm 2>/dev/null || rm -rf ~/.cache/yay 2>/dev/null
}

clean_apt() {
    sudo apt clean 2>/dev/null
    sudo apt autoclean 2>/dev/null
}

clean_dnf() {
    sudo dnf clean all 2>/dev/null
}

clean_zypper() {
    sudo zypper clean -a 2>/dev/null
}

clean_pkg_cache() {
    case "$PKG_MGR" in
        pacman) clean_pacman ;;
        apt)    clean_apt ;;
        dnf)    clean_dnf ;;
        zypper) clean_zypper ;;
    esac
}

# ─── Helpers ───
size_of() {
    du -sk "$@" 2>/dev/null | awk '{s+=$1} END {print s+0}'
}

human() { numfmt --to=iec --suffix=B "$1" 2>/dev/null || echo "${1}B"; }

total_size() {
    local s=0 t
    for t in ~/.zsh-backup-* ~/.config/awesome/.codebak ~/.config/awesome/ui/*/.codebak \
             ~/.cache/opencode ~/.cache/yay ~/wget-log ~/download_repair*.php ~/.~lock.* ; do
        [[ -e "$t" ]] && s=$((s + $(size_of "$t")))
    done

    # Cache de package manager
    case "$PKG_MGR" in
        pacman) s=$((s + $(size_of /var/cache/pacman/pkg))) ;;
        apt)    s=$((s + $(size_of /var/cache/apt/archives))) ;;
        dnf)    s=$((s + $(size_of /var/cache/dnf))) ;;
        zypper) s=$((s + $(size_of /var/cache/zypp/packages))) ;;
    esac
    echo "$s"
}

confirm() {
    local msg="$1" ans
    ans=$(printf "%s %s\n%s %s" "$NO" "$(t co.no)" "$YES" "$(t co.yes)" | \
        rofi -dmenu -theme "$confirm_theme" -mesg "$msg" -selected-row 0)
    [[ "$ans" == "$YES $(t co.yes)" ]]
}

before=$(total_size)

if ! confirm "$(tsub cc.confirm "$(human $((before * 1024)))")"; then
    exit 0
fi

# 1) Backups de awesome (se regeneran con toggle-blur.sh)
( shopt -s nullglob
  rm -rf ~/.config/awesome/.codebak ~/.config/awesome/ui/*/.codebak 2>/dev/null )

# 2) Backup viejo de zsh (todo duplicado: .fzf, p10k, .p10k.zsh)
( shopt -s nullglob
  rm -rf ~/.zsh-backup-* 2>/dev/null )

# 3) Caché de opencode
rm -rf ~/.cache/opencode 2>/dev/null

# 4) Caché de package manager
clean_pkg_cache

# 5) Basura en $HOME
( shopt -s nullglob
  rm -f ~/wget-log ~/download_repair*.php ~/.~lock.* 2>/dev/null )

after=$(total_size)
freed=$(( (before > after) ? before - after : 0 ))

notify-send "$(t cc.done_title)" "$(tsub cc.freed "$(human $((freed * 1024)))")" -i edit-clear