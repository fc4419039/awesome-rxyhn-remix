-- Standard awesome library
local awful = require("awful")
local gears = require("gears")
local gfs = gears.filesystem

-- Compatibilidad con awesome estable 4.3: append_*_keybindings y append_*_mousebindings
-- solo existen en awesome-git. En 4.3 el getter de root.keys()/root.buttons() devuelve
-- una vista con metatable que el setter rechaza, así que se acumula en buffers locales
-- y se registra con gears.table.join() (la única convención que acepta el setter 4.3).
if not awful.keyboard then
    awful.keyboard = {}
end
if not awful.mouse then
    awful.mouse = {}
end
if not awful.keyboard.append_global_keybindings then
    local global_keys = {}
    local client_keys = {}
    local global_buttons = {}
    local client_buttons = {}
    local tjoin = gears.table.join

    function awful.keyboard.append_global_keybindings(bindings)
        for _, k in ipairs(bindings) do
            table.insert(global_keys, k)
        end
        root.keys(tjoin(table.unpack(global_keys)))
    end

    function awful.keyboard.append_client_keybindings(bindings)
        for _, k in ipairs(bindings) do
            table.insert(client_keys, k)
        end
        client.connect_signal("manage", function(c)
            c.keys = tjoin(table.unpack(client_keys))
        end)
    end

    function awful.mouse.append_global_mousebindings(bindings)
        for _, b in ipairs(bindings) do
            table.insert(global_buttons, b)
        end
        root.buttons(tjoin(table.unpack(global_buttons)))
    end

    function awful.mouse.append_client_mousebindings(bindings)
        for _, b in ipairs(bindings) do
            table.insert(client_buttons, b)
        end
        client.connect_signal("manage", function(c)
            c.buttons = tjoin(table.unpack(client_buttons))
        end)
    end

    -- En 4.3 las señales request::default_keybindings / request::default_mousebindings
    -- no existen: se ejecuta el handler al registrarse para poblar los buffers.
    local orig_connect = client.connect_signal
    function client.connect_signal(sig, fn)
        if sig == "request::default_keybindings" or sig == "request::default_mousebindings" then
            fn()
        else
            return orig_connect(sig, fn)
        end
    end
end

-- naughty.connect_signal (request::display / request::icon / request::display_error)
-- solo existe en awesome-git; en 4.3 naughty no es un objeto con señales.
-- No-op seguro: las notificaciones se muestran igual, solo se pierden los extras
-- (sonido al recibir, icono por app_icon, poblar dashboard/notif-center).
local naughty = require("naughty")
if not naughty.connect_signal then
    function naughty.connect_signal() end
end

-- Theme handling library
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

-- Helpers
local helpers = require("helpers")

-- Bling Module
local bling = require("module.bling")

-- Layout Machi
local machi = require("module.layout-machi")
beautiful.layout_machi = machi.get_icon()

-- This is to slave windows' positions in floating layout
require("module.savefloats")

-- Better mouse resizing on tiled
require("module.better-resize")


-- Desktop
-------------

-- Custom Layouts
local mstab = bling.layout.mstab
local centered = bling.layout.centered
local horizontal = bling.layout.horizontal
local equal = bling.layout.equalarea
local deck = bling.layout.deck

machi.editor.nested_layouts = {
    ["0"] = deck,
    ["1"] = awful.layout.suit.spiral,
    ["2"] = awful.layout.suit.fair,
    ["3"] = awful.layout.suit.fair.horizontal
}

-- Set the layouts
tag.connect_signal("request::default_layouts", function()
    awful.layout.append_default_layouts({
        awful.layout.suit.tile, awful.layout.suit.floating, centered, mstab,
        horizontal, machi.default_layout, equal, deck
    })
end)

-- Screen Padding and Tags
screen.connect_signal("request::desktop_decoration", function(s)
    -- La barra ajusta left/right padding dinámicamente en ui/bar/init.lua
    -- Este padding se aplica solo como valor inicial antes que la barra lo sobreescriba
    if not s.padding then
        s.padding = {left = dpi(40), right = dpi(15), top = dpi(5), bottom = dpi(5)}
    end
    -- Each screen has its own tag table (solo si no tiene tags aún)
    if #s.tags == 0 then
        awful.tag({"1", "2", "3", "4", "5"}, s, awful.layout.layouts[1])
    end

    -- Restaurar tag guardado inmediatamente tras crearlos (antes del primer render)
    -- Solo en la pantalla principal para evitar conflictos multi-monitor
    if s == screen.primary then
        local reload = require("ui.reload")
        local f = io.open(reload.focus_file, "r")
        if f then
            local data = f:read("*a")
            f:close()
            local win_str, tag_str = data:match("^([^|]+)|(%d+)$")
            if win_str and tag_str then
                local tag_idx = tonumber(tag_str)
                if tag_idx then
                    local tag = nil
                    for _, t in ipairs(s.tags) do
                        if t.name == tostring(tag_idx) then
                            tag = t
                            break
                        end
                    end
                    if tag then
                        tag:view_only()
                    end
                end
            end
        end
    end
end)

-- Wallpapers (lo establece ~/.config/cambiar_fondo.sh)
-- awful.screen.connect_for_each_screen(function(s)
--     gears.wallpaper.set(beautiful.xcolor8)
-- end)

-- Set Tile Wallpaper
-- bling.module.tiled_wallpaper("", s, {
--     fg = beautiful.lighter_bg,
--     bg = beautiful.xbackground,
--     offset_y = 6,
--     offset_x = 18,
--     font = "Iosevka",
--     font_size = 17,
--     padding = 70,
--     zickzack = true
-- })


-- Stuff
-----------

require("configuration.keys")
require("configuration.ruled")
require("configuration.extras")
require("configuration.menu")
