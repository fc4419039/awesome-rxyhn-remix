#!/bin/bash
# Fallback de emergencia: restaura colores sólidos si se reinició con
# blur/transparencia activa. Normalmente no se necesita porque el estado
# ahora es persistente en ~/.cache/awesome.

CODE_BAK="$HOME/.config/awesome/.codebak"
THEME_DIR="$HOME/.config/awesome/theme"
THEME_SOLID="$THEME_DIR/theme_solid.lua"

# Restaurar theme.lua: primero el backup real (si existe), si no el sólido
if [ -f "$THEME_DIR/theme.lua.bak" ]; then
    cp "$THEME_DIR/theme.lua.bak" "$THEME_DIR/theme.lua"
    rm -f "$THEME_DIR/theme.lua.bak"
else
    cp "$THEME_SOLID" "$THEME_DIR/theme.lua"
fi

if [ ! -d "$CODE_BAK" ]; then
    pgrep -x awesome > /dev/null 2>&1 && awesome-client 'awesome.restart()'
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

rm -rf "$CODE_BAK"

pgrep -x awesome > /dev/null 2>&1 && awesome-client 'awesome.restart()'
