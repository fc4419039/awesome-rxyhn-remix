#!/bin/bash
# Restaura colores sólidos si se reinició con blur/transparencia activa
# Los state files están en /tmp (se pierden al reiniciar) pero .codebak persiste

CODE_BAK="$HOME/.config/awesome/.codebak"
THEME_DIR="$HOME/.config/awesome/theme"
THEME_SOLID="$THEME_DIR/theme_solid.lua"

# Siempre restaurar theme.lua desde theme_solid.lua (tema base sin transparencia)
cp "$THEME_SOLID" "$THEME_DIR/theme.lua"

# Limpiar backup si existe
rm -f "$THEME_DIR/theme.lua.bak"

if [ ! -d "$CODE_BAK" ]; then
    awesome-client 'awesome.restart()'
    exit 0
fi

# Restaurar archivos UI
NOTIFS_INIT="$HOME/.config/awesome/ui/notifs/init.lua"
NOTIFS_POPUP="$HOME/.config/awesome/ui/notifs/popup.lua"
LOCKSCREEN="$HOME/.config/awesome/ui/lockscreen/lockscreen.lua"
SYS_MENU="$HOME/.config/awesome/ui/system_menu/init.lua"
TITLEBAR="$HOME/.config/awesome/ui/decorations/titlebar.lua"
TOOLTIP="$HOME/.config/awesome/ui/tooltip/init.lua"

for f in init.lua popup.lua lockscreen.lua sys_menu.lua titlebar.lua tooltip_init.lua; do
    if [ -f "$CODE_BAK/$f" ]; then
        case "$f" in
            init.lua) cp "$CODE_BAK/$f" "$NOTIFS_INIT" ;;
            popup.lua) cp "$CODE_BAK/$f" "$NOTIFS_POPUP" ;;
            lockscreen.lua) cp "$CODE_BAK/$f" "$LOCKSCREEN" ;;
            sys_menu.lua) cp "$CODE_BAK/$f" "$SYS_MENU" ;;
            titlebar.lua) cp "$CODE_BAK/$f" "$TITLEBAR" ;;
            tooltip_init.lua) cp "$CODE_BAK/$f" "$TOOLTIP" ;;
        esac
    fi
done

# Restaurar archivos rofi
ROFI_SRC=("rofi.rasi" "network.rasi" "bluetooth.rasi" "powermenu.rasi" "powermenu-confirm.rasi")
ROFI_DST=(
    "$THEME_DIR/rofi.rasi"
    "$THEME_DIR/network.rasi"
    "$THEME_DIR/bluetooth.rasi"
    "$THEME_DIR/powermenu.rasi"
    "$THEME_DIR/powermenu-confirm.rasi"
)
for i in "${!ROFI_SRC[@]}"; do
    if [ -f "$CODE_BAK/${ROFI_SRC[$i]}" ]; then
        cp "$CODE_BAK/${ROFI_SRC[$i]}" "${ROFI_DST[$i]}"
    fi
done

# wifi-theme.rasi está en ~/.config/rofi/
if [ -f "$CODE_BAK/wifi-theme.rasi" ]; then
    cp "$CODE_BAK/wifi-theme.rasi" "$HOME/.config/rofi/wifi-theme.rasi"
fi

rm -rf "$CODE_BAK"

awesome-client 'awesome.restart()'
