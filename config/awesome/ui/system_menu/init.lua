local awful = require("awful")
local gears = require("gears")
local i18n = require("i18n")

-- Lista de opciones con iconos (nombre traducido, id estable para la acción)
local options = {
    { id = "Power Menu", name = i18n.tr("sm.power"), icon = "⏻", color = "#ef4444" },
    { id = "Network", name = i18n.tr("sm.network"), icon = "", color = "#06b6d4" },
    { id = "Bluetooth", name = i18n.tr("sm.bluetooth"), icon = "", color = "#8b5cf6" },
    { id = "Blur", name = i18n.tr("sm.blur"), icon = "", color = "#3b82f6" },
    { id = "Apps", name = i18n.tr("sm.apps"), icon = "", color = "#10b981" },
    { id = "OpenCode", name = i18n.tr("sm.opencode"), icon = "", color = "#8b5cf6" },
    { id = "Transparency", name = i18n.tr("sm.transparency"), icon = "", color = "#10b981" },
    { id = "Wallpaper", name = i18n.tr("sm.wallpaper"), icon = "", color = "#06b6d4" },
    { id = "SDDM", name = i18n.tr("sm.sddm"), icon = "", color = "#f59e0b" },
    { id = "Volume", name = i18n.tr("sm.volume"), icon = "", color = "#3b82f6" },
    { id = "Clean Orphans", name = i18n.tr("sm.clean"), icon = "", color = "#10b981" },
    { id = "Color Temp", name = i18n.tr("sm.color_temp"), icon = "", color = "#f59e0b" },
    { id = "Widgets", name = i18n.tr("sm.widgets"), icon = "", color = "#8b5cf6" },
    { id = "Timezone", name = i18n.tr("sm.timezone"), icon = "", color = "#06b6d4" },
    { id = "Keyboard", name = i18n.tr("sm.keyboard"), icon = "", color = "#3b82f6" },
    { id = "Language", name = i18n.tr("sm.language"), icon = "", color = "#10b981" },
    { id = "Accent", name = i18n.tr("sm.accent"), icon = "", color = "#8b5cf6" },
    { id = "Titlebar", name = i18n.tr("sm.titlebar"), icon = "", color = "#06b6d4" },
    { id = "Borders", name = i18n.tr("sm.borders"), icon = "", color = "#3b82f6" },
    { id = "Night Mode", name = i18n.tr("sm.night"), icon = "", color = "#f59e0b" },
    { id = "Resources", name = i18n.tr("sm.resources"), icon = "", color = "#06b6d4" },
    { id = "Calculator", name = i18n.tr("sm.calculator"), icon = "", color = "#3b82f6" }
}

-- Mapas: nombre traducido -> id estable -> acción
local by_label = {}
for _, o in ipairs(options) do
    by_label[o.name] = o.id
end

-- Mapa de acciones
local actions = {
    ["Wallpaper"]    = function() require("ui.system_menu.wallpaper_picker").toggle() end,
    ["Resources"]    = function() require("ui.widgets.resources").toggle() end,
    ["Calculator"]   = function() require("ui.widgets.calculator").toggle() end,
    ["Color Temp"]   = function() require("ui.system_menu.color_temp").create(awful.screen.focused()):_toggle() end,
    ["Widgets"]      = function() for s in screen do if s.datetime_widget then s.datetime_widget.visible = not s.datetime_widget.visible end end end,
    ["Titlebar"]     = function() toggle_window_titlebars() end,
    ["Borders"]      = function() toggle_window_borders() end,
    ["SDDM"]         = function() require("ui.system_menu.sddm_picker").toggle() end,
    ["Apps"]         = function() awful.spawn(launcher) end,
    ["OpenCode"]     = function() awful.spawn.with_shell(terminal .. " -e opencode") end
}

local function toggle_system_menu()
    local theme = os.getenv("HOME") .. "/.config/awesome/theme/system-menu.rasi"
    local opt_str = ""
    for _, o in ipairs(options) do
        -- Usamos una representación segura para el icono y el nombre
        opt_str = opt_str .. "<span color='" .. o.color .. "'>" .. o.icon .. "</span> " .. o.name .. "\\n"
    end
    
    local cmd = "echo -e \"" .. opt_str .. "\" | rofi -dmenu -markup-rows -theme " .. theme .. " -i"
    
    awful.spawn.easy_async_with_shell(cmd, function(stdout)
        local raw_choice = stdout:gsub("\\n", ""):gsub("\n", "")
        if raw_choice == "" then return end
        
        -- Extraer el nombre (limpiando el span de color y el icono)
        local label = raw_choice:gsub("<span[^>]*>[^<]*</span>%s+", "")
        local choice = by_label[label]

        
        if actions[choice] then
            actions[choice]()
        else
            local scripts = {
                ["Network"]      = "/scripts/network.sh",
                ["Bluetooth"]    = "/scripts/bluetooth.sh",
                ["Blur"]         = "/scripts/toggle-blur.sh",
                ["Transparency"] = "/scripts/toggle-transparency.sh",
                ["Night Mode"]   = "redshift -O 3500",
                ["Volume"]       = "/scripts/volumen",
                ["Power Menu"]   = "/scripts/powermenu.sh",
                ["Clean Orphans"]= "/scripts/clean-orphans.sh",
                ["Timezone"]     = "/scripts/change-timezone.sh",
                ["Keyboard"]     = "/scripts/change-keyboard.sh",
                ["Language"]     = "/scripts/change-locale.sh",
                ["Accent"]       = "/scripts/cycle-accent.sh"
            }
            if scripts[choice] then
                if scripts[choice]:find("/") == 1 then
                    awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome" .. scripts[choice])
                else
                    awful.spawn.with_shell(scripts[choice])
                end
            end
        end
    end)
end

_G.system_menu_toggle = toggle_system_menu

return function(s)
    s.system_menu_toggle = toggle_system_menu
end
