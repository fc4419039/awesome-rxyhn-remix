<div align="center">
  <img src="https://awesomewm.org/images/awesome-logo.svg" height="80">
</div>

<br>

<div align="center">

[![GitHub stars](https://img.shields.io/github/stars/fc4419039/awesome-rxyhn-remix?style=for-the-badge&label=★%20STARS&color=7c3aed&labelColor=0f0f0f)](https://github.com/fc4419039/awesome-rxyhn-remix/stargazers)
[![GitHub license](https://img.shields.io/github/license/fc4419039/awesome-rxyhn-remix?style=for-the-badge&color=67AFC1&labelColor=0f0f0f)](https://github.com/fc4419039/awesome-rxyhn-remix/blob/main/LICENSE)
[![Install](https://img.shields.io/badge/⚡-INSTALL-7c3aed?style=for-the-badge&labelColor=0f0f0f)](https://github.com/fc4419039/awesome-rxyhn-remix#installation--instalación)
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
  <i>rxyhn's legendary dotfiles — lost to the void, now reborn with modern AwesomeWM APIs, bug fixes, and a bag of extras.</i>
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

<h2 align="center">
  <img src="https://img.shields.io/badge/-PREVIEW-7c3aed?style=for-the-badge&labelColor=0f0f0f">
</h2>

<br>

<div align="center">
  <table>
    <tr>
      <td width="50%" align="center">
        <img src=".github/assets/123.png" alt="Dashboard" style="border-radius: 12px; box-shadow: 0 4px 24px rgba(0,0,0,0.6);">
        <br>
        <sub><b>Dashboard</b></sub>
      </td>
      <td width="50%" align="center">
        <img src=".github/assets/login.png" alt="Lock Screen" style="border-radius: 12px; box-shadow: 0 4px 24px rgba(0,0,0,0.6);">
        <br>
        <sub><b>Lock Screen</b></sub>
      </td>
    </tr>
    <tr>
      <td width="50%" align="center">
        <img src=".github/assets/preview-widgets.png" alt="Widgets" style="border-radius: 12px; box-shadow: 0 4px 24px rgba(0,0,0,0.6);">
        <br>
        <sub><b>Widgets & Menus</b></sub>
      </td>
      <td width="50%" align="center">
        <img src=".github/assets/preview-btop.png" alt="BTOP" style="border-radius: 12px; box-shadow: 0 4px 24px rgba(0,0,0,0.6);">
        <br>
        <sub><b>System Monitor</b></sub>
      </td>
    </tr>
  </table>
</div>

<br>

---

<br>

<!-- ==================== ENGLISH ==================== -->

<h1 align="center" id="english">🇬🇧 English</h1>

<p align="center">
  A complete <b>AwesomeWM</b> configuration: repaired, optimized, and extended with modern features.
  Based on <b>rxyhn</b>'s original work (repo deleted) and the <b>Alpharivs</b> fork.
</p>

<br>

### Features

- **Wibar** — vertical bar on the left: Pac-Man taglist, battery arc, stacked clock, window list tooltips, layoutbox, notification-center button. Auto-hides on fullscreen (`Ctrl+F` to toggle).
- **Dashboard** — slide-in from the left: profile, music with cover art & progress, media controls, clock, todo arc, **weather** (Open-Meteo, no API key — location auto-detected by IP), system stats, recent notifications.
- **Notification Center** — scrollable history, clear-all, and a **Do Not Disturb that actually works**: popups are silenced *and queued* until you turn it back on.
- **Notification audio** — isolated PipeWire sink, screenshot sounds, auto-router, independent volume (`Super+v`), low-latency loopback, fully silenced by DND.
- **Rofi menus** — launcher, wifi, bluetooth, power, GTK3 volume sliders, and instant **accent cycling** across 12 colors.
- **Window decorations** — round buttons, WiFi/IP/VPN info, 2px accent border. **Borders & titlebars on by default** (`Ctrl+Super+Shift+B` / `+T` to toggle). ncmpcpp windows get a full music titlebar with album art, seek bar & controls.
- **Lock screen** — PAM auth, English word clock, music controls, rainbow keys (`Mod+Ctrl+L`).
- **Alt+Tab switcher** — live window thumbnails with keyboard navigation.
- **System Menu** — slide-out panel: blur, transparency, night mode, wallpaper, music, accent, borders/titlebars, widgets, power.
- **Layouts** — tile, floating, centered, mstab, horizontal, machi, equalarea, deck.
- **MSCDown** — bundled YouTube music searcher/downloader (`musica` or `musica <query>`), auto-installed with the dotfiles. The installer **skips it if already present**.
- **Multi-monitor** — independent wibars, dashboards and tags per screen (`Mod+Ctrl+j/k`).
- **Touchegg gestures** — 3-finger swipe for the desktop overview, 4-finger to change desktops, pinches to close windows or open the launcher.

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

### Extras

Sloppy & flash focus · window swallowing · scratchpad · save floats · better resize · rounded corners · OSD volume/brightness notifications · clipboard history (cliphist) · macOS-style floating calculator · desktop context menu with wallpaper picker · blur/transparency toggles that fully re-adapt the theme · `reset-theme.sh` emergency reset · three picom configs (solid/blur/transparency) · **UI watchdog** that auto-repairs broken panels · OpenCode AI config included.

### Developer Tools

`config/awesome/scripts/check.sh` validates the syntax of every Lua, Shell and Python file in the config — your dotfiles' CI. Run it **before restarting awesome or pushing** to catch errors that would crash the WM into fallback mode.

```bash
config/awesome/scripts/check.sh                       # from the repo (before install)
~/.config/awesome/scripts/check.sh                    # from your installed config
~/.config/awesome/scripts/check.sh <another/dir>      # check any directory (e.g. the repo)
~/.config/awesome/scripts/check.sh --watch            # continuous watch mode (every 2s)
```

Exit code `0` = all OK, `1` = syntax errors found (file:line shown).

<br>

---

<br>

<!-- ==================== ESPAÑOL ==================== -->

<h1 align="center" id="español">🇪🇸 Español</h1>

<p align="center">
  Configuración completa de <b>AwesomeWM</b>, reparada, optimizada y extendida con funcionalidades modernas.
  Basada en el trabajo original de <b>rxyhn</b> (repo eliminado) y el <b>Alpharivs</b> fork.
</p>

<br>

### Características

- **Wibar** — barra vertical a la izquierda: taglist Pac-Man, arco de batería, reloj apilado, tooltips de ventanas, layoutbox, botón del centro de notificaciones. Se oculta en pantalla completa (`Ctrl+F` para alternar).
- **Dashboard** — panel deslizable desde la izquierda: perfil, música con carátula y progreso, controles multimedia, reloj, arco de tareas, **clima** (Open-Meteo, sin API key — ubicación detectada por IP), estadísticas del sistema y notificaciones recientes.
- **Centro de notificaciones** — historial scrolleable, limpiar todo y un **no molestar que funciona de verdad**: silencia *y encola* los popups hasta que lo vuelvas a activar.
- **Audio de notificaciones** — sink aislado en PipeWire, sonidos de captura, router automático, volumen independiente (`Super+v`), loopback de baja latencia, silenciado por completo con no molestar.
- **Menús Rofi** — lanzador, wifi, bluetooth, power, sliders GTK3 de volumen y **cambio de acento** instantáneo entre 12 colores.
- **Decoraciones de ventana** — botones redondos, widgets WiFi/IP/VPN, borde de 2px del color de acento. **Bordes y titlebars activados por defecto** (`Ctrl+Super+Shift+B` / `+T` para alternar). Las ventanas de ncmpcpp tienen una titlebar de música completa con carátula, barra de búsqueda y controles.
- **Lock screen** — autenticación PAM, word clock en inglés, controles de música, teclas arcoíris (`Mod+Ctrl+L`).
- **Switcher Alt+Tab** — miniaturas en vivo con navegación por teclado.
- **System Menu** — panel deslizable: blur, transparencia, modo noche, fondo, música, acento, bordes/titlebars, widgets, power.
- **Layouts** — tile, floating, centered, mstab, horizontal, machi, equalarea, deck.
- **MSCDown** — buscador/descargador de música de YouTube incluido (`musica` o `musica <consulta>`), se instala automáticamente con el dotfiles. El instalador **lo salta si ya está presente**.
- **Multi-monitor** — wibar, dashboard y tags independientes por pantalla (`Mod+Ctrl+j/k`).
- **Gestos de Touchegg** — swipe de 3 dedos para el overview, 4 dedos para cambiar de escritorio, pinches para cerrar ventanas o abrir el lanzador.

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
| `Insert` / `Alt+Insert` | Captura / captura de área |
| `Mod+z` | Scratchpad |
| `Mod+Ctrl+l` | Lock screen |
| `Ctrl+Super+b` | Cycle accent color |
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

### Extras

Foco sloppy y flash · window swallowing · scratchpad · save floats · mejor redimensionado · esquinas redondeadas · OSD de volumen/brillo · historial del portapapeles (cliphist) · calculadora flotante estilo macOS · menú contextual con selector de fondo · toggles de blur/transparencia que re-adaptan el tema completo · reset de emergencia `reset-theme.sh` · tres configs de picom (sólido/blur/transparencia) · **UI watchdog** que repara paneles rotos · configuración del agente OpenCode incluida.

### Herramientas de desarrollo

`config/awesome/scripts/check.sh` valida la sintaxis de todos los archivos Lua, Shell y Python de la config — el "CI" de tus dotfiles. Ejecútalo **antes de reiniciar awesome o de hacer push** para detectar errores que romperían el WM y lo mandarían a modo fallback.

```bash
config/awesome/scripts/check.sh                       # desde el repo (antes de instalar)
~/.config/awesome/scripts/check.sh                    # desde tu config instalada
~/.config/awesome/scripts/check.sh <otro/dir>         # revisa cualquier directorio (ej. el repo)
~/.config/awesome/scripts/check.sh --watch            # modo vigilancia continua (cada 2s)
```

Código de salida `0` = todo OK, `1` = errores de sintaxis (muestra archivo:línea).

<br>

---

<br>

<!-- ==================== SHARED SECTIONS ==================== -->

<h2 align="center">Installation / Instalación</h2>

<br>

<details>
<summary><strong>📦 Automatic / Automática</strong></summary>

<br>

```bash
git clone --recurse-submodules https://github.com/fc4419039/awesome-rxyhn-remix.git
cd awesome-rxyhn-remix
chmod +x install.sh
./install.sh
```

> The installer is **smart**: it detects already-installed packages and skips them, won't reconfigure what's already configured, and won't re-clone or re-install mscdown if it's already present.
>
> El instalador es **inteligente**: detecta los paquetes ya instalados y los omite, no reconfigura lo ya configurado y no vuelve a clonar ni instalar mscdown si ya está presente.

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

<br>

---

<br>

<h2 align="center">Credits / Créditos</h2>

<div align="center">

**rxyhn** — Original design • **Alpharivs** — Fork base • **s4vitar** — Zsh config • **ner0z** — Colorscheme night • **ChocolateBread799**, **JavaCafe01** — Original contributions

<br>
<br>

| Source | Description |
|---|---|
| [rxyhn](https://github.com/rxyhn) (original, deleted) | Dotfiles original de AwesomeWM |
| [Alpharivs](https://github.com/Alpharivs/dotfiles) | Fork base usado para esta remix |
| [s4vitar](https://github.com/s4vitar) | Configuración de zsh |
| [ner0z](https://github.com/ner0z) | Colorscheme night |

</div>

<br>

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
