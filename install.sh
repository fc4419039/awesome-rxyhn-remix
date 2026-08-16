#!/bin/bash

# AwesomeWM Remix - Script de instalación completo
# Portable: Arch/Manjaro/EndeavourOS, Debian/Ubuntu/Mint/Pop, Fedora/RHEL,
#           openSUSE, NixOS (declarativo)

# IMPORTANTE: este script NUNCA se detiene por errores.
# Cada sección intenta su trabajo, reporta (✓/⚠) y continúa.
# Nunca usar `set -e` ni `exit 1` aquí.

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Directorio del script: funciona aunque se ejecute desde otra ruta o vía symlink
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
cd "$SCRIPT_DIR" || echo -e "${RED}⚠ No se pudo entrar a $SCRIPT_DIR; las rutas relativas podrían fallar${NC}"

# =====================================================================
# 0️⃣ DETECTAR DISTRO
# =====================================================================
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID="$ID"
    DISTRO_LIKE="$ID_LIKE"
else
    DISTRO_ID="unknown"
    DISTRO_LIKE=""
fi

IS_ARCH=0
case "$DISTRO_ID $DISTRO_LIKE" in
    *arch*|*manjaro*|*endeavouros*|*garuda*|*artix*)
        IS_ARCH=1
        ;;
esac

echo -e "${CYAN}Distro detectada: ${DISTRO_NAME:-$DISTRO_ID}${NC}"

# =====================================================================
# 1️⃣ VERIFICAR E INSTALAR AUR HELPER (solo distros basadas en Arch)
# =====================================================================
AUR_HELPER=""

if [ "$IS_ARCH" = "1" ]; then
    echo -e "${YELLOW}🔍 Buscando AUR helper...${NC}"

    if command -v paru &> /dev/null; then
        echo -e "${GREEN}✓ Paru está instalado${NC}"
        AUR_HELPER="paru"
    elif command -v yay &> /dev/null; then
        echo -e "${GREEN}✓ yay está instalado${NC}"
        AUR_HELPER="yay"
    else
        echo -e "${YELLOW}⚠️  No se encontró AUR helper. Instalando yay...${NC}"

        # makepkg NO puede ejecutarse como root
        if [ "$(id -u)" -eq 0 ]; then
            echo -e "${YELLOW}⚠️  Eres root: makepkg no funciona como root.${NC}"
            echo -e "${YELLOW}  Las dependencias se instalarán desde los repos oficiales; instala yay después como usuario normal.${NC}"
        else
            # Instalar dependencias necesarias
            echo -e "${YELLOW}📦 Instalando base-devel y git...${NC}"
            sudo pacman -S --needed --noconfirm base-devel git 2>/dev/null \
                || echo -e "${YELLOW}⚠️  No se pudieron instalar base-devel/git. Continuando...${NC}"

            # Crear directorio temporal
            TEMPDIR=$(mktemp -d 2>/dev/null)
            if [ -n "$TEMPDIR" ] && [ -d "$TEMPDIR" ]; then
                echo -e "${YELLOW}📁 Directorio temporal: $TEMPDIR${NC}"

                # Clonar yay-bin (con reintentos por si hay red inestable o AUR caído)
                CLONADO=false
                for intento in 1 2 3; do
                    if git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$TEMPDIR/yay-bin" 2>/dev/null; then
                        CLONADO=true
                        break
                    fi
                    echo -e "${YELLOW}⚠️  Intento $intento/3 falló (¿sin red o AUR caído?). Reintentando en 5s...${NC}"
                    sleep 5
                done

                # Compilar e instalar (puede tardar unos minutos)
                if [ "$CLONADO" = true ] && ( cd "$TEMPDIR/yay-bin" 2>/dev/null ); then
                    echo -e "${YELLOW}🔨 Compilando e instalando yay (puede tardar)...${NC}"
                    ( cd "$TEMPDIR/yay-bin" && makepkg -si --noconfirm ) \
                        && echo -e "${GREEN}✓ yay compilado e instalado${NC}" \
                        || echo -e "${YELLOW}⚠️  La compilación de yay falló. Puedes instalarlo después manualmente:
   git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si${NC}"
                else
                    echo -e "${YELLOW}⚠️  No se pudo clonar o compilar yay desde el AUR (¿sin red?). Continuando con repos oficiales...${NC}"
                fi

                # Limpiar
                rm -rf "$TEMPDIR" 2>/dev/null || true
            else
                echo -e "${YELLOW}⚠️  No se pudo crear el directorio temporal. Saltando instalación de yay.${NC}"
            fi
        fi

        # Verificar instalación
        if command -v yay &> /dev/null; then
            echo -e "${GREEN}✓ yay instalado correctamente${NC}"
            AUR_HELPER="yay"
        else
            echo -e "${YELLOW}⚠️  yay no disponible. Se usarán solo los repos oficiales; los paquetes AUR los puedes instalar después.${NC}"
        fi
    fi
fi

echo ""

# =====================================================================
# 2️⃣ INSTALAR DEPENDENCIAS (multi-distro)
# =====================================================================
echo -e "${YELLOW}📦 Instalando dependencias...${NC}"

# Mapear distro a archivo de deps
case "$DISTRO_ID" in
    arch|manjaro|endeavouros|garuda|artix)
        DEPS_FILE="docs/deps-arch.txt"
        PKG_CHECK="pacman -Q"
        PKG_INSTALL="${AUR_HELPER:-pacman} -S --needed --noconfirm"
        ;;
    ubuntu|debian|linuxmint|pop|elementary|zorin)
        DEPS_FILE="docs/deps-debian.txt"
        PKG_CHECK="dpkg -s"
        PKG_INSTALL="sudo apt-get update && sudo apt-get install -y"
        ;;
    fedora|rhel|centos|rocky|almalinux|nobara)
        DEPS_FILE="docs/deps-fedora.txt"
        PKG_CHECK="rpm -q"
        PKG_INSTALL="sudo dnf install -y"
        ;;
    opensuse-tumbleweed|opensuse-leap|suse|sled)
        DEPS_FILE="docs/deps-opensuse.txt"
        PKG_CHECK="rpm -q"
        PKG_INSTALL="sudo zypper install -y"
        ;;
    nixos)
        DEPS_FILE="docs/deps-nixos.txt"
        PKG_CHECK="echo 'NixOS: usa home-manager'"
        PKG_INSTALL="echo 'NixOS: config declarativa en docs/deps-nixos.txt'"
        ;;
    *)
        # Fallback por ID_LIKE
        if [[ "$DISTRO_LIKE" == *arch* ]]; then
            DEPS_FILE="docs/deps-arch.txt"
            PKG_CHECK="pacman -Q"
            PKG_INSTALL="${AUR_HELPER:-pacman} -S --needed --noconfirm"
        elif [[ "$DISTRO_LIKE" == *debian* ]]; then
            DEPS_FILE="docs/deps-debian.txt"
            PKG_CHECK="dpkg -s"
            PKG_INSTALL="sudo apt-get update && sudo apt-get install -y"
        elif [[ "$DISTRO_LIKE" == *fedora* ]] || [[ "$DISTRO_LIKE" == *rhel* ]]; then
            DEPS_FILE="docs/deps-fedora.txt"
            PKG_CHECK="rpm -q"
            PKG_INSTALL="sudo dnf install -y"
        elif [[ "$DISTRO_LIKE" == *opensuse* ]] || [[ "$DISTRO_LIKE" == *suse* ]]; then
            DEPS_FILE="docs/deps-opensuse.txt"
            PKG_CHECK="rpm -q"
            PKG_INSTALL="sudo zypper install -y"
        else
            DEPS_FILE="docs/deps-arch.txt"
            PKG_CHECK="echo 'Distro no detectada'"
            PKG_INSTALL="echo 'Instala manualmente desde docs/deps-arch.txt'"
        fi
        ;;
esac

echo -e "${CYAN}Archivo de deps:  $DEPS_FILE${NC}"

if [ "$DISTRO_ID" = "nixos" ]; then
    echo -e "${YELLOW}⚠️  NixOS detectado: usa Home Manager / flake.nix${NC}"
    echo -e "${YELLOW}    Ver $DEPS_FILE para configuración declarativa${NC}"
    echo -e "${GREEN}✓ Saltando instalación de paquetes (gestión declarativa)${NC}"
else
    # Leer paquetes del archivo (ignorar comentarios y líneas vacías)
    if [ ! -f "$DEPS_FILE" ]; then
        echo -e "${YELLOW}⚠️  No se encontró $DEPS_FILE. Saltando instalación de dependencias.${NC}"
        packages=()
    else
        mapfile -t packages < <(grep -v '^#' "$DEPS_FILE" | grep -v '^$' | sed 's/#.*//' | xargs -n1)
    fi

    to_install=()
    for pkg in "${packages[@]}"; do
        if ! eval "$PKG_CHECK $pkg" > /dev/null 2>&1; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        echo -e "${YELLOW}📦 Instalando paquetes faltantes: ${to_install[*]}${NC}"

        if ! eval "$PKG_INSTALL ${to_install[*]}"; then
            echo -e "${YELLOW}⚠️  Algunos paquetes fallaron. Intentando de nuevo en modo individual...${NC}"
            for pkg in "${to_install[@]}"; do
                if ! eval "$PKG_CHECK $pkg" > /dev/null 2>&1; then
                    eval "$PKG_INSTALL $pkg" \
                        || echo -e "${YELLOW}⚠️  No se pudo instalar $pkg, continuando...${NC}"
                fi
            done
        fi
    else
        echo -e "${GREEN}✓ Todos los paquetes ya están instalados. Saltando.${NC}"
    fi

    echo -e "${GREEN}✓ Dependencias instaladas${NC}"
fi

echo ""

# =====================================================================
# 2b️⃣ INSTALAR OPENCODE (AI Agent)
# =====================================================================
echo -e "${YELLOW}🤖 Verificando OpenCode...${NC}"

# Verificar si el comando existe o si el binario está en ~/.opencode/bin/opencode
if command -v opencode &> /dev/null || [ -f "$HOME/.opencode/bin/opencode" ]; then
    echo -e "${GREEN}✓ OpenCode ya está instalado.${NC}"
else
    echo -e "${YELLOW}📦 Instalando OpenCode...${NC}"
    if curl -fsSL https://opencode.ai/install | bash; then
        echo -e "${GREEN}✓ OpenCode instalado.${NC}"
    else
        echo -e "${YELLOW}⚠️  Falló la instalación de OpenCode. Puedes instalarlo manualmente después.${NC}"
    fi
fi

echo ""

# =====================================================================
# 3️⃣ HABILITAR SERVICIOS
# =====================================================================
echo -e "${YELLOW}🔄 Habilitando servicios...${NC}"

sudo systemctl enable acpid.service 2>/dev/null && sudo systemctl start acpid.service 2>/dev/null \
    && echo -e "${GREEN}✓ acpid habilitado${NC}" \
    || echo -e "${YELLOW}⚠️  No se pudo habilitar acpid (¿paquete no instalado o sin sudo?). Continuando...${NC}"

echo -e "${GREEN}✓ Servicios habilitados${NC}"

# Configurar hooks de git (validación sintaxis Lua al commitear)
if [ -d "$SCRIPT_DIR/.git" ]; then
    git config core.hooksPath "$SCRIPT_DIR/.githooks" 2>/dev/null \
        && echo -e "${GREEN}✓ Git hooks configurados${NC}" \
        || echo -e "${YELLOW}⚠️  No se pudieron configurar los git hooks${NC}"
else
    echo -e "${YELLOW}⚠️  No es un repositorio git (¿descarga ZIP?). Saltando git hooks.${NC}"
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
mkdir -p ~/.config/todo || true
mkdir -p ~/.config/mpd/playlists

echo -e "${GREEN}✓ Directorios creados${NC}"

echo ""

# =====================================================================
# 5️⃣ COPIAR ARCHIVOS DE CONFIGURACIÓN
# =====================================================================
echo -e "${YELLOW}📦 Copiando archivos de configuración...${NC}"

# Verificar que los directorios existan (avisar y continuar, nunca detener)
if [ ! -d "config" ]; then
    echo -e "${YELLOW}⚠️  Carpeta 'config' no encontrada. Saltando copia de configuración.${NC}"
else
    # Copiar archivos de configuración excluyendo directorios .git
    if command -v rsync &> /dev/null; then
        rsync -av --exclude='.git' --exclude='.codebak' config/ ~/.config/ \
            || echo -e "${YELLOW}⚠️  Falló la copia de config/ a ~/.config/. Continuando...${NC}"
    else
        echo -e "${YELLOW}  rsync no encontrado, usando cp...${NC}"
        mkdir -p ~/.config 2>/dev/null || true
        cp -r config/. ~/.config/ 2>/dev/null \
            || echo -e "${YELLOW}⚠️  Falló la copia de config/ a ~/.config/. Continuando...${NC}"
    fi
    rm -rf ~/.config/awesome/.codebak 2>/dev/null || true
fi

if [ -d "bin" ] && [ "$(ls -A bin 2>/dev/null)" ]; then
    cp -r bin/* ~/.local/bin/ \
        || echo -e "${YELLOW}⚠️  Falló la copia de bin/ a ~/.local/bin/. Continuando...${NC}"
else
    echo -e "${YELLOW}⚠️  Carpeta bin vacía o no encontrada, saltando${NC}"
fi

# Copiar .profile si existe
if [ -f ".profile" ]; then
    cp .profile ~/
fi

# Copiar .Xresources si existe
if [ -f "misc/.Xresources" ]; then
    cp misc/.Xresources ~/.Xresources 2>/dev/null || true
    echo -e "${GREEN}✓ .Xresources instalado${NC}"
fi

# Copiar .zprofile si existe (SDDM con zsh lee ~/.zprofile, no ~/.profile)
if [ -f "misc/.zprofile" ]; then
    cp misc/.zprofile ~/.zprofile 2>/dev/null || true
    echo -e "${GREEN}✓ .zprofile instalado${NC}"
fi

# Copiar .profile desde misc/ si no se copió antes
if [ -f "misc/.profile" ] && [ ! -f "$HOME/.profile" ]; then
    cp misc/.profile ~/ 2>/dev/null || true
    echo -e "${GREEN}✓ .profile instalado desde misc/${NC}"
fi

echo -e "${GREEN}✓ Archivos de configuración copiados${NC}"

# Generar secrets.lua desde el template si no existe (config del clima, sin API key)
if [ -f ~/.config/awesome/secrets.lua.template ] && [ ! -f ~/.config/awesome/secrets.lua ]; then
    cp ~/.config/awesome/secrets.lua.template ~/.config/awesome/secrets.lua
    echo -e "${GREEN}✓ secrets.lua generado desde el template${NC}"
fi

# Actualizar módulos externos a sus últimas versiones
echo -e "${YELLOW}📦 Actualizando módulos externos (bling, rubato, layout-machi)...${NC}"
bash "$SCRIPT_DIR/update_modules.sh" 2>/dev/null || echo -e "${YELLOW}  ⚠ No se pudieron actualizar, se usan los versionados en el repo${NC}"

# Activar timer de limpieza automática (cada 3 días)
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable --now limpiar-sistema.timer 2>/dev/null && echo -e "${GREEN}✓ Timer de limpieza automática activado${NC}" || true

# Activar servicios de usuario (mpd, mpd-mpris, udiskie) si hay sesión
# (cada uno se activa por separado: que uno no exista no bloquea a los demás)
for svc in mpd.service mpd-mpris.service udiskie.service; do
    systemctl --user enable --now "$svc" 2>/dev/null \
        && echo -e "${GREEN}✓ Servicio de usuario activado: $svc${NC}" \
        || echo -e "${YELLOW}⚠️  $svc no se pudo activar (¿no instalado o sin sesión activa?). Se activará al iniciar sesión.${NC}"
done

echo ""
echo -e "${YELLOW}🔐 Instalando librerías PAM para Lua (lockscreen)...${NC}"

# Los headers de PAM se instalan con el paquete del distro (pam / libpam0g-dev / pam-devel)
# ya incluido en docs/deps-*.txt (sección LUA / DEPS). Aquí solo falta lua-pam via luarocks.
if command -v luarocks &> /dev/null; then
    luarocks install lua-pam 2>/dev/null || echo -e "${YELLOW}⚠️  lua-pam ya instalado o falló (requiere headers de PAM: libpam0g-dev / pam-devel)${NC}"
else
    echo -e "${YELLOW}⚠️  luarocks no encontrado, saltando lua-pam${NC}"
fi

echo -e "${GREEN}✓ liblua_pam instalado${NC}"

# =====================================================================
# 6️⃣ INSTALAR FUENTES
# =====================================================================
echo -e "${YELLOW}🔤 Instalando fuentes...${NC}"

if [ -d "fonts" ] && [ "$(ls -A fonts)" ]; then
    # Instalar en ~/.local/share/fonts/ (usuario actual)
    cp -r fonts/* ~/.local/share/fonts/ 2>/dev/null \
        || echo -e "${YELLOW}⚠️  Falló la copia de fuentes a ~/.local/share/fonts/. Continuando...${NC}"
    echo -e "${GREEN}✓ Fuentes instaladas en ~/.local/share/fonts/${NC}"

    # Instalar en /usr/share/fonts/ (sistema completo)
    echo -e "${YELLOW}⚠️  Instalando fuentes en /usr/share/fonts/ (requiere sudo)...${NC}"
    sudo mkdir -p /usr/share/fonts && sudo cp -r fonts/* /usr/share/fonts/ \
        && echo -e "${GREEN}✓ Fuentes instaladas en /usr/share/fonts/${NC}" \
        || echo -e "${YELLOW}⚠️  No se pudieron instalar las fuentes en /usr/share/fonts (sin sudo). Las del usuario siguen activas.${NC}"

    # Actualizar cache de fuentes
    echo -e "${YELLOW}🔄 Actualizando cache de fuentes...${NC}"
    fc-cache -fv >/dev/null 2>&1 || true
    sudo fc-cache -fv >/dev/null 2>&1 || true
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
    cp -rf fondos/* ~/fondos/ 2>/dev/null \
        || echo -e "${YELLOW}⚠️  Falló la copia de fondos a ~/fondos/. Continuando...${NC}"
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
        cp ~/.zshrc ~/.zshrc.bak.$(date +%s) 2>/dev/null || echo -e "${YELLOW}⚠️  No se pudo crear el respaldo de .zshrc. Continuando...${NC}"
    fi
    cp .zshrc ~/ 2>/dev/null \
        || echo -e "${YELLOW}⚠️  No se pudo copiar .zshrc. Continuando...${NC}"
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

# Config de powerlevel10k: respetar la del usuario si ya existe;
# si no hay ninguna, instalar la incluida en el repo
if [ -f "misc/.p10k.zsh" ] && [ ! -f ~/.p10k.zsh ]; then
    cp misc/.p10k.zsh ~/.p10k.zsh
    echo -e "${GREEN}✓ .p10k.zsh instalado (config de powerlevel10k del repo)${NC}"
fi

echo ""

# =====================================================================
# 🔟 INSTALAR MSCDOWN (Music Searcher & Downloader)
# =====================================================================
echo -e "${YELLOW}🎵 Instalando MSCDown (Music Searcher & Downloader)...${NC}"

# Inicializar submodulos (mscdown)
ROOT_DIR="$SCRIPT_DIR"
MSCDOWN_INSTALLER="$ROOT_DIR/mscdown/install.sh"

if [ ! -f "$MSCDOWN_INSTALLER" ] && [ -d "$ROOT_DIR/.git" ]; then
    echo -e "${YELLOW}⚠️  Submódulo mscdown no encontrado. Inicializando...${NC}"
    git submodule update --init --recursive || echo -e "${YELLOW}⚠️  Falló la inicialización del submódulo.${NC}"
fi

if [ -f "$MSCDOWN_INSTALLER" ]; then
    echo -e "${YELLOW}📦 Ejecutando instalador de mscdown...${NC}"
    chmod +x "$MSCDOWN_INSTALLER" 2>/dev/null || true
    ( cd "$ROOT_DIR/mscdown" && ./install.sh ) || echo -e "${YELLOW}⚠️  El instalador de MSCDown falló, continuando...${NC}"

    # Colocar mscdown en ~/mscdown (donde apunta el alias creado por su instalador)
    if [ ! -d "$HOME/mscdown" ]; then
        echo -e "${YELLOW}📂 Colocando mscdown en ~/mscdown...${NC}"
        mkdir -p "$HOME/mscdown" 2>/dev/null || true
        if ! rsync -a --exclude='.git' --exclude='__pycache__' "$ROOT_DIR/mscdown/" "$HOME/mscdown/" 2>/dev/null; then
            cp -r "$ROOT_DIR/mscdown/." "$HOME/mscdown/" 2>/dev/null || true
        fi
        if [ -f "$HOME/mscdown/main.py" ]; then
            echo -e "${GREEN}✓ mscdown colocado en ~/mscdown${NC}"
        else
            echo -e "${YELLOW}⚠️  No se pudo copiar mscdown a ~/mscdown. El alias 'musica' no funcionará hasta copiarlo manualmente.${NC}"
        fi
    fi

    echo -e "${GREEN}✓ MSCDown instalado${NC}"
else
    echo -e "${YELLOW}⚠️  No se encontró mscdown (ni como submódulo). Puedes clonarlo después: git submodule update --init.${NC}"
fi

echo ""

# =====================================================================
# 1️⃣1️⃣ CONFIGURACIÓN DE SDDM (COMPATIBLE CON QT6)
# =====================================================================
echo -e "${YELLOW}🎨 Configurando tema de inicio de sesión SDDM...${NC}"

if command -v sddm &> /dev/null; then
    sudo mkdir -p /etc/sddm.conf.d 2>/dev/null \
        || echo -e "${YELLOW}⚠️  No se pudo crear /etc/sddm.conf.d (¿sin sudo?). La config del tema fallará pero el script continúa.${NC}"

    THEME_DIR=""
    THEME_NAME=""

    # 1) Tema incluido en el repo (sddm-astronaut-theme con estilo sugar-candy ya aplicado)
    if [ -d "$SCRIPT_DIR/sddm/sddm-astronaut-theme" ]; then
        echo -e "${YELLOW}📦 Instalando tema sddm-astronaut-theme desde el repositorio...${NC}"
        sudo rm -rf /usr/share/sddm/themes/sddm-astronaut-theme
        sudo cp -r "$SCRIPT_DIR/sddm/sddm-astronaut-theme" /usr/share/sddm/themes/sddm-astronaut-theme
        sudo chown -R root:root /usr/share/sddm/themes/sddm-astronaut-theme
        THEME_DIR="/usr/share/sddm/themes/sddm-astronaut-theme"
        THEME_NAME="sddm-astronaut-theme"
    else
        # 2) Fallback: instalar desde AUR (solo distros Arch con AUR helper)
        if [ -n "$AUR_HELPER" ]; then
            echo -e "${YELLOW}📦 Instalando sddm-astronaut-theme desde AUR...${NC}"
            $AUR_HELPER -S --needed --noconfirm sddm-astronaut-theme 2>/dev/null || true
        else
            echo -e "${YELLOW}⚠️  Tema no incluido en el repo y sin AUR helper para instalarlo.${NC}"
        fi
        if [ -d "/usr/share/sddm/themes/sddm-astronaut-theme" ]; then
            THEME_DIR="/usr/share/sddm/themes/sddm-astronaut-theme"
            THEME_NAME="sddm-astronaut-theme"
        elif [ -d "/usr/share/sddm/themes/astronaut" ]; then
            THEME_DIR="/usr/share/sddm/themes/astronaut"
            THEME_NAME="astronaut"
        fi
    fi

    if [ -n "$THEME_DIR" ]; then
        # Crear carpeta compartida para fondos de SDDM (escribible por el usuario)
        echo -e "${YELLOW}📂 Configurando carpeta compartida de fondos SDDM...${NC}"
        sudo mkdir -p /usr/share/sddm/backgrounds
        sudo chown "$USER":"$USER" /usr/share/sddm/backgrounds
        sudo chmod 775 /usr/share/sddm/backgrounds

        # Copiar un fondo inicial desde ~/fondos si existe
        FONDO_SELECCIONADO=""
        if [ -d "$HOME/fondos" ]; then
            FONDO_SELECCIONADO=$(find "$HOME/fondos" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \) | head -n 1)
        fi

        if [ -n "$FONDO_SELECCIONADO" ]; then
            echo -e "${YELLOW}🖼️ Copiando fondo inicial ($FONDO_SELECCIONADO) a la carpeta compartida...${NC}"
            sudo cp "$FONDO_SELECCIONADO" /usr/share/sddm/backgrounds/sddm_wallpaper.jpg
            sudo chown "$USER":"$USER" /usr/share/sddm/backgrounds/sddm_wallpaper.jpg
            sudo chmod 644 /usr/share/sddm/backgrounds/sddm_wallpaper.jpg
        fi

        # Configurar el tema para usar la ruta fija compartida
        echo -e "${YELLOW}⚙️  Apuntando tema a la carpeta compartida...${NC}"

        # Aplicar configuración al tema (formulario izquierdo, acento naranja, Welcome!, blur parcial)
        ASTRONAUT_CONF="$THEME_DIR/Themes/astronaut.conf"
        if [ -f "$ASTRONAUT_CONF" ]; then
            sudo bash -c 'cat << EOF > '"$ASTRONAUT_CONF"'
[General]
#################### General ####################

ScreenWidth="1366"
ScreenHeight="768"
ScreenPadding=""

Font="Noto Sans"
FontSize=""

KeyboardSize="0.4"

RoundCorners="20"

Locale=""
HourFormat="HH:mm"
DateFormat="dddd, d of MMMM"

HeaderText="Welcome!"

#################### Background ####################

BackgroundPlaceholder=""
Background="/usr/share/sddm/backgrounds/sddm_wallpaper.jpg"
BackgroundSpeed=""
PauseBackground=""
DimBackground="0.0"
CropBackground="true"
BackgroundHorizontalAlignment="center"
BackgroundVerticalAlignment="center"

#################### Colors ####################

HeaderTextColor="#ffffff"
DateTextColor="#ffffff"
TimeTextColor="#ffffff"

FormBackgroundColor="#444444"
BackgroundColor="#444444"
DimBackgroundColor="#444444"

LoginFieldBackgroundColor="#ffffff"
PasswordFieldBackgroundColor="#ffffff"
LoginFieldTextColor="#ffffff"
PasswordFieldTextColor="#ffffff"
UserIconColor="#ffffff"
PasswordIconColor="#ffffff"

PlaceholderTextColor="#ffffff"
WarningColor="#fb884f"

LoginButtonTextColor="#ffffff"
LoginButtonBackgroundColor="#ffffff"
SystemButtonsIconsColor="#F8F8F2"
SessionButtonTextColor="#F8F8F2"
VirtualKeyboardButtonTextColor="#F8F8F2"

DropdownTextColor="#ffffff"
DropdownSelectedBackgroundColor="#fb884f"
DropdownBackgroundColor="#444444"

HighlightTextColor="#ffffff"
HighlightBackgroundColor="#fb884f"
HighlightBorderColor="#fb884f"

HoverUserIconColor="#fb884f"
HoverPasswordIconColor="#fb884f"
HoverSystemButtonsIconsColor="#fb884f"
HoverSessionButtonTextColor="#fb884f"
HoverVirtualKeyboardButtonTextColor="#fb884f"

#################### Form ####################

PartialBlur="true"
FullBlur="false"
BlurMax="64"
Blur="1.0"

HaveFormBackground="false"
FormPosition="left"

#################### Virtual Keyboard ####################

VirtualKeyboardPosition="left"

#################### Interface Behavior ####################

HideVirtualKeyboard="false"
HideSystemButtons="false"
HideLoginButton="false"

UseRealName="false"
ForceLastUser="true"
PasswordFocus="true"
HideCompletePassword="false"
AllowEmptyPassword="false"
BypassSystemButtonsChecks="false"
RightToLeftLayout="false"

#################### Translation ####################

TranslatePlaceholderUsername=""
TranslatePlaceholderPassword=""
TranslateLogin=""
TranslateLoginFailedWarning=""
TranslateCapslockWarning=""
TranslateSuspend=""
TranslateHibernate=""
TranslateReboot=""
TranslateShutdown=""
TranslateSessionSelection=""
TranslateVirtualKeyboardButtonOn=""
TranslateVirtualKeyboardButtonOff=""
EOF'
        elif [ -f "$THEME_DIR/theme.conf" ]; then
            sudo sed -i 's|^Background=.*|Background="/usr/share/sddm/backgrounds/sddm_wallpaper.jpg"|' "$THEME_DIR/theme.conf"
        fi

        echo -e "${YELLOW}⚙️  Activando tema $THEME_NAME...${NC}"
        sudo bash -c "cat << EOF > /etc/sddm.conf.d/theme.conf
[Theme]
Current=$THEME_NAME
EOF"
        echo -e "${GREEN}✓ SDDM configurado con el tema $THEME_NAME e imagen de ~/fondos${NC}"
    else
        echo -e "${YELLOW}⚠️  No se encontró el tema sddm-astronaut-theme. Instálalo manualmente (AUR: $AUR_HELPER -S sddm-astronaut-theme)${NC}"
    fi

    echo -e "${YELLOW}🔄 Habilitando servicio SDDM...${NC}"
    sudo systemctl enable sddm.service 2>/dev/null \
        && echo -e "${GREEN}✓ Servicio sddm habilitado${NC}" \
        || echo -e "${YELLOW}⚠️  No se pudo habilitar el servicio sddm (¿sin systemd o sin sudo?). Actívalo manualmente después.${NC}"
else
    echo -e "${YELLOW}⚠️  SDDM no está instalado. Saltando configuración.${NC}"
fi

echo ""

# =====================================================================
# 1️⃣2️⃣ CONFIGURAR ZSH DE ROOT (symlinks a la config del usuario)
# =====================================================================
echo -e "${YELLOW}👑 Configurando zsh de root (symlinks)...${NC}"
bash "$SCRIPT_DIR/zsh-root.sh" || echo -e "${YELLOW}⚠️  No se pudo configurar root (requiere sudo). Puedes ejecutar zsh-root.sh después.${NC}"

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
echo "3. Control de volumen:"
echo "   El script notif-sink-setup.sh (autostart) crea sinks"
echo "   independientes 'system_sink' (programas) y 'notifications'."
echo "   Usa Super+v para abrir el panel de volumen (dashboard):"
echo "   sliders por app, notificaciones separadas, mute por fila."
echo "   Ctrl+scroll en el widget de volumen = volumen de notificaciones."
echo ""
echo "4. MSCDown (Music Searcher & Downloader):"
echo "   Escribe 'musica' (o el alias que elegiste) para abrir"
echo "   el buscador interactivo de música desde YouTube."
echo "   También puedes usarlo directo: musica <canción>"
echo ""
echo "5. Reinicia tu sesión o presiona Super+Ctrl+R en AwesomeWM"
echo ""
echo "════════════════════════════════════════════════════"
