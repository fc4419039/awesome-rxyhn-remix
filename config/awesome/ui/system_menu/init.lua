local awful = require("awful")

local create_v1 = require("ui.system_menu.v1")
local create_v2 = require("ui.system_menu.v2")
local create_v3 = require("ui.system_menu.v3")

local function create_system_menu(s)
    local m1 = create_v1(s)
    local m2 = create_v2(s)
    local m3 = create_v3(s)

    local menus = {m1, m2, m3}
    m1.visible = false
    m2.visible = false
    m3.visible = false

    local current_idx = 1

    s.system_menu_toggle = function()
        menus[current_idx]._hide()
        current_idx = current_idx % 3 + 1
        menus[current_idx]._show()
    end

    return m1
end

_G.system_menu_toggle = function()
    local s = awful.screen.focused()
    if s and s.system_menu_toggle then
        s.system_menu_toggle()
    end
end

return create_system_menu
