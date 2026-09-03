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
-- Se persiste en ~/.cache/awesome/.desktop-widgets-hidden para que queden
-- ocultos también tras recargar Awesome.
local WIDGETS_STATE = os.getenv("HOME") .. "/.cache/awesome/.desktop-widgets-hidden"

-- Recorre todas las pantallas y recoge los widgets de escritorio existentes.
local function all_desktop_widgets()
    local list = {}
    for s in screen do
        if s.datetime_widget then list[#list + 1] = s.datetime_widget end
        if s.desktop_sysmon then list[#list + 1] = s.desktop_sysmon end
        if s.desktop_music then list[#list + 1] = s.desktop_music end
    end
    return list
end

-- true si algún widget de escritorio está oculto en alguna pantalla.
function misc.desktop_widgets_hidden()
    for _, w in ipairs(all_desktop_widgets()) do
        if not w.visible then return true end
    end
    return false
end

-- Oculta todos los widgets de escritorio y persiste el estado.
function misc.hide_all_desktop_widgets()
    for _, w in ipairs(all_desktop_widgets()) do
        w.visible = false
    end
    local f = io.open(WIDGETS_STATE, "w")
    if f then f:close() end
end

-- Muestra todos los widgets de escritorio y borra el estado persistido.
function misc.show_all_desktop_widgets()
    for _, w in ipairs(all_desktop_widgets()) do
        w.visible = true
    end
    os.remove(WIDGETS_STATE)
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