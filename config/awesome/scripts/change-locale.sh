#!/bin/bash
# Change system locale

current=$(grep "^LANG=" /etc/locale.conf 2>/dev/null | cut -d= -f2)

locales="es_MX.UTF-8  Español (México)
es_ES.UTF-8  Español (España)
en_US.UTF-8  Inglés (EE.UU.)
en_GB.UTF-8  Inglés (Reino Unido)
pt_BR.UTF-8  Portugués (Brasil)
pt_PT.UTF-8  Portugués (Portugal)
fr_FR.UTF-8  Francés
de_DE.UTF-8  Alemán
it_IT.UTF-8  Italiano
ja_JP.UTF-8  Japonés
ko_KR.UTF-8  Coreano
zh_CN.UTF-8  Chino (Simplificado)
ru_RU.UTF-8  Ruso
ar_SA.UTF-8  Árabe"

selected=$(echo "$locales" | rofi -dmenu -p "Language" \
    -theme "$HOME/.config/awesome/theme/rofi-menu.rasi" \
    -no-custom)

if [ -n "$selected" ]; then
    locale=$(echo "$selected" | awk '{print $1}')

    sudo localectl set-locale "LANG=$locale" 2>/dev/null
    if [ $? -eq 0 ]; then
        notify-send "Locale actualizado" "Idioma: $locale\nReiniciando awesome..." -i preferences-desktop-locale
        sleep 1
        awesome-client 'awesome.restart()' 2>/dev/null
    else
        notify-send "Error" "No se pudo cambiar el locale" -i dialog-error
    fi
fi
