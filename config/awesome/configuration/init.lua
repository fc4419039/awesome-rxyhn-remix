-- Standard awesome library
local awful = require("awful")
local gears = require("gears")
local gfs = gears.filesystem

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
