local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")

local misc = {}

function misc.resize_gaps(amt)
    local t = awful.screen.focused().selected_tag
    t.gap = t.gap + tonumber(amt)
    awful.layout.arrange(awful.screen.focused())
end

function misc.resize_padding(amt)
    local s = awful.screen.focused()
    local l = s.padding.left
    local r = s.padding.right
    local t = s.padding.top
    local b = s.padding.bottom
    s.padding = {
        left = l + amt,
        right = r + amt,
        top = t + amt,
        bottom = b + amt
    }
    awful.layout.arrange(awful.screen.focused())
end

function misc.find(rule)
    local function matcher(c) return awful.rules.match(c, rule) end
    local clients = client.get()
    local findex = gears.table.hasitem(clients, client.focus) or 1
    local start = gears.math.cycle(#clients, findex + 1)

    local matches = {}
    for c in awful.client.iterate(matcher, start) do
        matches[#matches + 1] = c
    end

    return matches
end

function misc.round(number, decimals)
    local power = 10 ^ decimals
    return math.floor(number * power) / power
end

-- Estado de visibilidad de los widgets de escritorio (Sistema, Sysmon, Música).
-- Cada widget persiste su estado por separado en ~/.cache/awesome/, así al
-- ocultar un widget desde su propio menú solo ese queda oculto (y se mantiene
-- oculto tras recargar). En system_menu "Widgets" se ocultan/muestran los 3.
local WIDGET_KEYS = {
    datetime_widget = ".desktop-widget-hidden-datetime",
    desktop_sysmon  = ".desktop-widget-hidden-sysmon",
    desktop_music   = ".desktop-widget-hidden-music",
}

local function state_file(key)
    return os.getenv("HOME") .. "/.cache/awesome/" .. WIDGET_KEYS[key]
end

-- Recorre todas las pantallas y recoge los widgets de escritorio de una clave.
local function widgets_by_key(key)
    local list = {}
    for s in screen do
        if s[key] then list[#list + 1] = s[key] end
    end
    return list
end

-- true si el widget de esa clave está en modo oculto (persistido).
function misc.desktop_widget_hidden(key)
    local f = io.open(state_file(key), "r")
    if f then f:close(); return true end
    return false
end

-- Oculta SOLO el widget indicado y persiste su estado individual.
function misc.hide_desktop_widget(key)
    for _, w in ipairs(widgets_by_key(key)) do
        w.visible = false
    end
    local f = io.open(state_file(key), "w")
    if f then f:close() end
end

-- Muestra SOLO el widget indicado y borra su estado individual.
function misc.show_desktop_widget(key)
    for _, w in ipairs(widgets_by_key(key)) do
        w.visible = true
    end
    os.remove(state_file(key))
end

-- true si hay al menos un widget de escritorio en modo oculto (persistido).
function misc.desktop_widgets_hidden()
    for key in pairs(WIDGET_KEYS) do
        if misc.desktop_widget_hidden(key) then return true end
    end
    return false
end

-- Oculta los 3 widgets y persiste el estado de cada uno.
function misc.hide_all_desktop_widgets()
    for key in pairs(WIDGET_KEYS) do
        misc.hide_desktop_widget(key)
    end
end

-- Muestra los 3 widgets y borra el estado de cada uno.
function misc.show_all_desktop_widgets()
    for key in pairs(WIDGET_KEYS) do
        misc.show_desktop_widget(key)
    end
end

-- Desde el system_menu: si no hay ninguno oculto, oculta los 3; si hay uno
-- o más ocultos, muestra todos.
function misc.toggle_all_desktop_widgets()
    if misc.desktop_widgets_hidden() then
        misc.show_all_desktop_widgets()
    else
        misc.hide_all_desktop_widgets()
    end
end

return misc