#!/bin/bash
# clean-cache.sh — Limpia caché acumulada y basura regenerable del sistema.
# Lanzado desde el system_menu (rofi). No requiere terminal.
# - Backups .codebak de awesome (los regenera toggle-blur.sh)
# - Backup viejo de zsh (~/.zsh-backup-*)  [todo duplicado]
# - Caché de opencode y de yay
# - Caché de pacman (paccache, mantiene 3 versiones)
# - Basura en $HOME (wget-log, download_repair*, locks de LibreOffice)

source "$HOME/.config/awesome/scripts/i18n.sh"

theme="$HOME/.config/awesome/theme/rofi-menu.rasi"
confirm_theme="$HOME/.config/awesome/theme/powermenu-confirm.rasi"

NO="󰄰"
YES="󰄱"

# --- Targets de limpieza (solo caché/basura regenerable) ---
pacman_cache=/var/cache/pacman/pkg

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
    s=$((s + $(size_of "$pacman_cache")))
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

# 4) Caché de paquetes
if ! command paccache -rk3 2>/dev/null; then
    command -v pkexec >/dev/null 2>&1 && pkexec paccache -rk3 2>/dev/null
fi
command yay -Sc --noconfirm 2>/dev/null || rm -rf ~/.cache/yay 2>/dev/null

# 5) Basura en $HOME
( shopt -s nullglob
  rm -f ~/wget-log ~/download_repair*.php ~/.~lock.* 2>/dev/null )

after=$(total_size)
freed=$(( (before > after) ? before - after : 0 ))

notify-send "$(t cc.done_title)" "$(tsub cc.freed "$(human $((freed * 1024)))")" -i edit-clear
