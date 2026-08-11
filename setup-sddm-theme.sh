#!/bin/bash

# =====================================================================
# setup-sddm-theme.sh
# Re-aplica SOLO la configuración del tema SDDM incluido en el repo
# (sddm-astronaut-theme con estilo sugar-candy).
#
# ¿Cuándo usarlo?
#   - Después de actualizar el paquete sddm-astronaut-theme (AUR):
#     la actualización sobrescribe el tema y pierde el estilo personalizado.
#   - Si en el login aparece el tema por defecto de SDDM en vez del nuestro.
#   - En un equipo nuevo, sin necesidad de correr todo install.sh.
#
# Es seguro repetirlo cuantas veces quieras (idempotente).
# Requiere sudo (te pedirá la contraseña en la terminal).
# =====================================================================

set -e

# Directorio del script (raíz del repo si se ejecuta desde ahí)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
THEME_SRC="$SCRIPT_DIR/sddm/sddm-astronaut-theme"
THEME_DST="/usr/share/sddm/themes/sddm-astronaut-theme"
THEME_NAME="sddm-astronaut-theme"
BG_DIR="/usr/share/sddm/backgrounds"
BG_FILE="$BG_DIR/sddm_wallpaper.jpg"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Configurando SDDM (tema sddm-astronaut-theme, estilo sugar-candy) ===${NC}"
echo ""

# Comprobaciones previas
if ! command -v sddm &> /dev/null; then
    echo -e "${RED}✗ SDDM no está instalado. Aborta.${NC}"
    exit 1
fi

if [ ! -d "$THEME_SRC" ]; then
    echo -e "${RED}✗ No se encontró el tema en: $THEME_SRC${NC}"
    echo -e "  Asegúrate de ejecutar este script desde dentro del repo awesome-rxyhn-remix."
    exit 1
fi

# 1) Copiar el tema incluido en el repo al sistema
echo -e "${YELLOW}📦 Copiando tema al sistema...${NC}"
sudo mkdir -p /usr/share/sddm/themes
sudo rm -rf "$THEME_DST"
sudo cp -r "$THEME_SRC" "$THEME_DST"
sudo chown -R root:root "$THEME_DST"
echo -e "${GREEN}✓ Tema copiado a $THEME_DST${NC}"
echo ""

# 2) Carpeta de fondos compartida, escribible por el usuario actual
#    (así el cambio de fondo desde system_menu → SDDM funciona sin pedir root cada vez)
echo -e "${YELLOW}📂 Configurando carpeta de fondos SDDM...${NC}"
sudo mkdir -p "$BG_DIR"
sudo chown "$USER":"$USER" "$BG_DIR"
sudo chmod 775 "$BG_DIR"
if [ -f "$BG_FILE" ]; then
    sudo chown "$USER":"$USER" "$BG_FILE"
    sudo chmod 644 "$BG_FILE"
fi
echo -e "${GREEN}✓ $BG_DIR ahora es escribible por $USER${NC}"
echo ""

# 3) Fondo inicial desde ~/fondos si todavía no hay ninguno
if [ ! -f "$BG_FILE" ] && [ -d "$HOME/fondos" ]; then
    FONDO=$(find "$HOME/fondos" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \) | head -n 1)
    if [ -n "$FONDO" ]; then
        echo -e "${YELLOW}🖼️  Copiando fondo inicial desde ~/fondos...${NC}"
        sudo cp "$FONDO" "$BG_FILE"
        sudo chown "$USER":"$USER" "$BG_FILE"
        sudo chmod 644 "$BG_FILE"
        echo -e "${GREEN}✓ Fondo inicial copiado${NC}"
    fi
fi

# 4) Activar el tema en SDDM
echo -e "${YELLOW}⚙️  Activando tema...${NC}"
sudo mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=%s\n' "$THEME_NAME" | sudo tee /etc/sddm.conf.d/theme.conf > /dev/null
echo -e "${GREEN}✓ Tema activado: Current=$THEME_NAME${NC}"
echo ""

# 5) Habilitar el servicio (si aún no está)
if ! systemctl is-enabled sddm.service &> /dev/null; then
    echo -e "${YELLOW}🔄 Habilitando servicio SDDM...${NC}"
    sudo systemctl enable sddm.service
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ SDDM configurado correctamente.${NC}"
echo -e "   Cierra sesión (o reinicia SDDM) para ver el nuevo tema."
echo "════════════════════════════════════════════════════════════════"
