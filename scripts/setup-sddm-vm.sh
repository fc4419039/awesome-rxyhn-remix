#!/bin/bash
# SDDM VM Setup - Force software rendering when no 3D acceleration
# Called by install.sh on VMs without GPU passthrough

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Detect if running in VM (same logic as autostart)
IS_VM=0
VM_TYPE=""

# Check DMI (works without root)
for f in /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/board_name /sys/class/dmi/id/product_name; do
    if [ -f "$f" ] && grep -qi "virtualbox\|vbox\|vmware\|qemu\|kvm\|microsoft\|hyper\|parallels\|xen\|bochs\|innotek" "$f" 2>/dev/null; then
        IS_VM=1
        VM_TYPE=$(cat "$f" 2>/dev/null)
        break
    fi
done

# Check /proc/cpuinfo hypervisor flag
if [ "$IS_VM" -eq 0 ] && grep -qi "hypervisor" /proc/cpuinfo 2>/dev/null; then
    IS_VM=1
    VM_TYPE="hypervisor"
fi

# Check virtio devices
if [ "$IS_VM" -eq 0 ] && ls /sys/bus/virtio/devices/ 2>/dev/null | head -1 | grep -q .; then
    IS_VM=1
    VM_TYPE="virtio"
fi

# systemd-detect-virt (if available and not already detected)
if [ "$IS_VM" -eq 0 ] && command -v systemd-detect-virt >/dev/null 2>&1; then
    VM_TYPE=$(systemd-detect-virt 2>/dev/null)
    if [ -n "$VM_TYPE" ] && [ "$VM_TYPE" != "none" ]; then
        IS_VM=1
    fi
fi

if [ "$IS_VM" -eq 0 ]; then
    echo -e "${GREEN}✓ Not a VM, skipping SDDM software rendering config${NC}"
    exit 0
fi

# Check 3D acceleration in VM using glxinfo
HAS_3D=0
if command -v glxinfo >/dev/null 2>&1; then
    GL_RENDERER=$(glxinfo 2>/dev/null | grep "OpenGL renderer" | cut -d: -f2 | xargs)
    if [ -n "$GL_RENDERER" ]; then
        case "$GL_RENDERER" in
            *llvmpipe*|*swrast*|*softpipe*|*Software*|*Mesa*Offscreen*)
                HAS_3D=0
                echo -e "${YELLOW}🔍 VM: renderer software detectado ($GL_RENDERER), sin aceleracion 3D${NC}"
                ;;
            *)
                HAS_3D=1
                echo -e "${GREEN}✓ VM: renderer hardware detectado ($GL_RENDERER), con aceleracion 3D${NC}"
                ;;
        esac
    else
        echo -e "${YELLOW}🔍 VM: glxinfo no reporto renderer, asumiendo sin aceleracion 3D${NC}"
    fi
else
    echo -e "${YELLOW}🔍 VM: glxinfo no disponible, asumiendo sin aceleracion 3D${NC}"
fi

# VM with 3D acceleration: no need to force software rendering
if [ "$HAS_3D" -eq 1 ]; then
    echo -e "${GREEN}✓ VM con aceleracion 3D, SDDM usara GPU normal (sin cambios)${NC}"
    # Create flag file for autostart VM detection
    VM_FLAG="$HOME/.cache/awesome/vm-detected"
    mkdir -p "$(dirname "$VM_FLAG")"
    touch "$VM_FLAG"
    echo -e "${GREEN}✓ Created VM flag: $VM_FLAG${NC}"
    exit 0
fi

echo -e "${YELLOW}🔍 VM detected ($VM_TYPE) sin aceleracion 3D, configurando SDDM for software rendering...${NC}"

# Create flag file for autostart VM detection
VM_FLAG="$HOME/.cache/awesome/vm-detected"
mkdir -p "$(dirname "$VM_FLAG")"
touch "$VM_FLAG"
echo -e "${GREEN}✓ Created VM flag: $VM_FLAG${NC}"

# Create Xsetup script to force software rendering for Qt Quick
XSETUP="/usr/share/sddm/scripts/Xsetup"
sudo bash -c "cat > '$XSETUP'" << 'XSETUPEOF'
#!/bin/sh
# Xsetup - run as root before the login dialog appears
# Force software rendering in VMs without 3D acceleration (safer, no GPU required)

# Force software rendering for Qt Quick
export QT_QUICK_BACKEND=software
export QSG_RHI=software
export QSG_RENDER_LOOP=basic

XSETUPEOF
sudo chmod +x "$XSETUP"

# Create sddm.conf with VM-specific settings if not exists
SDDM_CONF="/etc/sddm.conf"
if [ ! -f "$SDDM_CONF" ]; then
    sudo bash -c "cat > '$SDDM_CONF'" << 'EOF'
[General]
DisplayServer=x11

[Greeter]
Environment="QT_QUICK_BACKEND=software QSG_RHI=software QSG_RENDER_LOOP=basic"
EOF
    echo -e "${GREEN}✓ Created $SDDM_CONF with software rendering${NC}"
else
    # Check if Environment line already exists
    if ! sudo grep -q "QT_QUICK_BACKEND=software" "$SDDM_CONF" 2>/dev/null; then
        # Add Greeter section with Environment if not present
        if sudo grep -q "\[Greeter\]" "$SDDM_CONF" 2>/dev/null; then
            # Add Environment after [Greeter] section
            sudo sed -i '/\[Greeter\]/a Environment="QT_QUICK_BACKEND=software QSG_RHI=software QSG_RENDER_LOOP=basic"' "$SDDM_CONF"
        else
            # Add [Greeter] section
            echo -e '\n[Greeter]\nEnvironment="QT_QUICK_BACKEND=software QSG_RHI=software QSG_RENDER_LOOP=basic"' | sudo tee -a "$SDDM_CONF" > /dev/null
        fi
        echo -e "${GREEN}✓ Updated $SDDM_CONF with software rendering${NC}"
    else
        echo -e "${GREEN}✓ $SDDM_CONF already configured for software rendering${NC}"
    fi
fi

# Also set in /etc/environment as fallback
ENV_FILE="/etc/environment"
if ! grep -q "QT_QUICK_BACKEND=software" "$ENV_FILE" 2>/dev/null; then
    echo "QT_QUICK_BACKEND=software" | sudo tee -a "$ENV_FILE" > /dev/null
    echo "QSG_RHI=software" | sudo tee -a "$ENV_FILE" > /dev/null
    echo -e "${GREEN}✓ Added Qt env vars to $ENV_FILE${NC}"
fi

echo -e "${GREEN}✓ SDDM configured for software rendering in VM${NC}"
echo -e "${YELLOW}Note: SDDM will use CPU-based rendering (slower but works without GPU)${NC}"
