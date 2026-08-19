#!/bin/bash
# SDDM VM Setup - Force software rendering when no 3D acceleration
# Called by install.sh on VMs without GPU passthrough

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Detect if running in VM
IS_VM=0
VM_TYPE=""
if command -v systemd-detect-virt >/dev/null 2>&1; then
    VM_TYPE=$(systemd-detect-virt 2>/dev/null)
    if [ -n "$VM_TYPE" ] && [ "$VM_TYPE" != "none" ]; then
        IS_VM=1
    fi
fi

# Fallback: check DMI
if [ "$IS_VM" -eq 0 ]; then
    if grep -qi "virtualbox\|vbox\|vmware\|qemu\|kvm\|microsoft\|hyper" /sys/class/dmi/id/sys_vendor 2>/dev/null || \
       grep -qi "virtual\|kvm\|vmware\|virtualbox" /sys/class/dmi/id/board_name 2>/dev/null; then
        IS_VM=1
    fi
fi

if [ "$IS_VM" -eq 0 ]; then
    echo -e "${GREEN}✓ Not a VM, skipping SDDM software rendering config${NC}"
    exit 0
fi

echo -e "${YELLOW}🔍 VM detected ($VM_TYPE), configuring SDDM for software rendering...${NC}"

# Create Xsetup script to force software rendering for Qt Quick
XSETUP="/usr/share/sddm/scripts/Xsetup"
sudo bash -c "cat > '$XSETUP'" << 'EOF'
#!/bin/sh
# Xsetup - run as root before the login dialog appears
# Force software rendering for Qt Quick in VMs without 3D acceleration

# Check if 3D acceleration is available
HAS_3D=0
if command -v glxinfo >/dev/null 2>&1; then
    if glxinfo 2>/dev/null | grep -q "OpenGL renderer.*Mesa\|OpenGL renderer.*VMware\|OpenGL renderer.*QXL\|OpenGL renderer.*Virgil"; then
        HAS_3D=1
    fi
fi

# Also check via lspci for virtio-gpu with 3D
if [ "$HAS_3D" -eq 0 ]; then
    if lspci 2>/dev/null | grep -qi "virtio.*gpu\|3d\|accel"; then
        HAS_3D=1
    fi
fi

# If no 3D, force software rendering
if [ "$HAS_3D" -eq 0 ]; then
    export QT_QUICK_BACKEND=software
    export QSG_RHI=software
    export QSG_RENDER_LOOP=basic
    echo "[sddm-vm] No 3D acceleration, forcing software rendering" > /dev/kmsg 2>/dev/null || true
fi
EOF
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
