local naughty = require("naughty")
naughty.notify({text = "DEBUG: system_menu module loaded", timeout = 3})

local function debug_create(s)
    naughty.notify({text = "DEBUG: create_system_menu called for screen " .. tostring(s), timeout = 3})

    -- Test if menu widget works at all
    local menu = wibox({
        type = "dialog",
        screen = s,
        height = dpi(200),
        width = dpi(200),
        ontop = true,
        visible = false,
    })

    menu:setup {
        {
            {
                nil,
                {
                    {
                        markup = "<b>TEST MENU</b>",
                        align = "center",
                        widget = wibox.widget.textbox
                    },
                    layout = wibox.layout.fixed.vertical
                },
                expand = "none",
                layout = wibox.layout.align.horizontal
            },
            margins = dpi(10),
            widget = wibox.container.margin
        },
        bg = "#ff000080",
        shape = helpers.rrect(beautiful.border_radius),
        widget = wibox.container.background
    }

    menu.y = dpi(50)
    menu.x = s.geometry.width + dpi(50)

    s.system_menu_toggle = function()
        naughty.notify({text = "DEBUG: toggle called, visible=" .. tostring(menu.visible), timeout = 2})
        if menu.visible then
            menu.visible = false
            menu.x = s.geometry.width + dpi(50)
        else
            menu.x = s.geometry.width - dpi(200) - dpi(10)
            menu.visible = true
        end
    end

    return menu
end

return debug_create
