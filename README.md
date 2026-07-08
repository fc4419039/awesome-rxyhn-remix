<div align="center">
  <img src="https://awesomewm.org/images/awesome-logo.svg" height="80">
</div>

<br>

<div align="center">

[![GitHub stars](https://img.shields.io/github/stars/fc4419039/awesome-rxyhn-remix?style=for-the-badge&label=★%20STARS&color=7c3aed&labelColor=0f0f0f)](https://github.com/fc4419039/awesome-rxyhn-remix/stargazers)
[![GitHub license](https://img.shields.io/github/license/fc4419039/awesome-rxyhn-remix?style=for-the-badge&color=67AFC1&labelColor=0f0f0f)](https://github.com/fc4419039/awesome-rxyhn-remix/blob/main/LICENSE)
[![Install](https://img.shields.io/badge/⚡-INSTALL-7c3aed?style=for-the-badge&labelColor=0f0f0f)](https://github.com/fc4419039/awesome-rxyhn-remix#Installation--Instalaci%C3%B3n)
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

<br>

<div align="center">
  <h2>Stack</h2>
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

<!-- LANGUAGE SELECTOR -->

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
  <i>Complete <b>AwesomeWM</b> configuration — repaired, optimized, and extended with modern features.</i>
  <br><br>
  Based on the original work by <b>rxyhn</b> (deleted repository) and the <b>Alpharivs</b> fork.
</p>

<br>

### Wibar
Vertical bar on the **left** side (50px wide):
- **Pac-Man taglist** — Pac-Man (selected), Ghost (has windows), Dot (empty)
- **Battery arc chart** — dynamic colors (green/yellow/red), charging indicator
- **Digital clock** — stacked hour/minute
- **Window list** — hover tooltip with title and class
- **Notification center** button
- **Layoutbox** for switching layouts
- Auto-hide on maximize/fullscreen
- Toggle with `Ctrl+F`

### Dashboard
Slide-in panel from the left with:
- **Profile** with user photo
- **Music** — cover art, animated artist/title, progress bar
- **Media controls** — prev/play/next
- **12h clock**, **date**, **todo** arc chart & counter
- **Weather** — icon, temp, description, humidity, wind (OpenWeatherMap)
- **System stats** — volume, brightness, CPU, RAM with tooltips
- **Recent notifications** — scrollable list with clear button

### Stats Tooltip
Dropdown on battery/clock click:
- **Analog clock** drawn with Cairo
- **Battery** with dynamic icons
- **System uptime**
- **Interactive WiFi manager**:
  - Network scanning · Signal-sorted list · Password input · Connected indicator
- **Settings button** — opens the **System Menu** slide-out panel

### Notification Center
- Recent notification list with icon, title, message, timestamp
- **Do Not Disturb** toggle (persistent state, silences sounds)
- **Clear all** button
- Mouse wheel scrolling
- Slide animation

### Notification Audio System
- **Isolated PipeWire sink** for notifications
- **Screenshot sounds** (Insert/Alt+Insert) played on notification sink
- **Auto-router** for notification streams
- **Independent volume** via `volumen` (`Super+v`)
- **Low-latency loopback** to default sink (25ms)
- **DND** fully silences notification sounds

### Rofi Menus
- **Launcher** (`Super+d`) — centered, purple borders, cyan selection
- **WiFi** (`Super+Shift+w`) — searchable, robust SSID parsing
- **Bluetooth** (`Super+b`) — rewritten with modular functions
- **Power** (`Alt+F4`) — shutdown/reboot/lock/suspend
- **Volume** (`Super+v`) — GTK3 per-app sliders
- **Cycle accent** (`Ctrl+Super+b`) — switch between 12 accent colors instantly

### Window Decorations
**Standard titlebar:**
- Round buttons: close (red), maximize (yellow), float (purple)
- Info widgets: WiFi, public IP, VPN
- Centered window title
- **2px border** matching rofi accent color, changeable with `Ctrl+Super+b`
- **Borders & titlebars enabled by default.** Toggle:
  - `Ctrl+Super+Shift+B` — toggle borders
  - `Ctrl+Super+Shift+T` — toggle titlebars
- Both persist across Awesome reloads

**Music player (ncmpcpp windows):**
- Full replacement titlebar with album art
- Interactive progress bar (click to seek)
- Controls: prev, play/pause, next
- Buttons: loop, shuffle, playlist, visualizer
- Animated song text · Adjustable volume

### MSCDown — Music Searcher & Downloader
YouTube music search & download with interactive menu and direct mode:
- **Auto-install** with dotfiles or manually via `mscdown/install.sh`
- **Interactive menu** (`musica`)
- **Direct mode**: `musica Queen Bohemian Rhapsody`
- **Auto MPD sync** (optional)
- **Embedded metadata & thumbnails**
- **Adjustable quality**: 320/192/128 kbps, format mp3/m4a/ogg/wav
- **Isolated Python venv**
- Repo: [`fc4419039/mscdown`](https://github.com/fc4419039/mscdown)

### Lock Screen
- **PAM authentication**
- **English word clock** (e.g. "IT IS HALF PAST TEN")
- Music controls with cover art
- Rainbow key animation
- Shortcut: `Mod+Ctrl+L`

### Window Switcher (Alt+Tab)
- Live window thumbnails
- Keyboard navigation (Tab/arrows)
- Minimize/kill from switcher
- Auto-hide on Alt release

### Tag Preview
- Hover preview of tag contents
- Auto-positioned on correct monitor

### Multi-Monitor
- Full **multi-monitor** support
- Independent wibars, dashboards, tooltips, notification centers per screen
- Independent tags per monitor
- Navigate: `Mod+Ctrl+j/k`
- Move client: `Mod+o`

### Monitored System Signals

| Signal | Description |
|---|---|
| Battery | Percentage and status (30s) |
| Volume | Level and mute (wpctl polling every 0.5s) |
| Brightness | Level (inotify events) |
| CPU | Usage percentage (5s) |
| RAM | Used/total (20s) |
| Uptime | System uptime (60s) |
| Weather | OpenWeatherMap (1200s) |
| Todo | Task progress (inotify events) |
| Network | Status and SSID (30s) |
| Playerctl | Metadata, status, position |

### System Menu
Slide-out settings panel (200px) on the right side, toggled from the stats tooltip:
- **Blur** — toggle picom background blur on/off (reloads AwesomeWM, adapts theme)
- **Transparency** — toggle transparency mode without blur (reloads AwesomeWM, adapts theme)
- **Volume** — opens GTK3 per-app volume sliders
- **Night Mode** — redshift 3500K on/off
- **Network** — rofi WiFi menu
- **Bluetooth** — rofi Bluetooth menu
- **Wallpaper** — pick a custom image with yad file dialog
- **SDDM Wallpaper** — set lock screen background
- **Apps** — rofi application launcher
- **Music** — ncmpcpp music client
- **Cycle Accent** — switch between 12 accent colors
- **Titlebar / Borders** — toggle window titlebars or borders on all windows
- **Widgets** — toggle the desktop datetime widget visibility on/off
- **Power Menu** — shutdown/reboot/lock/suspend
- Auto-hides after 3 seconds of inactivity

### Available Layouts
- **Tile** (default) · **Floating** · **Centered** (bling) · **MSTab** (bling)
- **Horizontal** (bling) · **Machi** (interactive manual) · **Equalarea** (bling) · **Deck** (bling)

### Keyboard Shortcuts

| Key | Action |
|---|---|
| `Mod+Enter` | Terminal (kitty) |
| `Mod+d` | Rofi launcher |
| `Mod+Shift+d` | Dashboard |
| `Mod+w` | Web browser |
| `Mod+Shift+w` | Network menu |
| `Mod+b` | Bluetooth |
| `Mod+v` | Volume control |
| `Alt+F4` | Power menu |
| `Insert` | Full screenshot |
| `Alt+Insert` | Area screenshot |
| `Mod+z` | Scratchpad |
| `Mod+Ctrl+l` | Lock screen |
| `Ctrl+Super+b` | Cycle accent color |
| `Ctrl+Super+Shift+B` | Toggle borders |
| `Ctrl+Super+Shift+T` | Toggle titlebars |
| `Alt+Tab` | Window switcher |
| `Mod+q` | Close window |
| `Mod+f` | File manager |
| `Mod+Ctrl+j/k` | Navigate monitors |
| `Ctrl+F` | Toggle wibar |
| `Mod+[1-5]` | Switch tag |
| `Mod+Shift+[1-5]` | Move to tag |
| `Mod+Arrow` | Directional focus |
| `Mod+Shift+Arrow` | Directional swap |
| `Mod+=/-` | Adjust useless gap |
| `Mod+Shift+=/-` | Adjust padding |
| `Mod+s` | Tile layout |
| `Mod+Shift+s` | Floating layout |
| `Mod+Space` | Next layout |
| `Alt+a/s/d` | Tab group/iterate/ungroup |

### Extras
- **Sloppy focus** — mouse follows focus
- **Flash focus** — flash on focus change
- **Desktop context menu** with **Wallpapers** submenu:
  - **Interactive background** — random wallpaper from `~/fondos/` on reload
  - **Choose image** — `yad` file picker to set wallpaper manually
  - **Lock screen** — set SDDM lock screen background
- **Scratchpad** floating terminal (`Mod+z`)
- **Window swallowing** — terminals replaced by launched apps
- **Save floats** — preserves floating window positions across tags
- **Better resize** — improved tiled resize
- **Rounded corners** on windows
- **OSD notifications** for volume/brightness with progress bars (no watermark, adaptive bg)
- **Tooltip fix** — tooltip window is now visible (was transparent due to `beautiful.transparent`)
- **Blur toggle** — `toggle-blur.sh` switches picom compositor blur on/off with full theme adaptation
- **Transparency toggle** — `toggle-transparency.sh` enables transparency without blur (lighter picom), adapts theme
- **Emergency reset** — `reset-theme.sh` restores original theme and removes all state files if something breaks
- **Solid fallback theme** — `theme_solid.lua` is used when blur/transparency is off, ensuring backgrounds are opaque
- **Three picom configs** — `picom.conf` (solid), `picom-blur.conf` (blur), `picom-transparency.conf` (transparency); each with `inactive-opacity = 1.0` + `override = false` to respect per-window alpha, `dock = { opacity = 1.0 }` for panels, and custom opacity rules for browsers/media apps
- **Layout selector** with icon preview
- **Lock screen** uses PAM with `liblua_pam.so` (precompiled for Arch x86_64)
- **OpenCode** AI agent config included (`opencode.json`)
- **Desktop widget configurable menu** — click the datetime widget on the desktop to open a settings menu with color presets, visibility toggles, and size controls

<br>

---

<br>

<!-- ==================== ESPAÑOL ==================== -->

<h1 align="center" id="español">🇪🇸 Español</h1>

<p align="center">
  <i>Configuración completa de <b>AwesomeWM</b>, reparada, optimizada y extendida con funcionalidades modernas.</i>
  <br><br>
  Basado en el trabajo original de <b>rxyhn</b> (repo eliminado) y el <b>Alpharivs</b> fork.
</p>

<br>

### Wibar
Barra vertical en el lateral **izquierdo** (50px de ancho):
- **Taglist personalizado** — Pac-Man (seleccionado), Fantasma (con ventanas), Punto (vacío)
- **Arcchart de batería** — colores dinámicos verde/amarillo/rojo, indicador de carga
- **Reloj digital** — hora/minuto apilados verticalmente
- **Lista de ventanas** — tooltip con título y clase al hover
- Botón de **centro de notificaciones**
- **Layoutbox** para cambiar layouts
- Auto-ocultamiento al maximizar o pantalla completa
- Atajo `Ctrl+F` para ocultar/mostrar

### Dashboard
Panel deslizable desde la izquierda con:
- **Perfil** con foto de usuario
- **Música** — carátula, artista/título animado, barra de progreso
- **Controles multimedia** — anterior/reproducir/siguiente
- **Reloj 12h**, **fecha**, **Todo** con gráfico de arco y contador
- **Clima** — icono, temperatura, descripción, humedad, viento (OpenWeatherMap)
- **Estadísticas** — volumen, brillo, CPU, RAM con tooltips
- **Notificaciones recientes** — lista scrolleable con botón limpiar

### Panel de estadísticas (Stats Tooltip)
Panel desplegable al hacer clic en batería/reloj:
- **Reloj analógico** dibujado con Cairo
- **Batería** con iconos dinámicos
- **Uptime** del sistema
- **Gestor WiFi interactivo**:
  - Escaneo de redes · Lista ordenada por señal · Conexión con contraseña · Indicador de red conectada
- **Botón de ajustes** — abre el **System Menu**

### Centro de notificaciones
- Lista con icono, título, mensaje y timestamp
- **No molestar** (persiste, silencia sonidos)
- **Limpiar todas**
- Scroll con rueda del mouse
- Animación slide

### Sistema de audio de notificaciones
- **Sink independiente** en PipeWire
- **Sonido al capturar pantalla** (Insert/Alt+Insert)
- **Router automático** de streams
- **Volumen independiente** desde `volumen` (`Super+v`)
- **Loopback** de baja latencia (25ms)
- **No molestar** silencia todo

### Menús Rofi
- **Launcher** (`Super+d`) — centrado, bordes púrpura, selección cyan
- **WiFi** (`Super+Shift+w`) — buscador, parsing robusto
- **Bluetooth** (`Super+b`) — funciones modulares
- **Power** (`Alt+F4`) — apagado/reinicio/bloqueo/suspensión
- **Volumen** (`Super+v`) — GTK3 con sliders por app
- **Cycle accent** (`Ctrl+Super+b`) — cambia entre 12 colores de acento

### Decoraciones de ventana
**Barra de título estándar:**
- Botones redondos: cerrar (rojo), maximizar (amarillo), flotar (púrpura)
- Widgets: WiFi, IP pública, VPN
- Título centrado
- **Borde de 2px** del color de acento, cambiable con `Ctrl+Super+b`
- **Bordes y titlebars activados por defecto:**
  - `Ctrl+Super+Shift+B` — quitar/poner bordes
  - `Ctrl+Super+Shift+T` — quitar/poner titlebars
- Persisten entre recargas

**Reproductor (ventanas ncmpcpp):**
- Titlebar reemplazada por reproductor completo
- Carátula, barra de progreso interactiva
- Controles, loop/shuffle/playlist/visualizador
- Texto animado · Volumen ajustable

### MSCDown — Music Searcher & Downloader
Buscador y descargador de música desde YouTube:
- **Instalación automática** con el dotfiles o manual desde `mscdown/install.sh`
- **Menú interactivo** (`musica`)
- **Modo directo**: `musica Queen Bohemian Rhapsody`
- **Sincronización automática con MPD** (opcional)
- **Metadatos y miniaturas** embebidos
- **Calidad ajustable**: 320/192/128 kbps, formato mp3/m4a/ogg/wav
- **Entorno virtual aislado**
- Repo: [`fc4419039/mscdown`](https://github.com/fc4419039/mscdown)

### Lock Screen
- **Autenticación PAM**
- **Word clock** en inglés ("IT IS HALF PAST TEN")
- Controles de música con carátula
- Animación arcoíris en teclas
- Atajo: `Mod+Ctrl+L`

### Window Switcher (Alt+Tab)
- Thumbnails en vivo
- Navegación con teclado
- Minimizar/matar desde el switcher
- Auto-ocultamiento al soltar Alt

### Tag Preview
- Vista previa del tag al hover
- Posicionado automático

### Gestión de pantallas
- **Soporte multi-monitor** completo
- Wibar, dashboard, tooltip y notificaciones independientes
- Tags independientes por monitor
- Navegar: `Mod+Ctrl+j/k`
- Mover cliente: `Mod+o`

### Señales del sistema monitoreadas

| Señal | Descripción |
|---|---|
| Batería | Porcentaje y estado (c/30s) |
| Volumen | Nivel y mute (wpctl polling c/0.5s) |
| Brillo | Nivel (eventos inotify) |
| CPU | Uso porcentual (c/5s) |
| RAM | Usada/total (c/20s) |
| Uptime | Tiempo encendido (c/60s) |
| Clima | OpenWeatherMap (c/1200s) |
| Todo | Progreso (eventos inotify) |
| Red | Estado y SSID (c/30s) |
| Playerctl | Metadatos, estado, posición |

### System Menu
Panel deslizable de ajustes (200px) en el lateral derecho, abierto desde el tooltip:
- **Blur** — activa/desactiva el blur de picom (recarga AwesomeWM, adapta el tema)
- **Transparencia** — activa modo transparencia sin blur (recarga AwesomeWM, adapta el tema)
- **Volumen** — sliders GTK3 por aplicación
- **Modo noche** — redshift 3500K on/off
- **Red** — menú rofi WiFi
- **Bluetooth** — menú rofi Bluetooth
- **Fondo** — selector de wallpaper con yad
- **Fondo SDDM** — cambiar fondo de pantalla de bloqueo
- **Apps** — lanzador rofi
- **Música** — ncmpcpp
- **Cycle Accent** — cambia entre 12 colores de acento
- **Titlebar / Borders** — oculta/muestra barras de título o bordes
- **Widgets** — mostrar/ocultar el widget de escritorio (fecha/hora)
- **Power Menu** — apagado/reinicio/bloqueo/suspensión
- Se oculta automáticamente tras 3s de inactividad

### Layouts disponibles
- **Tile** (default) · **Floating** · **Centered** (bling) · **MSTab** (bling)
- **Horizontal** (bling) · **Machi** (manual interactivo) · **Equalarea** (bling) · **Deck** (bling)

### Atajos de teclado

| Tecla | Acción |
|---|---|
| `Mod+Enter` | Terminal (kitty) |
| `Mod+d` | Rofi lanzador |
| `Mod+Shift+d` | Dashboard |
| `Mod+w` | Navegador web |
| `Mod+Shift+w` | Menú de redes |
| `Mod+b` | Bluetooth |
| `Mod+v` | Control de volumen |
| `Alt+F4` | Menú de apagado |
| `Insert` | Captura de pantalla |
| `Alt+Insert` | Captura de área |
| `Mod+z` | Scratchpad |
| `Mod+Ctrl+l` | Lock screen |
| `Ctrl+Super+b` | Cycle accent color |
| `Ctrl+Super+Shift+B` | Quitar/poner bordes |
| `Ctrl+Super+Shift+T` | Quitar/poner titlebars |
| `Alt+Tab` | Window switcher |
| `Mod+q` | Cerrar ventana |
| `Mod+f` | Explorador de archivos |
| `Mod+Ctrl+j/k` | Navegar pantallas |
| `Ctrl+F` | Ocultar/mostrar wibar |
| `Mod+[1-5]` | Cambiar tag |
| `Mod+Shift+[1-5]` | Mover a tag |
| `Mod+Arrow` | Foco direccional |
| `Mod+Shift+Arrow` | Intercambiar direccional |
| `Mod+=/-` | Ajustar useless gap |
| `Mod+Shift+=/-` | Ajustar padding |
| `Mod+s` | Layout tile |
| `Mod+Shift+s` | Layout floating |
| `Mod+Space` | Siguiente layout |
| `Alt+a/s/d` | Agrupar/iterar/desagrupar pestañas |

### Extras
- **Sloppy focus** — el foco sigue al mouse
- **Flash focus** — destello al cambiar foco
- **Menú contextual** en escritorio con **"Fondos"**:
  - **Fondo interactivo** — wallpaper aleatorio desde `~/fondos/`
  - **Elegir imagen** — selector gráfico `yad`
  - **Pantalla de bloqueo** — fondo del lock screen SDDM
- **Scratchpad** terminal flotante (`Mod+z`)
- **Window swallowing** — terminales reemplazadas por apps
- **Save floats** — preserva posición flotante entre tags
- **Better resize** — redimensionado mejorado
- **Esquinas redondeadas**
- **Notificaciones OSD** para volumen/brillo (sin watermark, fondo adaptable)
- **Tooltip corregido** — la ventana del tooltip ahora es visible (era transparente por `beautiful.transparent`)
- **Toggle Blur** — `toggle-blur.sh` activa/desactiva el blur de picom adaptando el tema completo
- **Toggle Transparencia** — `toggle-transparency.sh` activa transparencia sin blur (picom más ligero), adapta el tema
- **Reset de emergencia** — `reset-theme.sh` restaura el tema original y limpia archivos de estado ante fallos
- **Tema sólido de respaldo** — `theme_solid.lua` se usa sin blur/transparencia para fondos opacos
- **Tres configs de picom** — `picom.conf` (sólido), `picom-blur.conf` (blur), `picom-transparency.conf` (transparencia); cada uno con `inactive-opacity = 1.0` + `override = false` para respetar el alpha por ventana, `dock = { opacity = 1.0 }` para paneles, y reglas de opacidad para navegadores/media
- **Selector de layouts** con vista previa
- **Lock screen** usa PAM (`liblua_pam.so` para Arch x86_64)
- **OpenCode** agente de IA incluido (`opencode.json`)
- **Menú configurable del widget de escritorio** — haz clic en el widget de fecha/hora para abrir un menú de ajustes con colores preseleccionados, alternar visibilidad y controles de tamaño

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

> ⚠️ `sudo` is only required for the SDDM theme installation.
> ⚠️ El script requiere `sudo` solo para instalar el tema SDDM.

</details>

<br>

<details>
<summary><strong>🔧 Manual</strong></summary>

<br>

**Dependencies / Dependencias** (Arch Linux):

```bash
yay -Sy awesome-git picom-git kitty rofi todo-bin acpi acpid \
wireless_tools jq inotify-tools polkit-gnome xdotool xclip maim \
brightnessctl alsa-utils alsa-tools pipewire pipewire-pulse wireplumber \
playerctl feh zsh neovim btop lsd bat python-gobject pipewire-alsa xcolor-pick --needed
```

**Fonts / Fuentes:** Iosevka Nerd Font, Material Design Icons, Weather Icons + icomoon fonts in `fonts/`

**Copy config / Copiar configuración:**

```bash
cp -r config/* ~/.config/
cp -r bin/* ~/.local/bin/
```

**Configure / Configurar:** Set `openweathermap_key` and `openweathermap_city_id` in `rc.lua`

**Wallpapers:** Place images in `~/fondos/`

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
