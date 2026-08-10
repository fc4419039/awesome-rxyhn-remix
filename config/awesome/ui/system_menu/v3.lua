local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local create_menu = require("ui.system_menu.menu_template")

return function(s)
    return create_menu(s, {
        menu_w = dpi(280),
        bg = "#0a1419b3", -- Color de fondo igual a Rofi
        border_color = "#06b6d433",
        button_bg = "#162026cc",
        hover_bg = "#16202680",
        icon_font = beautiful.font_name .. "15",
        accent_opacity = "60",
        show_accent = true,
        btn_height = dpi(38), -- Más delgado
        row_spacing = dpi(6),
        col_spacing = dpi(6),
        margin = dpi(12),
    })
end
