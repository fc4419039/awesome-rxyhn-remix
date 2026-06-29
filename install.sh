#!/bin/bash

# AwesomeWM Remix - Script de instalación completo
# Arch Linux / Manjaro compatible

set -e  # Salir si hay algún error

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# =====================================================================
# 1️⃣ VERIFICAR Y INSTALAR AUR HELPER
# =====================================================================
echo -e "${YELLOW}🔍 Buscando AUR helper...${NC}"

AUR_HELPER=""

if command -v paru &> /dev/null; then 
    echo -e "${GREEN}✓ Paru está instalado${NC}"
    AUR_HELPER="paru"
elif command -v yay &> /dev/null; then 
    echo -e "${GREEN}✓ yay está instalado${NC}"
    AUR_HELPER="yay"
else
    echo -e "${YELLOW}⚠️  No se encontró AUR helper. Instalando yay...${NC}"
    
    # Instalar dependencias necesarias
    sudo pacman -S --needed --noconfirm base-devel git
    
    # Crear directorio temporal
    TEMPDIR=$(mktemp -d)
    echo -e "${YELLOW}📁 Directorio temporal: $TEMPDIR${NC}"
    
    # Clonar yay-bin
    git clone https://aur.archlinux.org/yay-bin.git "$TEMPDIR/yay-bin"
    cd "$TEMPDIR/yay-bin"
    
    # Compilar e instalar
    makepkg -si --noconfirm
    
    # Volver al directorio original
    cd - > /dev/null
    
    # Limpiar
    rm -rf "$TEMPDIR"
    
    # Verificar instalación
    if command -v yay &> /dev/null; then
        echo -e "${GREEN}✓ yay instalado correctamente${NC}"
        AUR_HELPER="yay"
    else 
        echo -e "${RED}✗ Error instalando yay${NC}"
        exit 1
    fi
fi

echo ""

# =====================================================================
# 2️⃣ INSTALAR DEPENDENCIAS
# =====================================================================
echo -e "${YELLOW}📦 Instalando dependencias...${NC}"

$AUR_HELPER -Sy --needed awesome-git picom-git kitty rofi todo-bin acpi acpid \
    wireless_tools jq inotify-tools polkit-gnome xdotool xclip maim \
    brightnessctl alsa-utils alsa-tools pipewire pipewire-pulse wireplumber \
    playerctl spotify onlyoffice-bin mpd ncmpcpp mpd-mpris blueman pasystray \
    touchegg redshift networkmanager bluez libnotify curl ffmpeg gpick \
    imagemagick thunar firefox krita xorg-xrdb \
    nerd-fonts-jetbrains-mono ttf-iosevka-nerd ttf-font-awesome ttf-material-design-icons ttf-weather-icons \
    zsh-syntax-highlighting zsh-autosuggestions zoxide feh zsh neovim \
    btop lsd bat python-gobject pipewire-alsa \
    powerlevel10k sound-theme-freedesktop --needed

echo -e "${GREEN}✓ Dependencias instaladas${NC}"

echo ""

# =====================================================================
# 2b️⃣ INSTALAR OPENCODE (AI Agent)
# =====================================================================
echo -e "${YELLOW}🤖 Instalando OpenCode (AI Agent)...${NC}"

if ! command -v opencode &> /dev/null; then
    echo -e "${YELLOW}📦 Instalando opencode...${NC}"
    curl -fsSL https://opencode.ai/install | bash
    echo -e "${GREEN}✓ OpenCode instalado${NC}"
else
    echo -e "${GREEN}✓ OpenCode ya está instalado${NC}"
fi

echo ""

# =====================================================================
# 3️⃣ HABILITAR SERVICIOS
# =====================================================================
echo -e "${YELLOW}🔄 Habilitando servicios...${NC}"

sudo systemctl enable acpid.service
sudo systemctl start acpid.service

echo -e "${GREEN}✓ Servicios habilitados${NC}"

echo ""

# =====================================================================
# 4️⃣ CREAR DIRECTORIOS NECESARIOS
# =====================================================================
echo -e "${YELLOW}📁 Creando directorios...${NC}"

mkdir -p ~/.config
mkdir -p ~/.local/bin
mkdir -p ~/.local/share/fonts
mkdir -p ~/fondos
mkdir -p ~/Music
mkdir -p ~/.config/todo
mkdir -p ~/.config/mpd/playlists

echo -e "${GREEN}✓ Directorios creados${NC}"

echo ""

# =====================================================================
# 5️⃣ COPIAR ARCHIVOS DE CONFIGURACIÓN
# =====================================================================
echo -e "${YELLOW}📦 Copiando archivos de configuración...${NC}"

# Verificar que los directorios existan
if [ ! -d "config" ]; then
    echo -e "${RED}✗ Error: Carpeta 'config' no encontrada${NC}"
    exit 1
fi

if [ ! -d "bin" ]; then
    echo -e "${RED}✗ Error: Carpeta 'bin' no encontrada${NC}"
    exit 1
fi

cp -r config/* ~/.config/
cp -r bin/* ~/.local/bin/

# Copiar .profile si existe
if [ -f ".profile" ]; then
    cp .profile ~/
fi

# Copiar .Xresources si existe
if [ -f "misc/.Xresources" ]; then
    cp misc/.Xresources ~/.Xresources
    echo -e "${GREEN}✓ .Xresources instalado${NC}"
fi

# Copiar .profile desde misc/ si no se copió antes
if [ -f "misc/.profile" ] && [ ! -f "$HOME/.profile" ]; then
    cp misc/.profile ~/
    echo -e "${GREEN}✓ .profile instalado desde misc/${NC}"
fi

echo -e "${GREEN}✓ Archivos de configuración copiados${NC}"

# Actualizar módulos externos a sus últimas versiones
echo -e "${YELLOW}📦 Actualizando módulos externos (bling, rubato, layout-machi)...${NC}"
bash "$(dirname "$0")/update_modules.sh" 2>/dev/null || echo -e "${YELLOW}  ⚠ No se pudieron actualizar, se usan los versionados en el repo${NC}"

# Activar timer de limpieza automática (cada 3 días)
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable --now limpiar-sistema.timer 2>/dev/null && echo -e "${GREEN}✓ Timer de limpieza automática activado${NC}" || true

echo ""

# =====================================================================
# 6️⃣ INSTALAR FUENTES
# =====================================================================
echo -e "${YELLOW}🔤 Instalando fuentes...${NC}"

if [ -d "fonts" ] && [ "$(ls -A fonts)" ]; then
    # Instalar en ~/.local/share/fonts/ (usuario actual)
    cp -r fonts/* ~/.local/share/fonts/
    echo -e "${GREEN}✓ Fuentes instaladas en ~/.local/share/fonts/${NC}"
    
    # Instalar en /usr/share/fonts/ (sistema completo)
    echo -e "${YELLOW}⚠️  Instalando fuentes en /usr/share/fonts/ (requiere sudo)...${NC}"
    sudo mkdir -p /usr/share/fonts
    sudo cp -r fonts/* /usr/share/fonts/
    echo -e "${GREEN}✓ Fuentes instaladas en /usr/share/fonts/${NC}"
    
    # Actualizar cache de fuentes
    echo -e "${YELLOW}🔄 Actualizando cache de fuentes...${NC}"
    fc-cache -fv
    sudo fc-cache -fv
    echo -e "${GREEN}✓ Cache de fuentes actualizado${NC}"
else
    echo -e "${YELLOW}⚠️  Carpeta fonts vacía o no encontrada${NC}"
fi

echo ""

# =====================================================================
# 7️⃣ CONFIGURAR PERMISOS
# =====================================================================
echo -e "${YELLOW}🔐 Configurando permisos de ejecución...${NC}"

chmod +x ~/.local/bin/* 2>/dev/null || true
chmod +x ~/.config/awesome/scripts/* 2>/dev/null || true

if [ -f ~/.config/cambiar_fondo.sh ]; then
    chmod +x ~/.config/cambiar_fondo.sh
fi

if [ -f ~/.config/awesome/configuration/autostart ]; then
    chmod +x ~/.config/awesome/configuration/autostart
fi

echo -e "${GREEN}✓ Permisos configurados${NC}"

echo ""

# =====================================================================
# 8️⃣ COPIAR FONDOS DE PANTALLA
# =====================================================================
echo -e "${YELLOW}🖼️ Instalando fondos de pantalla...${NC}"
mkdir -p ~/fondos/
if [ -d "fondos" ] && [ "$(ls -A fondos)" ]; then
    cp -rf fondos/* ~/fondos/
    echo -e "${GREEN}✓ Fondos instalados en ~/fondos${NC}"
else
    echo -e "${YELLOW}⚠️  Carpeta fondos vacía o no encontrada${NC}"

fi

echo ""

# =====================================================================
# 9️⃣ CONFIGURAR SHELL (.zshrc)
# =====================================================================
echo -e "${YELLOW}🐚 Configurando shell...${NC}"

if [ -f ".zshrc" ]; then
    if [ -f ~/.zshrc ]; then
        echo -e "${YELLOW}💾 Se encontró un .zshrc existente. Creando respaldo...${NC}"
        cp ~/.zshrc ~/.zshrc.bak.$(date +%s)
    fi
    cp .zshrc ~/
    echo -e "${GREEN}✓ .zshrc instalado${NC}"
else
    echo -e "${YELLOW}⚠️  .zshrc no encontrado en el repositorio${NC}"
fi

# Agregar TODO_PATH si no existe
if ! grep -q "TODO_PATH" ~/.zshrc 2>/dev/null; then
    echo "" >> ~/.zshrc
    echo "# AwesomeWM Remix" >> ~/.zshrc
    echo 'export TODO_PATH="$HOME/.config/todo"' >> ~/.zshrc
    echo -e "${GREEN}✓ TODO_PATH agregada a .zshrc${NC}"
fi

echo ""

# =====================================================================
# 🔟 CONFIGURACIÓN DE SDDM (SUGAR-CANDY)
# =====================================================================
echo -e "${YELLOW}🎨 Configurando tema de inicio de sesión (SDDM)...${NC}"

if command -v sddm &> /dev/null; then
    if [ -d "sddm/sugar-candy" ]; then
        echo -e "${YELLOW}🔒 Copiando tema sugar-candy...${NC}"
        sudo cp -r sddm/sugar-candy /usr/share/sddm/themes/
        
        sudo mkdir -p /etc/sddm.conf.d
        
        echo -e "${YELLOW}⚙️  Activando Sugar-Candy...${NC}"
        sudo bash -c 'cat << EOF > /etc/sddm.conf.d/theme.conf
[Theme]
Current=sugar-candy
EOF'
        
        echo -e "${YELLOW}🔄 Habilitando servicio SDDM...${NC}"
        sudo systemctl enable sddm.service
        
        echo -e "${GREEN}✓ SDDM configurado${NC}"
    else
        echo -e "${YELLOW}⚠️  Carpeta sugar-candy no encontrada${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  SDDM no está instalado. Saltando configuración.${NC}"
fi

echo ""

# =====================================================================
# INSTALACIÓN COMPLETADA
# =====================================================================
echo "════════════════════════════════════════════════════"
echo -e "${GREEN}✅ ¡Instalación completada con éxito!${NC}"
echo "════════════════════════════════════════════════════"
echo ""
echo -e "${YELLOW}📝 PRÓXIMOS PASOS:${NC}"
echo "1. Recarga las variables de entorno:"
echo -e "   ${GREEN}source ~/.zshrc${NC}"
echo ""
echo "2. Configura OpenWeatherMap (opcional):"
echo -e "   ${GREEN}Edit: ~/.config/awesome/rc.lua${NC}"
echo "   Set: openweathermap_key y openweathermap_city_id"
echo ""
echo "3. Control de volumen de notificaciones:"
echo "   El script notif-sink-setup.sh (autostart) crea un sink"
echo "   independiente 'notifications' con volumen separado."
echo "   Usa Super+v para abrir el control de volumen GTK."
echo ""
echo "4. Reinicia tu sesión o presiona Super+Ctrl+R en AwesomeWM"
echo ""
echo "════════════════════════════════════════════════════"
