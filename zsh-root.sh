#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Verificar si se ejecuta con sudo
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}✗ No ejecutes este script como root. Ejecútalo como usuario normal.${NC}"
    exit 1
fi

# Verificar sudo
if ! sudo -n true 2>/dev/null; then
    echo -e "${YELLOW}⚠ Se necesita sudo para configurar root.${NC}"
    echo -e "${YELLOW}  Te pedirá la contraseña si es necesario.${NC}"
fi

USER_HOME="$HOME"
BACKUP_DIR="/root/.zsh-backup-$(date +%s)"

echo -e "${YELLOW}👑 Configurando zsh para root...${NC}"

# Cambiar shell de root a zsh si no lo es
ROOT_SHELL=$(sudo -u root sh -c 'echo "$SHELL"' 2>/dev/null || echo "")
if [ -n "$ROOT_SHELL" ] && [ "$ROOT_SHELL" != "/usr/bin/zsh" ] && [ "$ROOT_SHELL" != "/bin/zsh" ]; then
    echo -e "${YELLOW}⚠  Cambiando shell de root a zsh...${NC}"
    sudo chsh -s /usr/bin/zsh root
    echo -e "${GREEN}✓ Shell de root cambiada a zsh${NC}"
fi

# Backup configs existentes de root
echo -e "${YELLOW}💾 Respaldando configs existentes de root...${NC}"
sudo mkdir -p "$BACKUP_DIR" 2>/dev/null || true
for rf in "/root/.zshrc" "/root/.p10k.zsh" "/root/powerlevel10k" "/root/.fzf.zsh" "/root/.fzf"; do
    if sudo test -e "$rf" 2>/dev/null && ! sudo test -L "$rf" 2>/dev/null; then
        if sudo cp -r "$rf" "$BACKUP_DIR/" 2>/dev/null; then
            echo -e "${GREEN}  ✓ Respaldado: $rf${NC}"
        else
            echo -e "${YELLOW}  ⚠ No se pudo respaldar: $rf${NC}"
        fi
    fi
done

# Crear symlinks
echo -e "${YELLOW}🔗 Creando symlinks...${NC}"

if [ -f "$USER_HOME/.zshrc" ]; then
    sudo rm -f /root/.zshrc 2>/dev/null || true
    sudo ln -sf "$USER_HOME/.zshrc" /root/.zshrc
    echo -e "${GREEN}  ✓ /root/.zshrc -> $USER_HOME/.zshrc${NC}"
fi

if [ -f "$USER_HOME/.p10k.zsh" ]; then
    sudo rm -f /root/.p10k.zsh 2>/dev/null || true
    sudo ln -sf "$USER_HOME/.p10k.zsh" /root/.p10k.zsh
    echo -e "${GREEN}  ✓ /root/.p10k.zsh -> $USER_HOME/.p10k.zsh${NC}"
fi

if [ -d "$USER_HOME/powerlevel10k" ]; then
    sudo rm -rf /root/powerlevel10k 2>/dev/null || true
    sudo ln -sfT "$USER_HOME/powerlevel10k" /root/powerlevel10k
    echo -e "${GREEN}  ✓ /root/powerlevel10k -> $USER_HOME/powerlevel10k${NC}"
fi

if [ -f "$USER_HOME/.fzf.zsh" ]; then
    sudo rm -f /root/.fzf.zsh 2>/dev/null || true
    sudo ln -sf "$USER_HOME/.fzf.zsh" /root/.fzf.zsh
    echo -e "${GREEN}  ✓ /root/.fzf.zsh -> $USER_HOME/.fzf.zsh${NC}"
fi

if [ -d "$USER_HOME/.fzf" ]; then
    sudo rm -rf /root/.fzf 2>/dev/null || true
    sudo ln -sfT "$USER_HOME/.fzf" /root/.fzf
    echo -e "${GREEN}  ✓ /root/.fzf -> $USER_HOME/.fzf${NC}"
fi

echo ""
echo -e "${GREEN}✅ Root zsh configurada. Backup en: $BACKUP_DIR${NC}"
echo -e "${YELLOW}📝 Para revertir: sudo cp -r $BACKUP_DIR/* /root/${NC}"
