--[[
 _____ __ _ __ _____ _____ _____ _______ _____
|     |  | |  |  ___|  ___|     |       |  ___|
|  -  |  | |  |  ___|___  |  |  |  | |  |  ___|
|__|__|_______|_____|_____|_____|__|_|__|_____|
         ~ AestheticArch ~
                rxyhn
--]]
pcall(require, "luarocks.loader")

-- Override xapp-gtk3-module (viene con Thunar, rompe file chooser sin xdg-desktop-portal-xapp)
os.setenv("GTK3_MODULES", "")

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
browser = "firefox"
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
run_once("picom --config " .. os.getenv("HOME") .. "/.config/awesome/theme/picom.conf")
awful.spawn("pasystray")
awful.spawn("setxkbmap latam")
awful.spawn("touchegg")

-- Import Configuration, Signals and UI
-- NOTA: Estos deben cargarse después de definir las variables globales y el tema
require("configuration")
require("signal")
require("ui")

-- Wallpapers y scripts de sesión
awful.spawn(os.getenv("HOME") .. "/.config/cambiar_fondo.sh")

-- Temperatura de color ligeramente fría (7000K)
awful.spawn(os.getenv("HOME") .. "/.config/awesome/scripts/color_temp.sh")

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

-- Welcome notification solo al iniciar sesión (no al recargar)
if awesome.startup then
    gears.timer({
        timeout = 2,
        autostart = true,
        single_shot = true,
        callback = function()
            naughty.notify({
                title = "Bienvenido",
                text = "AwesomeWM listo — Mod+Ctrl+t para night mode",
                timeout = 5,
                bg = beautiful.xcolor0,
                fg = beautiful.xforeground,
            })
        end
    })
end
