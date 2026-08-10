-- Fail-safe: si la pantalla estaba bloqueada al crashear Awesome, lanzar
-- i3lock ANTES de cargar cualquier código. Evita que un error en rc.lua
-- o en los módulos de Awesome deje la pantalla desbloqueada.
do
    local c = os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")
    local f = io.open(c .. "/lockscreen/awesome-locked", "r")
    if f then
        f:close()
        os.execute("i3lock -n -e >/dev/null 2>&1")
        os.remove(c .. "/lockscreen/awesome-locked")
        os.remove(c .. "/lockscreen/x-session-env")
        os.remove(c .. "/lockscreen/xauth-cache")
    end
end

--[[
 _____ __ _ __ _____ _____ _____ _______ _____
|     |  | |  |  ___|  ___|     |       |  ___|
|  -  |  | |  |  ___|___  |  |  |  | |  |  ___|
|__|__|_______|_____|_____|_____|__|_|__|_____|
         ~ AestheticArch ~
                rxyhn
--]]
pcall(require, "luarocks.loader")

-- Log de tiempo de arranque (diagnóstico profesional)
local boot_start = os.clock()
local boot_prev = boot_start
local boot_marks = {}
local function boot_mark(label)
    local now = os.clock()
    boot_marks[#boot_marks + 1] = string.format("%-10s %6.0f ms", label, (now - boot_prev) * 1000)
    boot_prev = now
end
local function boot_flush()
    boot_marks[#boot_marks + 1] = string.format("%-10s %6.0f ms", "TOTAL", (os.clock() - boot_start) * 1000)
    local f = io.open("/tmp/awesome-startup-time.log", "a")
    if f then
        f:write(os.date("%H:%M:%S") .. "  arranque awesome\n")
        for _, line in ipairs(boot_marks) do f:write("  " .. line .. "\n") end
        f:write(string.rep("-", 26) .. "\n")
        f:close()
    end
end

-- Standard awesome library
local gears = require("gears")
local gfs = require("gears.filesystem")
local awful = require("awful")
local naughty = require("naughty")
local beautiful = require("beautiful")
boot_mark("core")

-- Theme handling library (Cargado primero para asegurar referencias en módulos UI)
beautiful.init(gfs.get_configuration_dir() .. "theme/theme.lua")
dpi = beautiful.xresources.apply_dpi
boot_mark("theme")

-- Default Applications
terminal = "kitty"
spotify = "spotify"
editor = "kitty nvim"
nvim = "kitty nvim"
browser = "env MOZ_GTK_TITLEBAR_DECORATION=none firefox"
launcher = "rofi -show drun -theme " .. os.getenv("HOME") .. "/.config/awesome/theme/rofi.rasi"
file_manager = "thunar"
music_client = "kitty --session " .. os.getenv("HOME") .. "/.config/ncmpcpp/session.conf --class music --title ncmpcpp --config " .. os.getenv("HOME") .. "/.config/ncmpcpp/kitty-music.conf"

-- Weather (cargar desde secrets.lua si existe, o usar defaults)
-- Proveedor: Open-Meteo (sin API key) + ubicación automática por IP.
local ok, secrets = pcall(require, "secrets")
if ok then
    weather_units = secrets.weather_units
    weather_location_override = secrets.weather_location_override
else
    weather_units = "metric"
    weather_location_override = nil
end

-- Garbage Collector Settings (Valores estables para AwesomeWM)
collectgarbage("setpause", 110)
collectgarbage("setstepmul", 200)

-- Traducción de la UI (sigue el LANG de /etc/locale.conf)
i18n = require("i18n")

-- Función para ejecutar aplicaciones solo si no están corriendo
local function run_once(cmd)
    local findme = cmd
    local firstspace = cmd:find(" ")
    if firstspace then
        findme = cmd:sub(1, firstspace - 1)
    end
    awful.spawn(string.format("pgrep -x %s > /dev/null 2>&1 || %s", findme, cmd))
end

-- Autostart de servicios base
awful.spawn(gfs.get_configuration_dir() .. "configuration/autostart")
awful.spawn(os.getenv("HOME") .. "/.config/awesome/scripts/notif-sink-setup.sh")
-- Estado de picom persistente en ~/.cache/awesome (sobrevive al reinicio).
-- Fallback: /tmp (estado antiguo) y .codebak (reinicio con efecto activo).
local home_dir = os.getenv("HOME")
local state_dir = home_dir .. "/.cache/awesome"
local function state_active(name)
    local f = io.open(state_dir .. "/" .. name, "r")
    if f then f:close(); return true end
    f = io.open("/tmp/" .. name, "r")
    if f then f:close(); return true end
    return false
end
local blur_state = state_active("blur-mode")
local transparency_state = state_active("transparency-mode")
local picom_cfg = home_dir .. "/.config/awesome/theme/picom.conf"
if blur_state then
    picom_cfg = home_dir .. "/.config/awesome/theme/picom-blur.conf"
elseif transparency_state then
    picom_cfg = home_dir .. "/.config/awesome/theme/picom-transparency.conf"
else
    -- Sin state files → verificar si .codebak persiste (reinicio con efecto activo)
    local codebak = io.open(home_dir .. "/.config/awesome/.codebak", "r")
    if codebak then
        codebak:close()
        awful.spawn.with_shell(home_dir .. "/.config/awesome/scripts/reset-theme.sh")
    end
end
run_once("picom --config " .. picom_cfg)
-- Leer layout guardado de localectl (persiste entre sesiones)
awful.spawn.with_shell('layout=$(localectl status 2>/dev/null | grep "X11 Layout:" | awk \'{print $NF}\'); [ -n "$layout" ] && setxkbmap "$layout" || setxkbmap latam')
-- Matar todos los touchegg viejos antes de iniciar uno nuevo
-- (evita acumulación de procesos que atrapan eventos del mouse)
-- Nota: solo el daemon; el client lo lanza autostart y no debe morirse
awful.spawn.with_shell("pkill -u $(whoami) -f 'touchegg --daemon' 2>/dev/null; sleep 0.2; pgrep -u $(whoami) -f 'touchegg --daemon' > /dev/null 2>&1 || nohup touchegg > /dev/null 2>&1 &")

-- Import Configuration, Signals and UI
-- NOTA: Estos deben cargarse después de definir las variables globales y el tema
require("configuration")
boot_mark("config")
 -- Deferred para que notif-sink-setup.sh tenga tiempo de crear los sinks
 gears.timer.delayed_call(function()
     local t0 = os.clock()
     pcall(require, "signal")
     boot_marks[#boot_marks + 1] = string.format("%-10s %6.0f ms", "signal", (os.clock() - t0) * 1000)
 end)
 require("ui")
 boot_mark("ui")
 require("ui.reload")

 -- Global UI Watchdog (inicia después de que UI esté lista)
 gears.timer.delayed_call(function()
     local ok, watchdog = pcall(require, "configuration.watchdog")
     if ok and watchdog and watchdog.start then
         watchdog.start()
     end
 end)

-- Wallpapers y scripts de sesión
awful.spawn(os.getenv("HOME") .. "/.config/cambiar_fondo.sh")
awful.spawn(os.getenv("HOME") .. "/.config/awesome/scripts/pregen_fondos_thumbs.sh")

-- Temperatura de color ligeramente fría (7000K)
awful.spawn(os.getenv("HOME") .. "/.config/awesome/scripts/color_temp.sh")

-- Leer locale de /etc/locale.conf y propagarlo a toda la sesión
do
    local f = io.open("/etc/locale.conf", "r")
    if f then
        local line = f:read("*l")
        f:close()
        local lang = line and line:match("^LANG=(.+)")
        if lang and lang ~= "" then
            local ok, lgi = pcall(require, "lgi")
            if ok then
                local GLib = lgi.GLib
                GLib.setenv("LANG", lang, true)
                for _, var in ipairs({"LC_CTYPE", "LC_NUMERIC", "LC_TIME", "LC_COLLATE", "LC_MONETARY", "LC_MESSAGES", "LC_PAPER", "LC_NAME", "LC_ADDRESS", "LC_TELEPHONE", "LC_IDENTIFICATION"}) do
                    GLib.setenv(var, lang, true)
                end
            end
        end
    end
end
os.setlocale(os.getenv("LANG") or "")

-- Auto-detectar monitores al inicio
awful.spawn.with_shell("autorandr --change")

-- Debounced autorandr: evita cascada de signals que destruyen la wibar
local autorandr_timer = nil
local function debounced_autorandr()
    if autorandr_timer then autorandr_timer:stop() end
    autorandr_timer = gears.timer.start_new(2, function()
        awful.spawn.with_shell("autorandr --change")
        autorandr_timer = nil
        return false
    end)
end

-- Auto-detectar monitores externos y re-aplicar temperatura
screen.connect_signal("added", function()
    debounced_autorandr()
    awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/color_temp.sh")
end)
screen.connect_signal("removed", function()
    debounced_autorandr()
    awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/color_temp.sh")
end)



-- Watchdog: verificar cada 30s que los sinks de audio existan
-- Si pipewire-pulse se reinicia, los sinks virtuales se pierden
gears.timer({
    timeout = 30,
    autostart = true,
    call_now = false,
    callback = function()
        awful.spawn.easy_async_with_shell(
            "wpctl status 2>/dev/null | grep -q notifications || "
            .. os.getenv("HOME") .. "/.config/awesome/scripts/notif-sink-setup.sh",
            function() end
        )
    end
})

-- Volcar el log de tiempos una vez que signal ya se midió
-- Volcar el log de tiempos una vez que signal ya se midió
gears.timer.delayed_call(function()
    boot_flush()
end)


