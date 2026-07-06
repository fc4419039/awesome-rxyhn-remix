local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local create_menu = require("ui.system_menu.menu_template")

return function(s)
    return create_menu(s, {
        border_color = beautiful.darker_bg,
        button_bg = beautiful.darker_bg,
        hover_bg = beautiful.lighter_bg,
        icon_font = beautiful.font_name .. "12",
        label_font = beautiful.font_name .. "9",
        show_accent = false,
        btn_height = dpi(26),
        width = dpi(210),
    })
end
