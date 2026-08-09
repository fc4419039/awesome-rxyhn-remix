#!/bin/bash

source "$HOME/.config/awesome/scripts/i18n.sh"

STATE_DIR="$HOME/.cache/awesome"
STATE_FILE="$STATE_DIR/blur-mode"
THEME_DIR="$HOME/.config/awesome/theme"
THEME_LUA="$THEME_DIR/theme.lua"
THEME_SOLID="$THEME_DIR/theme_solid.lua"
PICOM_CONF="$THEME_DIR/picom.conf"
PICOM_BLUR="$THEME_DIR/picom-blur.conf"
BACKUP="$THEME_DIR/theme.lua.bak"
THEME_SOLID="$THEME_DIR/theme_solid.lua"
NOTIFS_INIT="$HOME/.config/awesome/ui/notifs/init.lua"
NOTIFS_POPUP="$HOME/.config/awesome/ui/notifs/popup.lua"
LOCKSCREEN="$HOME/.config/awesome/ui/lockscreen/lockscreen.lua"
SYS_MENU="$HOME/.config/awesome/ui/system_menu/init.lua"
TITLEBAR="$HOME/.config/awesome/ui/decorations/titlebar.lua"
TOOLTIP="$HOME/.config/awesome/ui/tooltip/init.lua"
ROFI_FILES=(
    "$HOME/.config/awesome/theme/rofi.rasi"
    "$HOME/.config/awesome/theme/network.rasi"
    "$HOME/.config/awesome/theme/bluetooth.rasi"
    "$HOME/.config/awesome/theme/powermenu.rasi"
    "$HOME/.config/awesome/theme/powermenu-confirm.rasi"
    "$HOME/.config/rofi/wifi-theme.rasi"
)
CODE_BAK="$HOME/.config/awesome/.codebak"
TOOLTIP_BAK="$CODE_BAK/tooltip_init.lua"

mkdir -p "$STATE_DIR"

if [ -f "$STATE_FILE" ]; then
    rm -f "$STATE_FILE"
    TRANSPARENCY_STATE="$STATE_DIR/transparency-mode"
    if [ -f "$TRANSPARENCY_STATE" ]; then
        rm -f "$TRANSPARENCY_STATE"
    fi
    # Limpiar state files legacy de /tmp (pre-persistencia)
    rm -f /tmp/awesome-blur-mode /tmp/awesome-transparency-mode
    pkill picom
    if [ -f "$BACKUP" ]; then
        cp "$BACKUP" "$THEME_LUA"
        rm -f "$BACKUP"
    fi
    for f in init.lua popup.lua lockscreen.lua sys_menu.lua titlebar.lua; do
        if [ -f "$CODE_BAK/$f" ]; then
            case "$f" in
                init.lua) cp "$CODE_BAK/$f" "$NOTIFS_INIT" ;;
                popup.lua) cp "$CODE_BAK/$f" "$NOTIFS_POPUP" ;;
                lockscreen.lua) cp "$CODE_BAK/$f" "$LOCKSCREEN" ;;
                sys_menu.lua) cp "$CODE_BAK/$f" "$SYS_MENU" ;;
                titlebar.lua) cp "$CODE_BAK/$f" "$TITLEBAR" ;;
            esac
        fi
    done
    if [ -f "$TOOLTIP_BAK" ]; then
        cp "$TOOLTIP_BAK" "$TOOLTIP"
    fi
    for rf in "${ROFI_FILES[@]}"; do
        bname=$(basename "$rf")
        if [ -f "$CODE_BAK/$bname" ]; then
            cp "$CODE_BAK/$bname" "$rf"
        fi
    done
    rm -rf "$CODE_BAK"

    # Restaurar theme sólido desde theme_solid.lua
    cp "$THEME_SOLID" "$THEME_LUA"

    # Restaurar tooltip a transparente (sin fondo hardcodeado)
    sed -i 's/bg = "#0a1419[0-9a-f]\{2\}"/bg = beautiful.transparent/g' "$TOOLTIP"

    # Restaurar popup volume/brightness a 95%
    sed -i 's/bg = "#0a141999"/bg = "#0a1419e6"/g' "$NOTIFS_POPUP"

    picom -b --dbus --config "$PICOM_CONF" &>/dev/null &
    awesome-client 'awesome.restart()'
    notify-send -t 1500 "$(t tb.title)" "$(t tb.deactivated)"
else
    touch "$STATE_FILE"
    cp "$THEME_LUA" "$BACKUP"
    mkdir -p "$CODE_BAK"
    cp "$NOTIFS_INIT" "$NOTIFS_POPUP" "$LOCKSCREEN" "$SYS_MENU" "$TITLEBAR" "${ROFI_FILES[@]}" "$CODE_BAK/"
    cp "$TOOLTIP" "$CODE_BAK/tooltip_init.lua"

    sed -i \
        -e 's/^theme\.xbackground = xrdb\.background$/theme.xbackground = "#0a141973"/' \
        -e 's/^theme\.xcolor0 = xrdb\.color0$/theme.xcolor0 = "#1c252c73"/' \
        -e 's/theme\.darker_bg = "#0a1419"/theme.darker_bg = "#0a141973"/' \
        -e 's/theme\.lighter_bg = "#162026"/theme.lighter_bg = "#16202673"/' \
        -e 's/theme\.dashboard_box_bg = theme\.lighter_bg/theme.dashboard_box_bg = "#16202673"/' \
        -e 's/theme\.wibar_bg = theme\.xbackground/theme.wibar_bg = "#0a1419cc"/' \
        -e 's/theme\.tooltip_bg = theme\.xbackground/theme.tooltip_bg = "#0a141980"/' \
        "$THEME_LUA"

    sed -i \
        -e 's/beautiful\.xbackground \.\. "00"/"#00000000"/' \
        -e 's/beautiful\.xbackground \.\. "22"/"#0a141922"/' \
        "$NOTIFS_INIT" "$NOTIFS_POPUP" "$LOCKSCREEN"

    # System menu (35%) y notif center (60%)
    sed -i 's/bg = beautiful\.xbackground/bg = "#0a141959"/g' "$SYS_MENU"
    sed -i 's/bg = beautiful\.xbackground/bg = "#0a141999"/g' "$NOTIFS_INIT"
    # Titlebar (90%)
    sed -i 's/bg = beautiful\.bg_secondary/bg = "#0a1419e6"/g' "$TITLEBAR"
    # Volume/Brightness popup (80% - más transparente en blur)
    sed -i 's/bg = "#0a1419e6"/bg = "#0a141999"/g' "$NOTIFS_POPUP"

    # Tooltip (60% - match notif center)
    sed -i 's/bg = "#0a1419[0-9a-f]\{2\}"/bg = "#0a141999"/g' "$TOOLTIP"

    # Todos los rofi menus (70%)
    sed -i 's/background-color: *#0d0d1aF2/background-color: #0d0d1ab3/' "${ROFI_FILES[@]}"

    pkill picom
    picom -b --dbus --config "$PICOM_BLUR" &>/dev/null &
    awesome-client 'awesome.restart()'
    notify-send -t 1500 "$(t tb.title)" "$(t tb.activated)"
fi
