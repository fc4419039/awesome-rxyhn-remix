#!/bin/bash
# Pre-install validation script for AwesomeWM Remix
# Ejecutar antes de install.sh para detectar problemas potenciales

# No usar set -e porque verificamos códigos de retorno manualmente
set -uo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${CYAN}  AwesomeWM Remix - Pre-Install Check${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo ""

ERRORS=0
WARNINGS=0

check_cmd() {
    local cmd="$1"
    local pkg="$2"
    local desc="$3"
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $desc ($cmd)"
        return 0
    else
        echo -e "${RED}✗${NC} $desc ($cmd) - Paquete sugerido: $pkg"
        ((ERRORS++))
        return 1
    fi
}

check_optional() {
    local cmd="$1"
    local pkg="$2"
    local desc="$3"
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $desc ($cmd)"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} $desc ($cmd) - Paquete sugerido: $pkg (opcional)"
        ((WARNINGS++))
        return 1
    fi
}

# 1. Detectar distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID="${ID:-unknown}"
    DISTRO_LIKE="${ID_LIKE:-}"
    echo -e "${CYAN}Distro detectada: ${DISTRO_NAME:-$DISTRO_ID}${NC}"
else
    echo -e "${RED}✗ No se pudo detectar la distro (/etc/os-release no existe)${NC}"
    ((ERRORS++))
fi
echo ""

# 2. Verificar conectividad
echo -e "${CYAN}--- Conectividad ---${NC}"
if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Internet accesible"
else
    echo -e "${RED}✗${NC} Sin conexión a internet (requerido para instalar paquetes)"
    ((ERRORS++))
fi
echo ""

# 3. Verificar sudo
echo -e "${CYAN}--- Permisos ---${NC}"
sudo -n true 2>/dev/null
SUDO_RESULT=$?
if [ $SUDO_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓${NC} sudo sin contraseña (o ya autenticado)"
else
    echo -e "${YELLOW}⚠${NC} sudo requiere contraseña (se pedirá durante la instalación)"
    ((WARNINGS++))
fi

# Verificar si somos root
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${RED}✗${NC} Ejecutando como root - NO recomendado (makepkg fallará en Arch)"
    ((ERRORS++))
else
    echo -e "${GREEN}✓${NC} Usuario normal (correcto)"
fi
echo ""

# 4. Verificar espacio en disco
echo -e "${CYAN}--- Espacio en disco ---${NC}"
HOME_AVAIL=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$HOME_AVAIL" -ge 5 ]; then
    echo -e "${GREEN}✓${NC} Espacio en $HOME: ${HOME_AVAIL}GB libres"
elif [ "$HOME_AVAIL" -ge 2 ]; then
    echo -e "${YELLOW}⚠${NC} Espacio en $HOME: ${HOME_AVAIL}GB libres (mínimo recomendado: 5GB)"
    ((WARNINGS++))
else
    echo -e "${RED}✗${NC} Espacio en $HOME: ${HOME_AVAIL}GB libres (CRÍTICO: mínimo 2GB)"
    ((ERRORS++))
fi

ROOT_AVAIL=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$ROOT_AVAIL" -ge 5 ]; then
    echo -e "${GREEN}✓${NC} Espacio en /: ${ROOT_AVAIL}GB libres"
else
    echo -e "${YELLOW}⚠${NC} Espacio en /: ${ROOT_AVAIL}GB libres"
    ((WARNINGS++))
fi
echo ""

# 5. Verificar entorno virtualizado
echo -e "${CYAN}--- Entorno ---${NC}"
if command -v systemd-detect-virt >/dev/null 2>&1; then
    VIRT=$(systemd-detect-virt 2>/dev/null)
    if [ -z "$VIRT" ] || [ "$VIRT" = "none" ]; then
        echo -e "${GREEN}✓${NC} Hardware físico (no virtualizado)"
    else
        echo -e "${YELLOW}⚠${NC} Virtualizado: $VIRT (Picom/blur pueden no funcionar)"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}⚠${NC} systemd-detect-virt no disponible"
fi
echo ""

# 6. Verificar herramientas base
echo -e "${CYAN}--- Herramientas base ---${NC}"
check_cmd "git" "git" "Git"
check_cmd "curl" "curl" "cURL"
check_cmd "wget" "wget" "wget"
check_cmd "rsync" "rsync" "rsync"
check_cmd "make" "make" "make"
check_cmd "gcc" "gcc" "GCC (para compilar AUR)"
echo ""

# 7. Verificar dependencias específicas por distro
echo -e "${CYAN}--- Dependencias específicas ---${NC}"

case "$DISTRO_ID" in
    arch|manjaro|endeavouros|garuda|artix)
        check_cmd "pacman" "pacman" "Pacman"
        check_optional "paru" "paru" "AUR Helper (paru)"
        check_optional "yay" "yay" "AUR Helper (yay)"
        check_optional "base-devel" "base-devel" "base-devel (compilar AUR)"
        ;;
    ubuntu|debian|linuxmint|pop|elementary|zorin)
        check_cmd "apt" "apt" "APT"
        check_optional "flatpak" "flatpak" "Flatpak (para apps extra)"
        ;;
    fedora|rhel|centos|rocky|almalinux|nobara)
        check_cmd "dnf" "dnf" "DNF"
        check_optional "flatpak" "flatpak" "Flatpak"
        if rpm -q rpmfusion-free-release >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} RPM Fusion habilitado"
        else
            echo -e "${YELLOW}⚠${NC} RPM Fusion NO habilitado (se habilitará automáticamente)"
            ((WARNINGS++))
        fi
        ;;
    opensuse-tumbleweed|opensuse-leap|suse|sled)
        check_cmd "zypper" "zypper" "Zypper"
        check_optional "flatpak" "flatpak" "Flatpak"
        ;;
    nixos)
        check_cmd "nixos-rebuild" "nixos" "NixOS"
        check_optional "home-manager" "home-manager" "Home Manager"
        ;;
    *)
        echo -e "${YELLOW}⚠${NC} Distro no reconocida: $DISTRO_ID"
        ((WARNINGS++))
        ;;
esac
echo ""

# 8. Verificar archivos del repo
echo -e "${CYAN}--- Archivos del repositorio ---${NC}"
REQUIRED_FILES=(
    "config/awesome/rc.lua"
    "config/awesome/theme/theme.lua"
    "install.sh"
    "Makefile"
    "docs/deps-arch.txt"
    "docs/deps-debian.txt"
    docs/deps-fedora.txt
    docs/deps-opensuse.txt
    docs/deps-nixos.txt
)

for f in "${REQUIRED_FILES[@]}"; do
    if [ -f "$REPO_ROOT/$f" ]; then
        echo -e "${GREEN}✓${NC} $f"
    else
        echo -e "${RED}✗${NC} $f (FALTA)"
        ((ERRORS++))
    fi
done
echo ""

# 9. Verificar Nerd Fonts
echo -e "${CYAN}--- Fuentes ---${NC}"
if fc-list | grep -qi "nerd font\|jetbrainsmononerd\|iosevkanerd\|hacknerd"; then
    echo -e "${GREEN}✓${NC} Nerd Fonts detectadas"
else
    echo -e "${YELLOW}⚠${NC} Nerd Fonts NO detectadas (se instalarán automáticamente)"
    ((WARNINGS++))
fi
echo ""

# 10. Resumen
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${CYAN}  RESUMEN${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ Todo OK. Listo para instalar.${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS advertencias. La instalación debería funcionar pero revisa los items arriba.${NC}"
    exit 0
else
    echo -e "${RED}❌ $ERRORS errores críticos. Corrige antes de instalar.${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}   + $WARNINGS advertencias${NC}"
    fi
    exit 1
fi