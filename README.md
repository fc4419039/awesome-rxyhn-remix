<div align="center">
  <img src="https://awesomewm.org/images/awesome-logo.svg" height="80">
</div>

<br>

<div align="center">

[![GitHub stars](https://img.shields.io/github/stars/fc4419039/awesome-rxyhn-remix?style=for-the-badge&label=★%20STARS&color=7c3aed&labelColor=0f0f0f)](https://github.com/fc4419039/awesome-rxyhn-remix/stargazers)
[![GitHub license](https://img.shields.io/github/license/fc4419039/awesome-rxyhn-remix?style=for-the-badge&color=67AFC1&labelColor=0f0f0f)](https://github.com/fc4419039/awesome-rxyhn-remix/blob/main/LICENSE)
[![Install](https://img.shields.io/badge/⚡-INSTALL-7c3aed?style=for-the-badge&labelColor=0f0f0f)](#installation--instalación)
[![AwesomeWM](https://img.shields.io/badge/WM-Awesome-F4C2C2?style=for-the-badge&labelColor=0f0f0f&logo=awesomewm)](https://awesomewm.org/)
[![Arch Linux](https://img.shields.io/badge/OS-Arch_Linux-1793D1?style=for-the-badge&labelColor=0f0f0f&logo=arch-linux)](https://archlinux.org/)
[![Lua](https://img.shields.io/badge/Lua-2C2D72?style=for-the-badge&labelColor=0f0f0f&logo=lua)](https://www.lua.org/)

</div>

<br>

<div align="center">
  <img src=".github/assets/nv.png" alt="Rice Preview" width="85%" style="border-radius: 12px; box-shadow: 0 8px 32px rgba(0,0,0,0.5);">
</div>

<br>

<h1 align="center">
  AwesomeWM Dotfiles — Modernized & Fixed Remix
</h1>

<p align="center">
  <i>rxyhn's legendary dotfiles — recovered, rebuilt on modern AwesomeWM APIs, bugs fixed, and extended with useful extras.</i>
</p>

<br>

<div align="center">
  <h3>Stack</h3>
  <p>
    <img src="https://img.shields.io/badge/AwesomeWM-F4C2C2?style=flat-square&logo=awesomewm&labelColor=0f0f0f">
    <img src="https://img.shields.io/badge/Arch_Linux-1793D1?style=flat-square&logo=arch-linux&labelColor=0f0f0f">
    <img src="https://img.shields.io/badge/Kitty-000000?style=flat-square&logo=kitty&labelColor=0f0f0f">
    <img src="https://img.shields.io/badge/Zsh-F15A24?style=flat-square&logo=zsh&labelColor=0f0f0f">
    <img src="https://img.shields.io/badge/Neovim-57A143?style=flat-square&logo=neovim&labelColor=0f0f0f">
    <img src="https://img.shields.io/badge/Rofi-000000?style=flat-square&logo=rofi&labelColor=0f0f0f">
    <img src="https://img.shields.io/badge/PipeWire-8B5CF6?style=flat-square&logo=pipewire&labelColor=0f0f0f">
    <img src="https://img.shields.io/badge/Picom-000000?style=flat-square&logo=picom&labelColor=0f0f0f">
    <img src="https://img.shields.io/badge/ncmpcpp-000000?style=flat-square&logo=mpd&labelColor=0f0f0f">
    <img src="https://img.shields.io/badge/OpenCode-000000?style=flat-square&labelColor=0f0f0f">
  </p>
</div>

<br>

<div align="center">
  <a href="#english"><img src="https://img.shields.io/badge/🇬🇧-English-7c3aed?style=for-the-badge&labelColor=0f0f0f"></a>
  <a href="#español"><img src="https://img.shields.io/badge/🇪🇸-Español-7c3aed?style=for-the-badge&labelColor=0f0f0f"></a>
</div>

<br>

---

<br>

## 📑 Table of Contents / Índice

- [Features / Características](#features--características)
- [Screenshots / Capturas](#screenshots--capturas)
- [Keyboard Shortcuts / Atajos](#keyboard-shortcuts--atajos)
- [Installation / Instalación](#installation--instalación)
- [SDDM: keep the sugar-candy login after a theme update / Mantener el login sugar-candy](#sddm-keep-the-sugar-candy-login-after-a-theme-update--mantener-el-login-sugar-candy-tras-una-actualización)
- [Repository Structure / Estructura](#repository-structure--estructura-del-repositorio)
- [Dependencies / Dependencias](#dependencies--dependencias-completas)
- [Systemd Services / Servicios](#systemd-services--servicios-systemd)
- [Troubleshooting / Solución de problemas](#troubleshooting--solución-de-problemas)
- [Credits / Créditos](#credits--créditos)

---

<br>

## 🖼️ Screenshots / Capturas

<div align="center">
  <table>
    <tr>
      <td width="50%" align="center">
        <img src=".github/assets/123.png" alt="Dashboard" style="border-radius: 12px; box-shadow: 0 4px 24px rgba(0,0,0,0.6);">
        <br><sub><b>Dashboard</b></sub>
      </td>
      <td width="50%" align="center">
        <img src=".github/assets/login.png" alt="Lock Screen" style="border-radius: 12px; box-shadow: 0 4px 24px rgba(0,0,0,0.6);">
        <br><sub><b>Lock Screen</b></sub>
      </td>
    </tr>
    <tr>
      <td width="50%" align="center">
        <img src=".github/assets/preview-widgets.png" alt="Widgets" style="border-radius: 12px; box-shadow: 0 4px 24px rgba(0,0,0,0.6);">
        <br><sub><b>Widgets & Menus</b></sub>
      </td>
      <td width="50%" align="center">
        <img src=".github/assets/preview-btop.png" alt="BTOP" style="border-radius: 12px; box-shadow: 0 4px 24px rgba(0,0,0,0.6);">
        <br><sub><b>System Monitor</b></sub>
      </td>
    </tr>
  </table>
</div>

---

<br>

<!-- ==================== ENGLISH ==================== -->

<h1 align="center" id="english">🇬🇧 English</h1>

<p align="center">
  A complete <b>AwesomeWM</b> configuration: repaired, optimized, and extended with modern features.
  Based on <b>rxyhn</b>'s original work (repo deleted) and the <b>Alpharivs</b> fork.
</p>

### Features

- **Wibar** — Vertical left bar: Pac-Man taglist, battery arc, stacked clock, window list tooltips, layoutbox, notification-center button. Auto-hides on fullscreen (`Ctrl+F` to toggle).
- **Dashboard** — Slide-in from left: profile, music with cover art & progress, media controls, clock, todo arc, **weather** (Open-Meteo, no API key — location auto-detected by IP), system stats, recent notifications.
- **Notification Center** — Scrollable history, clear-all, and a **Do Not Disturb that actually works**: popups are silenced *and queued* until re-enabled.
- **Notification audio** — Isolated PipeWire sink, screenshot sounds, auto-router, independent volume (`Super+v`), low-latency loopback, fully silenced by DND.
- **Rofi menus** — Launcher, WiFi, Bluetooth, power, GTK3 volume sliders, instant **accent cycling** across 12 colors.
- **Window decorations** — Round buttons, WiFi/IP/VPN info, 2px accent border. **Borders & titlebars on by default** (`Ctrl+Super+Shift+B` / `+T` to toggle). ncmpcpp windows get a full music titlebar with album art, seek bar & controls.
- **Lock screen** — PAM auth, English word clock, music controls, rainbow keys (`Mod+Ctrl+L`).
- **Alt+Tab switcher** — Live window thumbnails with keyboard navigation.
- **System Menu** — Slide-out panel: blur, transparency, night mode, wallpaper, music, accent, borders/titlebars, widgets, power.
- **Layouts** — Tile, floating, centered, mstab, horizontal, machi, equalarea, deck.
- **MSCDown** — Bundled YouTube music searcher/downloader (`musica` or `musica <query>`), auto-installed. The installer **skips it if already present**.
- **Multi-monitor** — Independent wibars, dashboards and tags per screen (`Mod+Ctrl+j/k`).
- **Touchegg gestures** — 3-finger swipe for desktop overview, 4-finger to change desktops, pinches to close windows or open launcher.

### Keyboard Shortcuts

| Key | Action |
|---|---|
| `Mod+Enter` | Terminal (kitty) |
| `Mod+d` | Rofi launcher |
| `Mod+Shift+d` | Dashboard |
| `Mod+w` / `Mod+Shift+w` | Web browser / WiFi menu |
| `Mod+b` / `Mod+v` | Bluetooth / Volume |
| `Alt+F4` | Power menu |
| `Mod+p` | **No-sleep toggle** (keep screen on) |
| `Ctrl+Super+t` | **Toggle night mode** (redshift 3500K) |
| `Insert` / `Alt+Insert` | Screenshot / area screenshot |
| `Mod+z` | Scratchpad |
| `Mod+Ctrl+l` | Lock screen |
| `Ctrl+Super+b` | Cycle accent color |
| `Ctrl+Super+Shift+B` / `+T` | Toggle borders / titlebars |
| `Alt+Tab` | Window switcher |
| `Mod+e` | Desktop Overview |
| `Mod+Shift+v` | Clipboard history |
| `Mod+s` / `Mod+Shift+s` / `Mod+Space` | Tile / floating / next layout |
| `Mod+q` | Close window |
| `Mod+f` | File manager |
| `Ctrl+F` | Toggle wibar |
| `Mod+[1-5]` / `Mod+Shift+[1-5]` | Switch / move to tag |
| `Mod+Arrow` / `Mod+Shift+Arrow` | Directional focus / swap |
| `Mod+=/-` | Adjust useless gap |
| `Mod+x` | Color picker |
| `Mod+i` / `Mod+o` | Spotify / Opera GX |
| `Mod+Shift+n` | Music client (ncmpcpp) |
| `Mod+Ctrl+d` | Show desktop (minimize all) |
| `Mod+Shift+f` | Toggle fullscreen |
| `Mod+F1` | Keybinding help |
| `Mod+Ctrl+r` | Reload AwesomeWM |
| `XF86Audio*` / `XF86MonBrightness*` | Volume, brightness & playback keys |

### Extras

Sloppy & flash focus · window swallowing · scratchpad · save floats · better resize · rounded corners · OSD volume/brightness notifications · clipboard history (cliphist) · macOS-style floating calculator · desktop context menu with wallpaper picker · **blur/transparency toggles with persistent state** (survives reboot via `~/.cache/awesome`) · `reset-theme.sh` emergency reset · three picom configs (solid/blur/transparency) · **UI watchdog** that auto-repairs broken panels · OpenCode AI config included.

### Developer Tools

`config/awesome/scripts/check.sh` validates the syntax of every Lua, Shell and Python file in the config — your dotfiles' CI. Run it **before restarting awesome or committing** to catch errors that would crash the WM into fallback mode.

```bash
config/awesome/scripts/check.sh                       # from the repo (before install)
~/.config/awesome/scripts/check.sh                    # from your installed config
~/.config/awesome/scripts/check.sh <another/dir>      # check any directory (e.g. the repo)
~/.config/awesome/scripts/check.sh --watch            # continuous watch mode (every 2s)
```

Exit code `0` = all OK, `1` = syntax errors found (file:line shown).

---

<br>

<!-- ==================== ESPAÑOL ==================== -->

<h1 align="center" id="español">🇪🇸 Español</h1>

<p align="center">
  Configuración completa de <b>AwesomeWM</b>, reparada, optimizada y extendida con funcionalidades modernas.
  Basada en el trabajo original de <b>rxyhn</b> (repo eliminado) y el fork de <b>Alpharivs</b>.
</p>

### Características

- **Wibar** — Barra vertical a la izquierda: taglist Pac-Man, arco de batería, reloj apilado, tooltips de ventanas, layoutbox, botón del centro de notificaciones. Se oculta en pantalla completa (`Ctrl+F` para alternar).
- **Dashboard** — Panel deslizable desde la izquierda: perfil, música con carátula y progreso, controles multimedia, reloj, arco de tareas, **clima** (Open-Meteo, sin API key — ubicación detectada por IP), estadísticas del sistema y notificaciones recientes.
- **Centro de notificaciones** — Historial scrolleable, limpiar todo y un **no molestar que funciona de verdad**: silencia *y encola* los popups hasta que lo vuelvas a activar.
- **Audio de notificaciones** — Sink aislado en PipeWire, sonidos de captura, router automático, volumen independiente (`Super+v`), loopback de baja latencia, silenciado por completo con no molestar.
- **Menús Rofi** — Lanzador, WiFi, Bluetooth, power, sliders GTK3 de volumen y **cambio de acento** instantáneo entre 12 colores.
- **Decoraciones de ventana** — Botones redondos, widgets WiFi/IP/VPN, borde de 2px del color de acento. **Bordes y titlebars activados por defecto** (`Ctrl+Super+Shift+B` / `+T` para alternar). Las ventanas de ncmpcpp tienen una titlebar de música completa con carátula, barra de búsqueda y controles.
- **Lock screen** — Autenticación PAM, word clock en inglés, controles de música, teclas arcoíris (`Mod+Ctrl+L`).
- **Switcher Alt+Tab** — Miniaturas en vivo con navegación por teclado.
- **System Menu** — Panel deslizable: blur, transparencia, modo noche, fondo, música, acento, bordes/titlebars, widgets, power.
- **Layouts** — Tile, floating, centered, mstab, horizontal, machi, equalarea, deck.
- **MSCDown** — Buscador/descargador de música de YouTube incluido (`musica` o `musica <consulta>`), se instala automáticamente. El instalador **lo salta si ya está presente**.
- **Multi-monitor** — Wibar, dashboard y tags independientes por pantalla (`Mod+Ctrl+j/k`).
- **Gestos de Touchegg** — Swipe de 3 dedos para el overview, 4 dedos para cambiar de escritorio, pinches para cerrar ventanas o abrir el lanzador.

### Atajos de teclado

| Tecla | Acción |
|---|---|
| `Mod+Enter` | Terminal (kitty) |
| `Mod+d` | Rofi lanzador |
| `Mod+Shift+d` | Dashboard |
| `Mod+w` / `Mod+Shift+w` | Navegador / menú WiFi |
| `Mod+b` / `Mod+v` | Bluetooth / Volumen |
| `Alt+F4` | Menú de apagado |
| `Mod+p` | **No-sleep** (mantener pantalla encendida) |
| `Ctrl+Super+t` | **Modo noche** (redshift 3500K) |
| `Insert` / `Alt+Insert` | Captura / captura de área |
| `Mod+z` | Scratchpad |
| `Mod+Ctrl+l` | Lock screen |
| `Ctrl+Super+b` | Ciclar color de acento |
| `Ctrl+Super+Shift+B` / `+T` | Quitar/poner bordes / titlebars |
| `Alt+Tab` | Window switcher |
| `Mod+e` | Desktop Overview |
| `Mod+Shift+v` | Historial del portapapeles |
| `Mod+s` / `Mod+Shift+s` / `Mod+Space` | Tile / floating / siguiente layout |
| `Mod+q` | Cerrar ventana |
| `Mod+f` | Explorador de archivos |
| `Ctrl+F` | Ocultar/mostrar wibar |
| `Mod+[1-5]` / `Mod+Shift+[1-5]` | Cambiar / mover a tag |
| `Mod+Arrow` / `Mod+Shift+Arrow` | Foco / intercambio direccional |
| `Mod+=/-` | Ajustar useless gap |
| `Mod+x` | Selector de color |
| `Mod+i` / `Mod+o` | Spotify / Opera GX |
| `Mod+Shift+n` | Cliente de música (ncmpcpp) |
| `Mod+Ctrl+d` | Mostrar escritorio (minimizar todo) |
| `Mod+Shift+f` | Pantalla completa |
| `Mod+F1` | Ayuda de atajos |
| `Mod+Ctrl+r` | Recargar AwesomeWM |
| `XF86Audio*` / `XF86MonBrightness*` | Volumen, brillo y reproducción |

### Extras

Foco sloppy y flash · window swallowing · scratchpad · save floats · mejor redimensionado · esquinas redondeadas · OSD de volumen/brillo · historial del portapapeles (cliphist) · calculadora flotante estilo macOS · menú contextual con selector de fondo · **toggles de blur/transparencia con estado persistente** (sobrevive al reinicio vía `~/.cache/awesome`) · reset de emergencia `reset-theme.sh` · tres configs de picom (sólido/blur/transparencia) · **UI watchdog** que repara paneles rotos · configuración del agente OpenCode incluida.

### Herramientas de desarrollo

`config/awesome/scripts/check.sh` valida la sintaxis de todos los archivos Lua, Shell y Python de la config — el "CI" de tus dotfiles. Ejecútalo **antes de reiniciar awesome o de hacer commit** para detectar errores que romperían el WM y lo mandarían a modo fallback.

```bash
config/awesome/scripts/check.sh                       # desde el repo (antes de instalar)
~/.config/awesome/scripts/check.sh                    # desde tu config instalada
~/.config/awesome/scripts/check.sh <otro/dir>         # revisa cualquier directorio (ej. el repo)
~/.config/awesome/scripts/check.sh --watch            # modo vigilancia continua (cada 2s)
```

Código de salida `0` = todo OK, `1` = errores de sintaxis (muestra archivo:línea).

---

<br>

## ⚡ Installation / Instalación

<details>
<summary><strong>📦 Automatic / Automática (recommended / recomendada)</strong></summary>

<br>

```bash
git clone --recurse-submodules https://github.com/fc4419039/awesome-rxyhn-remix.git
cd awesome-rxyhn-remix
chmod +x install.sh
./install.sh
```

> The installer is **smart**: detects already-installed packages and skips them, won't reconfigure what's already configured, and won't re-clone or re-install mscdown if it's already present.
>
> El instalador es **inteligente**: detecta paquetes ya instalados y los omite, no reconfigura lo ya configurado y no vuelve a clonar ni instalar mscdown si ya está presente.
>
> ⚠️ `sudo` is only required for the SDDM theme installation.
> ⚠️ El script requiere `sudo` solo para instalar el tema SDDM.

</details>

<br>

<details>
<summary><strong>🔧 Manual</strong></summary>

<br>

**Dependencies / Dependencias** (Arch Linux):

```bash
yay -S awesome-git picom-git kitty rofi todo-bin acpi acpid \
wireless_tools jq inotify-tools polkit-gnome xdotool xclip maim \
brightnessctl alsa-utils alsa-tools pipewire pipewire-pulse wireplumber \
playerctl feh zsh neovim btop lsd bat python-gobject pipewire-alsa xcolor-pick \
touchegg cliphist xorg-xset mpc xorg-xprop xorg-xwininfo xdg-utils \
xdg-user-dirs libpulse psmisc --needed
```

**Fonts / Fuentes:** Iosevka Nerd Font, JetBrains Mono Nerd Font, Hack Nerd Font, Material Design Icons, Weather Icons + icomoon fonts in `fonts/`

**Copy config / Copiar configuración:**

```bash
cp -r config/* ~/.config/
cp -r bin/* ~/.local/bin/
```

**No API keys needed / Sin API keys:** the weather widget uses **Open-Meteo** and auto-detects your location by IP.
**Sin API keys:** el widget de clima usa **Open-Meteo** y detecta tu ubicación por IP.

**Wallpapers:** place images in `~/fondos/`

**Logout & select AwesomeWM / Cerrar sesión e iniciar AwesomeWM**

</details>

---

<br>

## 🎨 SDDM: keep the sugar-candy login after a theme update / Mantener el login sugar-candy tras una actualización

The login screen uses the **bundled** `sddm-astronaut-theme` (Qt6) customized to look like **sugar-candy**. If you update the `sddm-astronaut-theme` AUR package, the update **overwrites** the theme with the stock look and you lose the sugar-candy style. To re-apply it, use the dedicated script:

La pantalla de inicio usa el tema **incluido** `sddm-astronaut-theme` (Qt6) personalizado para verse como **sugar-candy**. Si actualizas el paquete `sddm-astronaut-theme` (AUR), la actualización **sobrescribe** el tema con el aspecto por defecto y pierdes el estilo sugar-candy. Para re-aplicarlo, usa el script dedicado:

```bash
# From the repo root / Desde la raíz del repo
./setup-sddm-theme.sh
```

It will ask for your `sudo` password and then / Te pedirá tu contraseña `sudo` y luego:

1. **Copies the bundled theme** to `/usr/share/sddm/themes/` with the sugar-candy style (transparent login fields, white borders, orange accent, left-aligned form, `Welcome!` header).
   **Copia el tema incluido** a `/usr/share/sddm/themes/` con el estilo sugar-candy (campos transparentes, bordes blancos, acento naranja, formulario a la izquierda, cabecera `Welcome!`).
2. **Fixes the background folder permissions** (`/usr/share/sddm/backgrounds` owned by your user) so `system_menu` → **SDDM** can change the wallpaper without root.
   **Arregla los permisos de la carpeta de fondos** (`/usr/share/sddm/backgrounds` a tu usuario) para que `system_menu` → **SDDM** pueda cambiar el fondo sin root.
3. **Copies an initial background** from `~/fondos/` if there isn't one yet.
   **Copia un fondo inicial** desde `~/fondos/` si aún no hay ninguno.
4. **Activates the theme** writing `Current=sddm-astronaut-theme` in `/etc/sddm.conf.d/theme.conf`.
   **Activa el tema** escribiendo `Current=sddm-astronaut-theme` en `/etc/sddm.conf.d/theme.conf`.
5. **Enables the SDDM service** if it isn't already.
   **Habilita el servicio SDDM** si aún no está.

> It's safe to run it as many times as you want (idempotent). Log out afterwards to see the result.
> Es seguro ejecutarlo cuantas veces quieras (idempotente). Cierra sesión después para ver el resultado.

<br>

## 📁 Repository Structure / Estructura del Repositorio

```
awesome-rxyhn-remix/
├── bin/                      # Custom scripts (awesomefetch, screensht, xcolor-pick)
├── config/
│   ├── awesome/              # Main AwesomeWM configuration
│   │   ├── configuration/    # Autostart, keybindings, rules
│   │   ├── module/           # External modules (bling, rubato, layout-machi)
│   │   ├── scripts/          # Lua/Shell scripts (toggles, utilities)
│   │   ├── signal/           # Signals (volume, battery, playerctl, weather)
│   │   ├── theme/            # Themes, picom configs, rofi Rasi
│   │   ├── ui/               # Widgets, wibar, dashboard, lockscreen
│   │   ├── rc.lua            # Entry point
│   │   └── secrets.lua.template
│   ├── kitty/                # Terminal
│   ├── mpd/                  # MPD config
│   ├── ncmpcpp/              # MPD client
│   ├── nvim/                 # Neovim
│   ├── rofi/                 # Rofi menus
│   ├── starship/             # Prompt
│   ├── systemd/user/         # User services (mpd, mpd-mpris, udiskie, cleanup)
│   └── touchegg/             # Touchpad gestures
├── fonts/                    # Custom Icomoon fonts
├── fondos/                   # Wallpapers
├── sddm/sddm-astronaut-theme/  # SDDM theme (bundled, sugar-candy style, Qt6)
├── mscdown/                  # Submodule: YouTube music searcher
├── misc/                     # .Xresources, .profile, .zshrc
├── install.sh                # Main installer
├── setup-sddm-theme.sh       # Re-applies only the SDDM theme (no full install)
├── update_modules.sh         # Updates external modules (bling, rubato, machi)
├── check.sh                  # Syntax validator (Lua/Shell/Python)
└── opencode.json             # OpenCode agent config
```

---

<br>

## 📦 Dependencies / Dependencias Completas

The installer (`install.sh`) handles everything automatically. Full list for Arch/Manjaro:

```bash
yay -S --needed \
  awesome-git picom-git kitty rofi todo-bin acpi acpid \
  wireless_tools jq inotify-tools polkit-gnome xdotool xclip maim \
  brightnessctl alsa-utils alsa-tools pipewire pipewire-pulse wireplumber libpulse psmisc \
  qt5-imageformats qt6-imageformats \
  playerctl spotify mpd mpc ncmpcpp mpd-mpris blueman pasystray \
  touchegg redshift networkmanager bluez libnotify curl ffmpeg gpick \
  imagemagick thunar firefox xorg-xrdb yad xcolor-pick cliphist xdg-utils xdg-user-dirs \
  nerd-fonts-jetbrains-mono ttf-iosevka-nerd ttf-hack-nerd ttf-font-awesome \
  ttf-material-design-icons ttf-weather-icons \
  zsh-syntax-highlighting zsh-autosuggestions zsh-sudo zoxide feh zsh neovim \
  btop lsd bat python-dbus python-gobject python-pip python-pyqt5 pipewire-alsa \
  powerlevel10k fzf starship autorandr xorg-xrandr pamixer gtk3 \
  sound-theme-freedesktop xorg-xset xorg-xprop xorg-xwininfo \
  bc pacman-contrib xorg-setxkbmap upower lua git
```

> **What are the new ones for?**
> - `bc` — needed by `cycle-accent.sh` (darken colors when cycling accent)
> - `pacman-contrib` — `paccache` used by `limpiar_sistema.sh`
> - `xorg-setxkbmap` — `change-keyboard.sh` and keyboard shortcut
> - `upower` — `bluetooth.sh` shows device battery
> - `lua` — `luac` for `check.sh`
> - `git` — submodules and cloning powerlevel10k
> - `mpd-mpris` — MPRIS bridge for media controls (dashboard, notifications)
> - `udiskie` + `udisks2` — auto-mount USB/external drives (enabled by default)

---

<br>

## 🔧 Systemd Services / Servicios systemd

| Service | Type | Description |
|---|---|---|
| `mpd.service` | user | Music server (mpd) |
| `mpd-mpris.service` | user | MPRIS bridge → media controls in dashboard/notifications |
| `udiskie.service` | user | Auto-mount USB/external drives with notifications |
| `limpiar-sistema.timer` | user | Auto cleanup every 3 days (`limpiar_sistema.sh`) |
| `touchegg.service` | system (root) | Touchpad gestures daemon |

> **Note:** user services enabled with `systemctl --user enable --now`. The `touchegg` daemon runs as root; the client launches from autostart.

---

<br>

## 🩹 Troubleshooting / Solución de problemas

<details>
<summary><strong>🔍 Validate config before restarting</strong></summary>

<br>

```bash
# From repo (before install)
config/awesome/scripts/check.sh

# From installed config
~/.config/awesome/scripts/check.sh

# Continuous watch mode
~/.config/awesome/scripts/check.sh --watch
```

> Exit code `0` = OK, `1` = syntax errors (shows file:line). Run **before reloading Awesome (`Super+Ctrl+R`) or committing** to avoid breaking your session.

</details>

<details>
<summary><strong>🎨 SDDM / Changing the login screen background</strong></summary>

<br>

The login theme is **sddm-astronaut-theme** (Qt6 compatible). It uses a fixed background image:

```
/usr/share/sddm/backgrounds/sddm_wallpaper.jpg
```

To change it whenever you want:

1. Open `system_menu` → **SDDM** (or run `set-sddm-bg.sh`).
2. Pick an image from `~/fondos/`.
3. Log out to see the new background (it doesn't apply in real time).

> The installer assigns `/usr/share/sddm/backgrounds` to your user. If you ever lack permissions, the script falls back to `pkexec` (it will ask for your password graphically).

> If a `sddm-astronaut-theme` AUR update overwrites the customization, re-apply the sugar-candy look with `./setup-sddm-theme.sh` — see the visible section **🎨 SDDM: keep the sugar-candy login after a theme update** above / mira la sección visible **🎨 SDDM: mantener el login sugar-candy tras una actualización** más arriba.

If you see the default SDDM theme on login instead of the astronaut one:

```bash
# Check the active theme
cat /etc/sddm.conf.d/theme.conf
# It should say: Current=sddm-astronaut-theme

# Re-enable it if missing
echo -e "[Theme]\nCurrent=sddm-astronaut-theme" | sudo tee /etc/sddm.conf.d/theme.conf

# If the theme folder is missing, re-apply it with the bundled script:
sudo cp -r sddm/sddm-astronaut-theme /usr/share/sddm/themes/
# (or simply: ./setup-sddm-theme.sh)
```

> The original **sugar-candy** theme is no longer used: its Qt5 build fails with SDDM 0.21+/Qt6. It was replaced by **sddm-astronaut-theme**, bundled in this repo and customized with the same visual style (transparent login fields with white borders, orange accent `#fb884f`, left-aligned form, `Welcome!` header).

</details>

<details>
<summary><strong>🎵 No sound / MPD won't start</strong></summary>

<br>

```bash
# Check services
systemctl --user status mpd.service mpd-mpris.service

# Enable if missing
systemctl --user enable --now mpd.service mpd-mpris.service

# Verify config
cat ~/.config/mpd/mpd.conf
# music_directory must be ~/Music (created by install.sh)
```

</details>

<details>
<summary><strong>🎨 Accent cycling doesn't darken properly (missing bc)</strong></summary>

<br>

```bash
sudo pacman -S bc
```
> `cycle-accent.sh` uses `bc -l` to calculate dark accent tones.

</details>

<details>
<summary><strong>⚙️ Awesome enters fallback mode (black/broken screen)</strong></summary>

<br>

1. `Mod+Ctrl+Shift+R` reloads config (if responsive).
2. If not: switch to TTY (`Ctrl+Alt+F3`), run:
   ```bash
   ~/.config/awesome/scripts/check.sh
   ```
   Fix any errors shown.
3. `awesome -k -c ~/.config/awesome/rc.lua` validates full syntax.

</details>

<details>
<summary><strong>🔐 secrets.lua / weather not working</strong></summary>

<br>

```bash
# If missing, generated from template on install
cp ~/.config/awesome/secrets.lua.template ~/.config/awesome/secrets.lua
# Edit weather_location_override to force location
```

> Widget uses **Open-Meteo** (no API key) + automatic IP geolocation.

</details>

<details>
<summary><strong>📦 AUR packages fail to install</strong></summary>

<br>

```bash
# Verify AUR helper
command -v yay || command -v paru

# Clean cache and retry
yay -S --clean
# or
paru -S --clean
```

</details>

---

<br>

## 🙏 Credits / Créditos

**rxyhn** — Original design • **Alpharivs** — Base fork • **s4vitar** — Zsh config • **ner0z** — Colorscheme night • **ChocolateBread799**, **JavaCafe01** — Original contributions

| Source | Description |
|---|---|
| [rxyhn](https://github.com/rxyhn) (original, deleted) | Original AwesomeWM dotfiles |
| [Alpharivs](https://github.com/Alpharivs/dotfiles) | Base fork used for this remix |
| [s4vitar](https://github.com/s4vitar) | Zsh configuration |
| [ner0z](https://github.com/ner0z) | Colorscheme night |

---

<br>

<div align="center">
  <p>
    <i>⭐ If you found this useful, please leave a star — it helps me keep improving it. Thanks! 🫶</i>
    <br>
    <i>⭐ Si este dotfiles te fue útil, ¡deja una estrella! Me ayuda a seguir mejorándolo. 🫶</i>
  </p>
  <br>

  [![GitHub stars](https://img.shields.io/github/stars/fc4419039/awesome-rxyhn-remix?style=for-the-badge&label=★%20STARS&color=7c3aed&labelColor=0f0f0f)](https://github.com/fc4419039/awesome-rxyhn-remix/stargazers)
  [![GitHub license](https://img.shields.io/badge/License-GPL--3.0-67AFC1?style=for-the-badge&labelColor=0f0f0f)](https://github.com/fc4419039/awesome-rxyhn-remix/blob/main/LICENSE)

  <br>
  <p align="center"><a href="https://github.com/fc4419039/awesome-rxyhn-remix/blob/main/LICENSE"><img src="https://img.shields.io/static/v1.svg?style=flat-square&label=License&message=GPL-3.0&logoColor=eceff4&logo=github&colorA=061115&colorB=67AFC1"/></a></p>
</div>