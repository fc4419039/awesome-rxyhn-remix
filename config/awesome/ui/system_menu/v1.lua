local beautiful = require("beautiful")
local create_menu = require("ui.system_menu.menu_template")

return function(s)
    return create_menu(s, {
        border_color = beautiful.lighter_bg,
        button_bg = beautiful.dashboard_box_bg,
        hover_bg = beautiful.lighter_bg,
        icon_font = beautiful.font_name .. "14",
        accent_opacity = "30",
        show_accent = true,
    })
end
