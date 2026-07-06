local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local create_menu = require("ui.system_menu.menu_template")

return function(s)
    return create_menu(s, {
        border_color = beautiful.xcolor5 .. "80",
        button_bg = beautiful.dashboard_box_bg,
        hover_bg = beautiful.xcolor5 .. "30",
        icon_font = beautiful.font_name .. "15",
        accent_opacity = "60",
        show_accent = true,
        btn_height = dpi(24),
    })
end
