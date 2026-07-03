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
echo -e "${YELLOW}📦 Verificando dependencias...${NC}"

PKGS="
    awesome-git picom-git kitty rofi todo-bin acpi acpid
    wireless_tools jq inotify-tools polkit-gnome xdotool xclip maim
    brightnessctl alsa-utils alsa-tools pipewire pipewire-pulse wireplumber
    qt5-imageformats qt6-imageformats
    playerctl spotify onlyoffice-bin mpd ncmpcpp mpd-mpris blueman pasystray
    touchegg redshift networkmanager bluez libnotify curl ffmpeg gpick
    imagemagick thunar firefox krita xorg-xrdb yad
    nerd-fonts-jetbrains-mono ttf-iosevka-nerd ttf-font-awesome ttf-material-design-icons ttf-weather-icons
    zsh-syntax-highlighting zsh-autosuggestions zsh-sudo zoxide feh zsh neovim
    btop lsd bat python-gobject python-pip python-pyqt5 pipewire-alsa
    powerlevel10k fzf starship autorandr xorg-xrandr pamixer gtk3 sound-theme-freedesktop
"

# Filtrar solo los paquetes que faltan
MISSING=""
for pkg in $PKGS; do
    if ! pacman -Qi "$pkg" &>/dev/null && ! pacman -Qg "$pkg" &>/dev/null; then
        MISSING="$MISSING $pkg"
    fi
done

if [ -n "$MISSING" ]; then
    echo -e "${YELLOW}  Paquetes faltantes detectados. Instalando...${NC}"
    $AUR_HELPER -S --needed $MISSING
    echo -e "${GREEN}✓ Dependencias instaladas${NC}"
else
    echo -e "${GREEN}✓ Todas las dependencias ya estan instaladas${NC}"
fi

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

sudo systemctl enable acpid.service 2>/dev/null || echo -e "${YELLOW}  ⚠ No se pudo habilitar acpid.service${NC}"
sudo systemctl start acpid.service 2>/dev/null || echo -e "${YELLOW}  ⚠ No se pudo iniciar acpid.service${NC}"

echo -e "${GREEN}✓ Servicios habilitados${NC}"

# Configurar hooks de git (validación sintaxis Lua al commitear)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -d "$SCRIPT_DIR/.githooks" ]; then
    git config core.hooksPath "$SCRIPT_DIR/.githooks" 2>/dev/null && echo -e "${GREEN}✓ Git hooks configurados${NC}"
fi

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

# Actualizar módulos externos antes de copiar (para que se copien las versiones frescas)
echo -e "${YELLOW}📦 Actualizando módulos externos (bling, rubato, layout-machi)...${NC}"
bash "$(dirname "$0")/update_modules.sh" 2>/dev/null || echo -e "${YELLOW}  ⚠ No se pudieron actualizar, se usan los versionados en el repo${NC}"

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

# Activar timer de limpieza automática (cada 3 días)
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable --now limpiar-sistema.timer 2>/dev/null && echo -e "${GREEN}✓ Timer de limpieza automática activado${NC}" || true

# Generar secrets.lua desde template si no existe
if [ ! -f "$HOME/.config/awesome/secrets.lua" ]; then
    cp config/awesome/secrets.lua.template "$HOME/.config/awesome/secrets.lua"
    echo -e "${YELLOW}🔑 Edita ~/.config/awesome/secrets.lua con tu API key de OpenWeather${NC}"
    echo -e "${YELLOW}   (consíguela gratis en https://openweathermap.org/api)${NC}"
fi

echo ""

# =====================================================================
# 6️⃣ INSTALAR FUENTES
# =====================================================================
echo -e "${YELLOW}🔤 Instalando fuentes...${NC}"

if [ -d "fonts" ] && [ "$(ls -A fonts)" ]; then
    local_fonts=0
    for f in fonts/*; do
        if [ ! -f "$HOME/.local/share/fonts/$(basename "$f")" ]; then
            cp "$f" "$HOME/.local/share/fonts/" 2>/dev/null || true
            local_fonts=$((local_fonts + 1))
        fi
    done
    [ "$local_fonts" -gt 0 ] && echo -e "${GREEN}✓ $local_fonts fuentes nuevas en ~/.local/share/fonts/${NC}" \
        || echo -e "${GREEN}✓ Fuentes de usuario ya instaladas${NC}"

    sys_fonts=0
    sudo mkdir -p /usr/share/fonts 2>/dev/null || true
    for f in fonts/*; do
        if [ ! -f "/usr/share/fonts/$(basename "$f")" ]; then
            sudo cp "$f" /usr/share/fonts/ 2>/dev/null || true
            sys_fonts=$((sys_fonts + 1))
        fi
    done
    [ "$sys_fonts" -gt 0 ] && echo -e "${GREEN}✓ $sys_fonts fuentes nuevas en /usr/share/fonts/${NC}" \
        || echo -e "${GREEN}✓ Fuentes del sistema ya instaladas${NC}"

    if [ "$local_fonts" -gt 0 ] || [ "$sys_fonts" -gt 0 ]; then
        echo -e "${YELLOW}🔄 Actualizando cache de fuentes...${NC}"
        fc-cache -f 2>/dev/null || true
        sudo fc-cache -f 2>/dev/null || true
        echo -e "${GREEN}✓ Cache de fuentes actualizado${NC}"
    fi
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

BACKUP_DIR="$HOME/.zsh-backup-$(date +%s)"

# Backup de configuraciones existentes del usuario
echo -e "${YELLOW}💾 Respaldando configuraciones existentes...${NC}"
mkdir -p "$BACKUP_DIR"

for f in "$HOME/.p10k.zsh" "$HOME/powerlevel10k" "$HOME/.fzf.zsh" "$HOME/.fzf"; do
    if [ -e "$f" ] && [ ! -L "$f" ]; then
        if cp -r "$f" "$BACKUP_DIR/" 2>/dev/null; then
            echo -e "${GREEN}  ✓ Respaldado: $f${NC}"
        else
            echo -e "${YELLOW}  ⚠ No se pudo respaldar: $f${NC}"
        fi
    fi
done

# Asegurar que ~/powerlevel10k exista (symlink al paquete del sistema o clonar)
if [ ! -d ~/powerlevel10k ]; then
    if [ -d /usr/share/zsh-theme-powerlevel10k ]; then
        ln -s /usr/share/zsh-theme-powerlevel10k ~/powerlevel10k
        echo -e "${GREEN}✓ ~/powerlevel10k -> /usr/share/zsh-theme-powerlevel10k${NC}"
    else
        echo -e "${YELLOW}⏬ Clonando powerlevel10k en ~/powerlevel10k...${NC}"
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
        echo -e "${GREEN}✓ powerlevel10k clonado en ~/powerlevel10k${NC}"
    fi
fi

# Asegurar que fzf.zsh exista
if [ ! -f ~/.fzf.zsh ] && [ -f /usr/share/fzf/key-bindings.zsh ]; then
    echo "source /usr/share/fzf/key-bindings.zsh" > ~/.fzf.zsh
    echo "source /usr/share/fzf/completion.zsh" >> ~/.fzf.zsh
    echo -e "${GREEN}✓ ~/.fzf.zsh creado${NC}"
fi

echo ""

# =====================================================================
# 🔟 CONFIGURAR ZSH PARA ROOT (symlinks)
# =====================================================================
echo -e "${YELLOW}👑 Configurando zsh para root...${NC}"

# Verificar que root tenga zsh como shell
ROOT_SHELL=$(sudo -u root sh -c 'echo "$SHELL"' 2>/dev/null || echo "")
if [ -n "$ROOT_SHELL" ] && [ "$ROOT_SHELL" != "/usr/bin/zsh" ] && [ "$ROOT_SHELL" != "/bin/zsh" ]; then
    echo -e "${YELLOW}⚠️  Cambiando shell de root a zsh...${NC}"
    sudo chsh -s /usr/bin/zsh root
    echo -e "${GREEN}✓ Shell de root cambiada a zsh${NC}"
fi

# Backup de configuraciones existentes de root
ROOT_BACKUP_DIR="/root/.zsh-backup-$(date +%s)"
echo -e "${YELLOW}💾 Respaldando configuraciones existentes de root...${NC}"
sudo mkdir -p "$ROOT_BACKUP_DIR" 2>/dev/null || true
for rf in "/root/.zshrc" "/root/.p10k.zsh" "/root/powerlevel10k" "/root/.fzf.zsh" "/root/.fzf"; do
    if sudo test -e "$rf" 2>/dev/null && ! sudo test -L "$rf" 2>/dev/null; then
        if sudo cp -r "$rf" "$ROOT_BACKUP_DIR/" 2>/dev/null; then
            echo -e "${GREEN}  ✓ Respaldado: $rf${NC}"
        else
            echo -e "${YELLOW}  ⚠ No se pudo respaldar: $rf${NC}"
        fi
    fi
done

echo -e "${YELLOW}🔗 Creando symlinks de zsh para root (apuntando a config del usuario)...${NC}"

USER_HOME="$HOME"

# .zshrc
if [ -f "$USER_HOME/.zshrc" ]; then
    sudo rm -f /root/.zshrc 2>/dev/null || true
    sudo ln -sf "$USER_HOME/.zshrc" /root/.zshrc
    echo -e "${GREEN}  ✓ /root/.zshrc -> $USER_HOME/.zshrc${NC}"
fi

# .p10k.zsh
if [ -f "$USER_HOME/.p10k.zsh" ]; then
    sudo rm -f /root/.p10k.zsh 2>/dev/null || true
    sudo ln -sf "$USER_HOME/.p10k.zsh" /root/.p10k.zsh
    echo -e "${GREEN}  ✓ /root/.p10k.zsh -> $USER_HOME/.p10k.zsh${NC}"
fi

# powerlevel10k
if [ -d "$USER_HOME/powerlevel10k" ]; then
    sudo rm -rf /root/powerlevel10k 2>/dev/null || true
    sudo ln -sfT "$USER_HOME/powerlevel10k" /root/powerlevel10k
    echo -e "${GREEN}  ✓ /root/powerlevel10k -> $USER_HOME/powerlevel10k${NC}"
fi

# .fzf.zsh
if [ -f "$USER_HOME/.fzf.zsh" ]; then
    sudo rm -f /root/.fzf.zsh 2>/dev/null || true
    sudo ln -sf "$USER_HOME/.fzf.zsh" /root/.fzf.zsh
    echo -e "${GREEN}  ✓ /root/.fzf.zsh -> $USER_HOME/.fzf.zsh${NC}"
fi

# .fzf (directorio de fzf)
if [ -d "$USER_HOME/.fzf" ]; then
    sudo rm -rf /root/.fzf 2>/dev/null || true
    sudo ln -sfT "$USER_HOME/.fzf" /root/.fzf
    echo -e "${GREEN}  ✓ /root/.fzf -> $USER_HOME/.fzf${NC}"
fi

echo -e "${GREEN}✓ Zsh de root configurada con los mismos archivos que el usuario${NC}"

echo ""

# =====================================================================
# 1️⃣1️⃣ INSTALAR MSCDOWN (Music Searcher & Downloader)
# =====================================================================
echo -e "${YELLOW}🎵 Instalando MSCDown (Music Searcher & Downloader)...${NC}"

# Inicializar submodulos (mscdown)
MSCDOWN_DIR="$(dirname "$0")/mscdown"
if [ -f "$MSCDOWN_DIR/install.sh" ]; then
    echo -e "${YELLOW}📦 Ejecutando instalador de mscdown...${NC}"
    chmod +x "$MSCDOWN_DIR/install.sh"

    # Copiar mscdown a $HOME/mscdown para que el alias funcione
    if [ ! -d "$HOME/mscdown" ]; then
        cp -r "$MSCDOWN_DIR" "$HOME/mscdown"
        echo -e "${GREEN}✓ mscdown copiado a $HOME/mscdown${NC}"
    fi

    # MSCDown install.sh contiene "sudo pacman -Syu" (full upgrade).
    # Parcheamos para evitar eso y solo instalar dependencias.
    sed -i 's/sudo pacman -Syu --noconfirm/sudo pacman -S --noconfirm --needed/' "$HOME/mscdown/install.sh"

    # Ejecutar instalador con "musica" como alias por defecto
    echo "musica" | bash "$HOME/mscdown/install.sh"
    echo -e "${GREEN}✓ MSCDown instalado (alias: musica)${NC}"
else
    echo -e "${YELLOW}⚠️  Submódulo mscdown no encontrado. Inicializando...${NC}"
    git submodule update --init --recursive
    chmod +x "$MSCDOWN_DIR/install.sh"

    if [ ! -d "$HOME/mscdown" ]; then
        cp -r "$MSCDOWN_DIR" "$HOME/mscdown"
    fi

    sed -i 's/sudo pacman -Syu --noconfirm/sudo pacman -S --noconfirm --needed/' "$HOME/mscdown/install.sh"

    echo "musica" | bash "$HOME/mscdown/install.sh"
    echo -e "${GREEN}✓ MSCDown instalado${NC}"
fi

echo ""

# =====================================================================
# 1️⃣2️⃣ CONFIGURACIÓN DE SDDM (SUGAR-CANDY)
# =====================================================================
echo -e "${YELLOW}🎨 Configurando tema de inicio de sesión (SDDM)...${NC}"

if command -v sddm &> /dev/null; then
    if [ -d "sddm/sugar-candy" ]; then
        echo -e "${YELLOW}🔒 Copiando tema sugar-candy...${NC}"
        sudo cp -rf sddm/sugar-candy /usr/share/sddm/themes/

        sudo mkdir -p /etc/sddm.conf.d 2>/dev/null || true

        echo -e "${YELLOW}⚙️  Activando Sugar-Candy...${NC}"
        sudo bash -c 'cat << EOF > /etc/sddm.conf.d/theme.conf
[Theme]
Current=sugar-candy
EOF'

        echo -e "${YELLOW}🔄 Habilitando servicio SDDM...${NC}"
        sudo systemctl enable sddm.service 2>/dev/null || echo -e "${YELLOW}  ⚠ No se pudo habilitar sddm.service${NC}"

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
echo "4. MSCDown (Music Searcher & Downloader):"
echo "   Escribe 'musica' (o el alias que elegiste) para abrir"
echo "   el buscador interactivo de música desde YouTube."
echo "   También puedes usarlo directo: musica <canción>"
echo ""
echo "5. Reinicia tu sesión o presiona Super+Ctrl+R en AwesomeWM"
echo ""
echo "════════════════════════════════════════════════════"
