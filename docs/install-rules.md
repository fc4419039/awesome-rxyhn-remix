# Reglas de Instalación Multi-Distro

## Filosofía
1. **NUNCA detenerse por errores** - cada sección intenta, reporta (✓/⚠), y continúa
2. **No instalar lo que ya existe** - verificar ANTES de instalar
3. **Usar la fuente correcta** - paquetes oficiales vs AUR vs Flatpak vs manual
4. **Paths portátiles** - siempre usar `$HOME`, nunca `/home/usuario`

## Detección de Distro

```bash
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID="$ID"
fi
```

| Distro ID | Family | Package Manager | Check Command |
|-----------|--------|-----------------|---------------|
| arch, manjaro, endeavouros, garuda, artix | Arch | pacman + yay/paru | `pacman -Qi` |
| ubuntu, debian, linuxmint, pop, elementary | Debian | apt | `dpkg -s` |
| fedora, rhel, centos, rocky, nobara | Fedora | dnf | `rpm -q` |
| opensuse-tumbleweed, opensuse-leap | SUSE | zypper | `rpm -q` |

## Regla: No instalar si ya existe

```bash
# Arch
if pacman -Qi "$pkg" &>/dev/null; then
    echo "✓ $pkg ya instalado"
    continue
fi

# Debian
if dpkg -s "$pkg" &>/dev/null; then
    echo "✓ $pkg ya instalado"
    continue
fi

# Fedora/SUSE
if rpm -q "$pkg" &>/dev/null; then
    echo "✓ $pkg ya instalado"
    continue
fi
```

## Paquetes por Fuente

### Arch Linux
- **Oficiales**: kitty, rofi, zsh, fzf, feh, neovim, btop, lsd, bat, etc.
- **AUR** (yay/paru): awesome-git, picom-git, ttf-material-design-icons, ttf-weather-icons, spotify, zsh-sudo
- **Flatpak** (si no hay nativo): cliphist, touchegg, mpd-mpris

### Debian/Ubuntu
- **Oficiales**:大部分 paquetes están en repos
- **Backports** (Debian 12): neovim, btop, lsd, bat, zoxide
- **Flatpak**: cliphist, touchegg, mpd-mpris, spotify
- **Manual**: nerd-fonts, xsecurelock

### Fedora
- **Oficiales**:大部分 paquetes
- **RPM Fusion**: ffmpeg, nerd-fonts
- **COPR**: awesome-git (varlad/awesome-git)
- **Flatpak**: cliphist, touchegg, mpd-mpris, spotify
- **Manual**: xsecurelock

### openSUSE
- **Oficiales**:大部分 paquetes
- **Packman**: ffmpeg, codecs
- **OBS**: nerd-fonts (home:deadmoo:nerdfonts)
- **Flatpak**: cliphist, touchegg, mpd-mpris, spotify
- **Manual**: xsecurelock

## Flatpak: Regla de No-Duplicación

ANTES de instalar un Flatpak, verificar si el paquete nativo ya existe:

```bash
# Ejemplo: spotify
NATIVE_PKGS=("spotify" "spotify-client" "spotify-client")
for nat in "${NATIVE_PKGS[@]}"; do
    if pacman -Qi "$nat" &>/dev/null || dpkg -s "$nat" &>/dev/null || rpm -q "$nat" &>/dev/null; then
        echo "✓ $nat ya instalado (nativo), saltando flatpak"
        continue 2
    fi
done
flatpak install -y flathub com.spotify.Client
```

## Servicios

```bash
# Habilitar servicios (que no exista uno no bloquea a los demás)
for svc in acpid sddm mpd; do
    systemctl enable "$svc" 2>/dev/null && echo "✓ $svc habilitado" || true
done
```

## Shell (.zshrc)

1. Respaldar el existente: `cp ~/.zshrc ~/.zshrc.bak.$(date +%s)`
2. Copiar el nuevo: `cp .zshrc ~/`
3. Verificar que no rompe nada: `zsh -n ~/.zshrc`

## Post-Instalación

1. Verificar dependencias críticas
2. Actualizar cache de fuentes
3. Habilitar servicios de usuario
4. Mostrar resumen de paquetes faltantes (si los hay)
