--[[
 _____ __ _ __ _____ _____ _____ _______ _____
|     |  | |  |  ___|  ___|     |       |  ___|
|  -  |  | |  |  ___|___  |  |  |  | |  |  ___|
|__|__|_______|_____|_____|_____|__|_|__|_____|
         ~ AestheticArch ~
                rxyhn
--]]
pcall(require, "luarocks.loader")


-- Standard awesome library
local gears = require("gears")
local gfs = require("gears.filesystem")
local awful = require("awful")
local naughty = require("naughty")
local beautiful = require("beautiful")

-- Theme handling library (Cargado primero para asegurar referencias en módulos UI)
beautiful.init(gfs.get_configuration_dir() .. "theme/theme.lua")
dpi = beautiful.xresources.apply_dpi

-- Default Applications
terminal = "kitty"
spotify = "spotify"
editor = "kitty nvim"
nvim = "kitty nvim"
browser = "env MOZ_GTK_TITLEBAR_DECORATION=none firefox"
launcher = "rofi -show drun -theme " .. os.getenv("HOME") .. "/.config/awesome/theme/rofi.rasi"
file_manager = "thunar"
music_client = "kitty --session " .. os.getenv("HOME") .. "/.config/ncmpcpp/session.conf --class music --title ncmpcpp --config " .. os.getenv("HOME") .. "/.config/ncmpcpp/kitty-music.conf"

-- Weather API (cargar desde secrets.lua si existe, o usar defaults)
local ok, secrets = pcall(require, "secrets")
if ok then
    openweathermap_key = secrets.openweathermap_key
    openweathermap_city_id = secrets.openweathermap_city_id
    weather_units = secrets.weather_units
else
    openweathermap_key = nil
    openweathermap_city_id = nil
    weather_units = "metric"
end

-- Garbage Collector Settings (Valores estables para AwesomeWM)
collectgarbage("setpause", 110)
collectgarbage("setstepmul", 1000)

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
local blur_state = io.open("/tmp/awesome-blur-mode", "r")
local transparency_state = io.open("/tmp/awesome-transparency-mode", "r")
local picom_cfg = os.getenv("HOME") .. "/.config/awesome/theme/picom.conf"
if blur_state then
    picom_cfg = os.getenv("HOME") .. "/.config/awesome/theme/picom-blur.conf"
    blur_state:close()
elseif transparency_state then
    picom_cfg = os.getenv("HOME") .. "/.config/awesome/theme/picom-transparency.conf"
    transparency_state:close()
else
    -- Sin state files → verificar si .codebak persiste (reinicio con efecto activo)
    local codebak = io.open(os.getenv("HOME") .. "/.config/awesome/.codebak", "r")
    if codebak then
        codebak:close()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/reset-theme.sh")
    end
end
run_once("picom --config " .. picom_cfg)
awful.spawn("setxkbmap latam")
awful.spawn("touchegg")

-- Import Configuration, Signals and UI
-- NOTA: Estos deben cargarse después de definir las variables globales y el tema
require("configuration")
-- Deferred para que notif-sink-setup.sh tenga tiempo de crear los sinks
gears.timer.delayed_call(function()
    pcall(require, "signal")
end)
require("ui")

-- Wallpapers y scripts de sesión
awful.spawn(os.getenv("HOME") .. "/.config/cambiar_fondo.sh")

-- Temperatura de color ligeramente fría (7000K)
awful.spawn(os.getenv("HOME") .. "/.config/awesome/scripts/color_temp.sh")

os.setlocale(os.getenv("LANG") or "")

-- Auto-detectar monitores al inicio
awful.spawn.with_shell("autorandr --change")

-- Auto-detectar monitores externos y re-aplicar temperatura
screen.connect_signal("added", function()
    awful.spawn.with_shell("autorandr --change")
    awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/color_temp.sh")
end)
screen.connect_signal("removed", function()
    awful.spawn.with_shell("autorandr --change")
    awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/color_temp.sh")
end)

-- Auto-cambiar wallpaper cada 30 minutos
gears.timer({
    timeout = 1800,
    autostart = true,
    call_now = false,
    callback = function()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/cambiar_fondo.sh")
    end
})

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


