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
# 0️⃣ PRE-FLIGHT CHECKS
# =====================================================================
echo -e "${CYAN}🔍 Ejecutando pre-flight checks...${NC}"

# Verificar conectividad a internet
if ! ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Sin conexión a internet detectada. Algunas instalaciones fallarán.${NC}"
fi

# Verificar sudo
if ! sudo -n true 2>/dev/null; then
    echo -e "${YELLOW}⚠️  sudo requiere contraseña. Se pedirá durante la instalación.${NC}"
fi

# Verificar espacio en disco (mínimo 2GB libres en /home)
HOME_AVAIL=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$HOME_AVAIL" -lt 2 ]; then
    echo -e "${YELLOW}⚠️  Poco espacio en $HOME (${HOME_AVAIL}GB libres). Mínimo recomendado: 2GB.${NC}"
fi

echo -e "${GREEN}✓ Pre-flight checks completados${NC}"
echo ""

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

echo ""

# =====================================================================
# 0️⃣b DETECTAR VM E INSTALAR HERRAMIENTAS DE INVITADO
# =====================================================================
echo -e "${CYAN}🔍 Verificando entorno virtualizado...${NC}"

VM_TYPE=""
if systemd-detect-virt -q 2>/dev/null; then
    VM_TYPE=$(systemd-detect-virt 2>/dev/null)
fi

# Detección adicional por si systemd-detect-virt no está disponible
if [ -z "$VM_TYPE" ]; then
    if grep -qi "virtualbox\|vbox" /sys/class/dmi/id/sys_vendor 2>/dev/null || \
       grep -qi "virtualbox\|vbox" /sys/class/dmi/id/board_name 2>/dev/null; then
        VM_TYPE="oracle"
    elif grep -qi "vmware" /sys/class/dmi/id/sys_vendor 2>/dev/null; then
        VM_TYPE="vmware"
    elif grep -qi "qemu\|kvm\|red hat" /sys/class/dmi/id/sys_vendor 2>/dev/null; then
        VM_TYPE="kvm"
    elif grep -qi "microsoft" /sys/class/dmi/id/sys_vendor 2>/dev/null && \
         grep -qi "virtual\|hyper-v" /sys/class/dmi/id/board_name 2>/dev/null; then
        VM_TYPE="microsoft"
    fi
fi

IS_VM=0
if [ -n "$VM_TYPE" ] && [ "$VM_TYPE" != "none" ]; then
    IS_VM=1
    echo -e "${YELLOW}⚠️  Entorno virtualizado detectado: ${VM_TYPE}${NC}"

    # Instalar herramientas de invitado según el hypervisor
    install_vm_tools() {
        local pkg_check="$1"
        local pkg_install="$2"

        case "$VM_TYPE" in
            kvm|qemu|oracle|vmware|microsoft|xen|parallels)
                echo -e "${YELLOW}📦 Instalando herramientas de invitado para ${VM_TYPE}...${NC}"

                # --- QEMU/KVM: spice-vdagent + qemu-guest-agent ---
                if echo "$VM_TYPE" | grep -qi "kvm\|qemu"; then
                    for agent in spice-vdagent qemu-guest-agent; do
                        if eval "$pkg_check $agent" >/dev/null 2>&1; then
                            echo -e "${GREEN}  ✓ $agent ya instalado${NC}"
                        else
                            echo -e "${YELLOW}  📦 Instalando $agent...${NC}"
                            eval "$pkg_install $agent" 2>/dev/null \
                                && echo -e "${GREEN}  ✓ $agent instalado${NC}" \
                                || echo -e "${YELLOW}  ⚠️  No se pudo instalar $agent (puede no existir en todos los repos)${NC}"
                        fi
                    done
                    # Mesa-utils para verificar OpenGL
                    if eval "$pkg_check mesa-utils" >/dev/null 2>&1; then
                        echo -e "${GREEN}  ✓ mesa-utils ya instalado${NC}"
                    else
                        eval "$pkg_install mesa-utils" 2>/dev/null \
                            && echo -e "${GREEN}  ✓ mesa-utils instalado${NC}" || true
                    fi
                fi

                # --- VirtualBox: virtualbox-guest-utils ---
                if echo "$VM_TYPE" | grep -qi "oracle\|virtualbox\|vbox"; then
                    if eval "$pkg_check virtualbox-guest-utils" >/dev/null 2>&1; then
                        echo -e "${GREEN}  ✓ virtualbox-guest-utils ya instalado${NC}"
                    else
                        echo -e "${YELLOW}  📦 Instalando virtualbox-guest-utils...${NC}"
                        eval "$pkg_install virtualbox-guest-utils" 2>/dev/null \
                            && echo -e "${GREEN}  ✓ virtualbox-guest-utils instalado${NC}" \
                            || echo -e "${YELLOW}  ⚠️  No se pudo instalar virtualbox-guest-utils${NC}"
                    fi
                fi

                # --- VMware: open-vm-tools ---
                if echo "$VM_TYPE" | grep -qi "vmware"; then
                    if eval "$pkg_check open-vm-tools" >/dev/null 2>&1; then
                        echo -e "${GREEN}  ✓ open-vm-tools ya instalado${NC}"
                    else
                        echo -e "${YELLOW}  📦 Instalando open-vm-tools...${NC}"
                        eval "$pkg_install open-vm-tools" 2>/dev/null \
                            && echo -e "${GREEN}  ✓ open-vm-tools instalado${NC}" \
                            || echo -e "${YELLOW}  ⚠️  No se pudo instalar open-vm-tools${NC}"
                    fi
                fi

                # --- Hyper-V: hyperv-daemons / linux-tools ---
                if echo "$VM_TYPE" | grep -qi "microsoft"; then
                    for hyperv_pkg in hyperv-daemons linux-tools; do
                        if eval "$pkg_check $hyperv_pkg" >/dev/null 2>&1; then
                            echo -e "${GREEN}  ✓ $hyperv_pkg ya instalado${NC}"
                        else
                            eval "$pkg_install $hyperv_pkg" 2>/dev/null \
                                && echo -e "${GREEN}  ✓ $hyperv_pkg instalado${NC}" || true
                        fi
                    done
                fi

                # --- Xen/XenServer ---
                if echo "$VM_TYPE" | grep -qi "xen"; then
                    if eval "$pkg_check xen-guest-tools" >/dev/null 2>&1; then
                        echo -e "${GREEN}  ✓ xen-guest-tools ya instalado${NC}"
                    else
                        eval "$pkg_install xen-guest-tools" 2>/dev/null \
                            && echo -e "${GREEN}  ✓ xen-guest-tools instalado${NC}" || true
                    fi
                fi

                # --- Parallels ---
                if echo "$VM_TYPE" | grep -qi "parallels"; then
                    if eval "$pkg_check parallels-tools" >/dev/null 2>&1; then
                        echo -e "${GREEN}  ✓ parallels-tools ya instalado${NC}"
                    else
                        eval "$pkg_install parallels-tools" 2>/dev/null \
                            && echo -e "${GREEN}  ✓ parallels-tools instalado${NC}" \
                            || echo -e "${YELLOW}  ⚠️  Instala Parallels Tools manualmente desde el menú de Parallels${NC}"
                    fi
                fi
                ;;
        esac
    }

    # Ejecutar instalación de herramientas de invitado
    case "$DISTRO_ID $DISTRO_LIKE" in
        *arch*|*manjaro*|*endeavouros*|*garuda*|*artix*)
            install_vm_tools "pacman -Qi" "sudo pacman -S --needed --noconfirm"
            ;;
        *ubuntu*|*debian*|*linuxmint*|*pop*|*elementary*|*zorin*)
            install_vm_tools "dpkg -s" "sudo apt-get install -y"
            ;;
        *fedora*|*rhel*|*centos*|*rocky*|*almalinux*|*nobara*)
            install_vm_tools "rpm -q" "sudo dnf install -y"
            ;;
        *opensuse*|*suse*|*sled*)
            install_vm_tools "rpm -q" "sudo zypper install -y"
            ;;
        *)
            install_vm_tools "echo 'no-pkg-check'" "echo 'no-pkg-install'"
            ;;
    esac

    # --- Habilitar servicios de invitado ---
    echo -e "${YELLOW}🔄 Habilitando servicios de VM...${NC}"

    enable_vm_service() {
        local svc="$1"
        if systemctl list-unit-files | grep -q "^${svc}\.service"; then
            if systemctl is-enabled "$svc" >/dev/null 2>&1; then
                echo -e "${GREEN}  ✓ $svc ya habilitado${NC}"
            else
                sudo systemctl enable --now "$svc" 2>/dev/null \
                    && echo -e "${GREEN}  ✓ $svc habilitado${NC}" \
                    || echo -e "${YELLOW}  ⚠️  No se pudo habilitar $svc${NC}"
            fi
        fi
    }

    # Servicios comunes para KVM/QEMU
    if echo "$VM_TYPE" | grep -qi "kvm\|qemu"; then
        enable_vm_service "qemu-guest-agent"
        enable_vm_service "spice-vdagentd"
        enable_vm_service "spice-vdagent"
    fi

    # Servicios para VirtualBox
    if echo "$VM_TYPE" | grep -qi "oracle\|virtualbox\|vbox"; then
        enable_vm_service "vboxadd"
        enable_vm_service "vboxadd-service"
        enable_vm_service "virtualbox-guest-utils"
    fi

    # Servicios para VMware
    if echo "$VM_TYPE" | grep -qi "vmware"; then
        enable_vm_service "vmtoolsd"
        enable_vm_service "vgauthd"
    fi

    # Servicios para Hyper-V
    if echo "$VM_TYPE" | grep -qi "microsoft"; then
        enable_vm_service "hv_kvp_daemon"
        enable_vm_service "hv_vss_daemon"
    fi

    echo -e "${GREEN}✓ Herramientas de VM configuradas${NC}"
else
    echo -e "${GREEN}✓ Entorno físico detectado (sin herramientas de VM)${NC}"
fi

echo ""

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
            echo -e "${YELLOW}  Paquetes AUR necesarios: awesome-git, picom-git, ttf-jetbrains-mono-nerd, ttf-iosevka-nerd, ttf-hack-nerd, ttf-weather-icons, mpd-mpris, touchegg, xsecurelock${NC}"

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
        PKG_INSTALL="pacman -S --needed --noconfirm"
        ;;
    ubuntu|debian|linuxmint|pop|elementary|zorin)
        DEPS_FILE="docs/deps-debian.txt"
        PKG_CHECK="dpkg -s"
        PKG_INSTALL="sudo apt-get update && sudo apt-get install -y"
        # Habilitar backports en Debian para paquetes nuevos
        if [ "$DISTRO_ID" = "debian" ] && [ -f /etc/debian_version ]; then
            DEBIAN_VER=$(cat /etc/debian_version | cut -d. -f1)
            if [ "$DEBIAN_VER" -ge 12 ] && ! grep -q "backports" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
                echo -e "${YELLOW}📦 Habilitando backports en Debian...${NC}"
                # Usar el codename real (bookworm, trixie...) en vez de hardcodear uno
                DEBIAN_CODE=${VERSION_CODENAME:-bookworm}
                echo "deb http://deb.debian.org/debian ${DEBIAN_CODE}-backports main" | sudo tee /etc/apt/sources.list.d/backports.list >/dev/null
                sudo apt-get update
            fi
        fi
        ;;
    fedora|rhel|centos|rocky|almalinux|nobara)
        DEPS_FILE="docs/deps-fedora.txt"
        PKG_CHECK="rpm -q"
        PKG_INSTALL="sudo dnf install -y"
        # Habilitar RPM Fusion si no está
        if ! rpm -q rpmfusion-free-release >/dev/null 2>&1; then
            echo -e "${YELLOW}📦 Habilitando RPM Fusion...${NC}"
            sudo dnf install -y \
                https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
                https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm 2>/dev/null \
                || echo -e "${YELLOW}⚠️  No se pudo habilitar RPM Fusion. Algunas dependencias (ffmpeg, nerd-fonts) no se instalarán.${NC}"
        fi
        # Habilitar COPR para awesome-git
        if ! dnf repolist | grep -q "varlad/awesome-git"; then
            echo -e "${YELLOW}📦 Habilitando COPR varlad/awesome-git para awesome-git...${NC}"
            sudo dnf copr enable -y varlad/awesome-git 2>/dev/null || true
        fi
        ;;
    opensuse-tumbleweed|opensuse-leap|suse|sled)
        DEPS_FILE="docs/deps-opensuse.txt"
        PKG_CHECK="rpm -q"
        PKG_INSTALL="sudo zypper install -y"
        # Añadir repo Packman para codecs
        if ! zypper lr | grep -q "packman"; then
            echo -e "${YELLOW}📦 Añadiendo repo Packman (codecs)...${NC}"
            sudo zypper ar -f https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman 2>/dev/null || true
            sudo zypper --gpg-auto-import-keys refresh packman 2>/dev/null || true
        fi
        # Añadir repo nerd-fonts (OBS)
        if ! zypper lr | grep -q "nerdfonts"; then
            echo -e "${YELLOW}📦 Añadiendo repo nerd-fonts (OBS)...${NC}"
            sudo zypper ar -f https://download.opensuse.org/repositories/home:/deadmoo:/nerdfonts/openSUSE_Tumbleweed/ nerdfonts 2>/dev/null || true
            sudo zypper --gpg-auto-import-keys refresh nerdfonts 2>/dev/null || true
        fi
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
            PKG_INSTALL="pacman -S --needed --noconfirm"
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
    # Leer paquetes del archivo (ignorar comentarios, líneas vacías, y marcadores FLATPAK/MANUAL/COPR/OBS/BACKPORTS)
    if [ ! -f "$DEPS_FILE" ]; then
        echo -e "${YELLOW}⚠️  No se encontró $DEPS_FILE. Saltando instalación de dependencias.${NC}"
        packages=()
    else
        mapfile -t packages < <(grep -v '^#' "$DEPS_FILE" | grep -v '^$' | grep -v '^FLATPAK:' | grep -v '^MANUAL:' | grep -v '^COPR:' | grep -v '^OBS:' | grep -v '^BACKPORTS:' | sed 's/#.*//' | xargs -n1)
    fi

    # Para Arch: separar paquetes oficiales y AUR, instalar desde la fuente correcta
    if [ "$IS_ARCH" = "1" ]; then
        official_pkgs=()
        aur_pkgs=()

        for pkg in "${packages[@]}"; do
            # Verificar si ya esta instalado (desde cualquier fuente)
            if pacman -Qi "$pkg" &>/dev/null; then
                echo -e "${GREEN}  ✓ $pkg ya instalado${NC}"
                continue
            fi

            # Verificar si esta en repos oficiales
            if pacman -Ss "^${pkg}$" &>/dev/null; then
                official_pkgs+=("$pkg")
            else
                aur_pkgs+=("$pkg")
            fi
        done

        # Instalar paquetes oficiales con pacman
        if [ ${#official_pkgs[@]} -gt 0 ]; then
            echo -e "${YELLOW}📦 Instalando paquetes oficiales: ${official_pkgs[*]}${NC}"
            sudo pacman -S --needed --noconfirm "${official_pkgs[@]}" 2>/dev/null \
                || {
                    echo -e "${YELLOW}⚠️  Algunos paquetes oficiales fallaron. Intentando individualmente...${NC}"
                    for pkg in "${official_pkgs[@]}"; do
                        if ! pacman -Qi "$pkg" &>/dev/null; then
                            sudo pacman -S --needed --noconfirm "$pkg" 2>/dev/null \
                                || echo -e "${YELLOW}⚠️  No se pudo instalar $pkg${NC}"
                        fi
                    done
                }
        fi

        # Instalar paquetes AUR con yay/paru
        if [ ${#aur_pkgs[@]} -gt 0 ]; then
            if [ -n "$AUR_HELPER" ]; then
                echo -e "${YELLOW}📦 Instalando paquetes AUR: ${aur_pkgs[*]}${NC}"
                $AUR_HELPER -S --needed --noconfirm "${aur_pkgs[@]}" 2>/dev/null \
                    || {
                        echo -e "${YELLOW}⚠️  Algunos paquetes AUR fallaron. Intentando individualmente...${NC}"
                        for pkg in "${aur_pkgs[@]}"; do
                            if ! pacman -Qi "$pkg" &>/dev/null; then
                                $AUR_HELPER -S --needed --noconfirm "$pkg" 2>/dev/null \
                                    || echo -e "${YELLOW}⚠️  No se pudo instalar $pkg (AUR)${NC}"
                            fi
                        done
                    }
            else
                echo -e "${YELLOW}⚠️  No hay AUR helper disponible. Paquetes AUR pendientes:${NC}"
                for pkg in "${aur_pkgs[@]}"; do
                    echo -e "${YELLOW}    - $pkg${NC}"
                done
                echo -e "${YELLOW}  Instálalos manualmente: git clone https://aur.archlinux.org/<pkg>.git && cd <pkg> && makepkg -si${NC}"
            fi
        fi

        # Reporte final
        total_missing=$(( ${#official_pkgs[@]} + ${#aur_pkgs[@]} ))
        if [ "$total_missing" -eq 0 ]; then
            echo -e "${GREEN}✓ Todos los paquetes ya están instalados${NC}"
        fi
    else
        # Para otras distros: verificar cada paquete individualmente
        to_install=()
        for pkg in "${packages[@]}"; do
            if eval "$PKG_CHECK $pkg" > /dev/null 2>&1; then
                echo -e "${GREEN}  ✓ $pkg ya instalado${NC}"
            else
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
    fi

    # =====================================================================
    # 2b️⃣ FLATPAK: fallback si no está en repos nativos ni especiales
    # =====================================================================
    # PRIORIDAD: 1) Repo oficial → 2) AUR/COPR/OBS → 3) Flatpak
    # Flatpak se instala solo si el paquete NO existe en repos nativos ni especiales

    if command -v flatpak >/dev/null 2>&1; then
        echo -e "${YELLOW}📦 Verificando Flatpak (último recurso)...${NC}"

        # Formato: "flatpak_id:nombre_arch:nombre_debian:nombre_fedora:nombre_opensuse:notas"
        # NOTA: Estos paquetes SOLO se instalan si el nativo NO existe en ninguna distro
        FLATPAK_MAP=(
            "com.spotify.Client:spotify:spotify-client:spotify-client:spotify-client:Solo si no hay repo nativo"
            "com.github.joseexposito.touchegg:touchegg:touchegg:touchegg:touchegg:Compilar desde fuente es mejor"
            "com.github.joseexposito.mpdris2:mpd-mpris:mpd-mpris:mpd-mpris:mpd-mpris:pip install mpdris2 es mejor"
            "com.sentriz.cliphist:cliphist:cliphist:cliphist:cliphist:go install es mejor"
            "org.mozilla.firefox:firefox:firefox:firefox:firefox:Siempre usar repo nativo"
        )

        for entry in "${FLATPAK_MAP[@]}"; do
            IFS=':' read -ra PARTS <<< "$entry"
            fpkg="${PARTS[0]}"
            native_arch="${PARTS[1]}"
            native_debian="${PARTS[2]}"
            native_fedora="${PARTS[3]}"
            native_opensuse="${PARTS[4]}"
            notas="${PARTS[5]}"

            # Verificar si CUALQUIER variante nativa esta instalada
            native_found=false
            for nat in "$native_arch" "$native_debian" "$native_fedora" "$native_opensuse"; do
                if pacman -Qi "$nat" &>/dev/null 2>&1 || dpkg -s "$nat" &>/dev/null 2>&1 || rpm -q "$nat" &>/dev/null 2>&1; then
                    echo -e "${GREEN}  ✓ $nat ya instalado (nativo) - saltando flatpak $fpkg${NC}"
                    native_found=true
                    break
                fi
            done

            if [ "$native_found" = true ]; then
                continue
            fi

            # Verificar si el flatpak ya esta instalado
            if flatpak list --app 2>/dev/null | grep -q "$fpkg"; then
                echo -e "${GREEN}  ✓ $fpkg ya instalado (flatpak)${NC}"
                continue
            fi

            # Fallback: no está en repos nativos ni especiales, usar Flatpak
            echo -e "${YELLOW}  ⚠️  $fpkg no está en repos de tu distro${NC}"
            echo -e "${YELLOW}    Instalando desde Flatpak...${NC}"
            flatpak install -y flathub "$fpkg" 2>/dev/null \
                && echo -e "${GREEN}  ✓ $fpkg instalado (flatpak)${NC}" \
                || echo -e "${YELLOW}  ⚠️  No se pudo instalar $fpkg (ni nativo ni flatpak)${NC}"
        done
    else
        echo -e "${YELLOW}⚠️  flatpak no instalado. Paquetes que pueden faltar:${NC}"
        echo -e "   - spotify (verificar repos de tu distro)"
        echo -e "   - touchegg (compilar desde fuente)"
        echo -e "   - mpd-mpris (pip install mpdris2)"
        echo -e "   - cliphist (go install)"
    fi

    echo -e "${GREEN}✓ Dependencias instaladas${NC}"

    # =====================================================================
    # 2c️⃣ VERIFICAR DEPENDENCIAS CRÍTICAS POST-INSTALACIÓN
    # =====================================================================
    echo -e "${YELLOW}🔍 Verificando dependencias críticas...${NC}"
    CRITICAL_DEPS=("awesome" "picom" "kitty" "rofi" "zsh" "git" "curl" "wget" "rsync" "pactl" "wpctl" "bluetoothctl" "notify-send" "autorandr")
    MISSING_CRITICAL=()
    for dep in "${CRITICAL_DEPS[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            MISSING_CRITICAL+=("$dep")
        fi
    done
    if [ ${#MISSING_CRITICAL[@]} -gt 0 ]; then
        echo -e "${RED}⚠️  Dependencias CRÍTICAS faltantes: ${MISSING_CRITICAL[*]}${NC}"
        echo -e "${YELLOW}   AwesomeWM puede no funcionar correctamente.${NC}"
        echo -e "${YELLOW}   Instálalas manualmente y re-ejecuta el script.${NC}"
    else
        echo -e "${GREEN}✓ Todas las dependencias críticas disponibles${NC}"
    fi
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

# =====================================================================
# 5b️⃣ CONFIGURAR TOUCHEGG PARA GESTOS DE 3 DEDOS
# =====================================================================
echo -e "${CYAN}🖐️ Configurando touchegg para gestos de 3 dedos...${NC}"

# Crear directorio de configuración si no existe
TOUCHEGF_DIR="${HOME}/.config/touchegg"
mkdir -p "${TOUCHEGF_DIR}"

# Copiar configuración del repo al sistema (sobreescribe si ya existe)
if [ -f "${SCRIPT_DIR}/config/touchegg/touchegg.conf" ]; then
    cp -f "${SCRIPT_DIR}/config/touchegg/touchegg.conf" "${TOUCHEGF_DIR}/config.conf"
    echo -e "  ${GREEN}✓ Configuración de touchegg copiada${NC}"
else
    echo -e "  ${YELLOW}⚠  No se encontró config/touchegg/touchegg.conf en el repo${NC}"
fi

# Asegurar que touchegg daemon se inicie en el autostart (ejecutado tras copiar config/)
AUTOSTART_FILE="${HOME}/.config/awesome/configuration/autostart"
if [ -f "${AUTOSTART_FILE}" ]; then
    if ! grep -q "touchegg.*--daemon" "${AUTOSTART_FILE}"; then
        # Agregar inicio del daemon antes del cliente (sección 5 del autostart)
        sed -i '/# 5. Touchegg client/i\
# 4. Touchegg daemon (siempre iniciar al login)\
if command -v touchegg >/dev/null 2>&1; then\
    if ! pgrep -u "$USER" -f "touchegg.*--daemon" >/dev/null 2>&1; then\
        touchegg --daemon &>/dev/null &\
    fi;\
fi' "${AUTOSTART_FILE}" >/dev/null 2>&1 \
        && echo -e "  ${GREEN}✓ Touchegg daemon añadido al autostart${NC}" \
        || echo -e "  ${YELLOW}⚠  No se pudo modificar ${AUTOSTART_FILE}${NC}"
    fi
fi

echo -e "${GREEN}✓ Touchegg configurado${NC}"

echo ""

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

# Instalar Nerd Fonts si faltan (para distros que no las tienen en repos)
echo -e "${YELLOW}🔤 Verificando Nerd Fonts...${NC}"
NERD_FONTS_DIR="$HOME/.local/share/fonts"
NEED_NERD_FONTS=false

# Verificar si tenemos al menos una Nerd Font instalada
if ! fc-list | grep -qi "nerd font\|jetbrainsmononerd\|iosevkanerd\|hacknerd"; then
    NEED_NERD_FONTS=true
fi

if [ "$NEED_NERD_FONTS" = true ]; then
    echo -e "${YELLOW}  Nerd Fonts no detectadas. Instalando JetBrains Mono Nerd Font...${NC}"
    mkdir -p "$NERD_FONTS_DIR"
    cd "$NERD_FONTS_DIR"
    DOWNLOADER=""
    if command -v wget &>/dev/null; then
        DOWNLOADER="wget -q"
    elif command -v curl &>/dev/null; then
        DOWNLOADER="curl -fsSL -o JetBrainsMono.zip"
    fi
    if [ -n "$DOWNLOADER" ]; then
        if echo "$DOWNLOADER" | grep -q "curl"; then
            $DOWNLOADER "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" 2>/dev/null
        else
            $DOWNLOADER "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" 2>/dev/null
        fi
        if [ -f "JetBrainsMono.zip" ] && [ -s "JetBrainsMono.zip" ]; then
            if command -v unzip >/dev/null 2>&1; then
                unzip -o JetBrainsMono.zip >/dev/null 2>&1
            elif command -v python3 >/dev/null 2>&1; then
                echo -e "${YELLOW}  ⚠️  unzip no instalado, extrayendo con python3...${NC}"
                python3 -m zipfile -e JetBrainsMono.zip . >/dev/null 2>&1
            else
                echo -e "${YELLOW}  ⚠️  Ni unzip ni python3 para extraer la fuente. Instálala manualmente.${NC}"
                rm -f JetBrainsMono.zip 2>/dev/null
            fi
            rm -f JetBrainsMono.zip
            fc-cache -fv "$NERD_FONTS_DIR" >/dev/null 2>&1
            echo -e "${GREEN}  ✓ JetBrains Mono Nerd Font instalada${NC}"
        else
            rm -f JetBrainsMono.zip 2>/dev/null
            echo -e "${YELLOW}  ⚠️  No se pudo descargar Nerd Font (¿sin red?). Instálala manualmente desde https://github.com/ryanoasis/nerd-fonts${NC}"
        fi
    else
        echo -e "${YELLOW}  ⚠️  Ni wget ni curl disponibles. Instala wget o curl y re-ejecuta.${NC}"
    fi
    cd "$SCRIPT_DIR"
else
    echo -e "${GREEN}  ✓ Nerd Fonts ya instaladas${NC}"
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
    # Ya está instalado: saltar el instalador interactivo (README: "no vuelve a instalar mscdown")
    if [ -d "$HOME/mscdown" ]; then
        echo -e "${GREEN}✓ MSCDown ya presente en ~/mscdown. Saltando instalación.${NC}"
    else
        echo -e "${YELLOW}📦 Ejecutando instalador de mscdown...${NC}"
        chmod +x "$MSCDOWN_INSTALLER" 2>/dev/null || true
        ( cd "$ROOT_DIR/mscdown" && ./install.sh ) || echo -e "${YELLOW}⚠️  El instalador de MSCDown falló, continuando...${NC}"

        # Colocar mscdown en ~/mscdown (donde apunta el alias creado por su instalador)
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
        echo -e "${GREEN}✓ MSCDown instalado${NC}"
    fi
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

    # Configurar SDDM para VMs sin aceleracion 3D (software rendering)
    if [ -f "$SCRIPT_DIR/scripts/setup-sddm-vm.sh" ]; then
        echo -e "${YELLOW}🔍 Verificando si se necesita software rendering para SDDM...${NC}"
        bash "$SCRIPT_DIR/scripts/setup-sddm-vm.sh" 2>/dev/null \
            && echo -e "${GREEN}✓ SDDM VM config aplicada${NC}" \
            || echo -e "${YELLOW}⚠️  setup-sddm-vm.sh no se pudo ejecutar (puede no ser VM o sin glxinfo)${NC}"
    fi
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
# INSTALACIÓN COMPLETADA - RESUMEN
# =====================================================================
echo "════════════════════════════════════════════════════"
echo -e "${GREEN}✅ ¡Instalación completada!${NC}"
echo "════════════════════════════════════════════════════"
echo ""

# Verificar dependencias críticas finales
echo -e "${CYAN}📊 Resumen de dependencias críticas:${NC}"
CRITICAL_CHECK=("awesome" "picom" "kitty" "rofi" "zsh" "git" "curl" "rsync" "notify-send" "autorandr")
INSTALLED=0
MISSING=0
for dep in "${CRITICAL_CHECK[@]}"; do
    if command -v "$dep" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $dep"
        INSTALLED=$((INSTALLED+1))
    else
        echo -e "  ${RED}✗${NC} $dep"
        MISSING=$((MISSING+1))
    fi
done

echo ""
echo -e "${CYAN}📈 Estado: ${INSTALLED} instalados, ${MISSING} faltantes${NC}"

if [ $MISSING -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Paquetes faltantes - instálalos manualmente:${NC}"
    echo -e "   ${CYAN}Ver: docs/deps-$(echo $DISTRO_ID | sed 's/-.*//' ).txt${NC}"
fi

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
