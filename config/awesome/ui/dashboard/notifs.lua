-- Standard awesome library
local gears = require("gears")
local awful = require("awful")

-- Theme handling library
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

-- Notification library
local naughty = require("naughty")

-- Widget library
local wibox = require("wibox")

-- Helpers
local helpers = require("helpers")

-- Notification Center
------------------------

local notifs_text = wibox.widget{
    font = beautiful.font_name .. "medium 8",
    markup = helpers.colorize_text("Notifications", beautiful.dashboard_box_fg),
    valign = "center",
    widget = wibox.widget.textbox
}

local notifs_clear = wibox.widget {
    markup = "",
    font = beautiful.icon_font_name .. "13",
    align = "center",
    valign = "center",
    widget = wibox.widget.textbox
}

-- Definición de funciones en el entorno global de forma segura
local notifs_container = wibox.widget{
    spacing = dpi(10),
    forced_width = dpi(240),
    layout = wibox.layout.fixed.vertical
}

local notifs_empty = wibox.widget {
    {
        nil,
        {
            nil,
            {
                markup = helpers.colorize_text('You have no notifs!', beautiful.xforeground .. "e6"),
                font = beautiful.font_name .. '8',
                align = 'center',
                valign = 'center',
                widget = wibox.widget.textbox
            },
            expand = "none",
            layout = wibox.layout.align.vertical
        },
        expand = "none",
        layout = wibox.layout.align.horizontal
    },
    forced_height = dpi(110),
    widget = wibox.container.background
}

local remove_notifs_empty = true

_G.reset_notifs_container = function()
    notifs_container:reset()
    notifs_container:insert(1, notifs_empty)
    remove_notifs_empty = true
end

_G.remove_notif = function(box)
    notifs_container:remove_widgets(box)
    if #notifs_container.children == 0 then
        notifs_container:insert(1, notifs_empty)
        remove_notifs_empty = true
    end
end

notifs_clear:buttons(gears.table.join(
    awful.button({}, 1, function() _G.reset_notifs_container() end)
))

local create_notif = function(icon, n)
    local time = os.date("%H:%M")

    local box = wibox.widget {
        {
            {
                {
                    {
                        image = icon,
                        resize = true,
                        clip_shape = helpers.rrect(dpi(2)),
                        halign = "center",
                        valign = "center",
                        widget = wibox.widget.imagebox
                    },
                    strategy = 'exact',
                    height = dpi(40),
                    width = dpi(40),
                    widget = wibox.container.constraint
                },
                {
                    {
                        nil,
                            {
                                {
                                    {
                                        markup = helpers.colorize_text(n.title or "Notification", beautiful.xforeground .. "b3"),
                                        font = beautiful.font_name .. "medium 8",
                                        align = "left",
                                        forced_width = dpi(140),
                                        widget = wibox.widget.textbox
                                    },
                                nil,
                                {
                                    markup = helpers.colorize_text(time, beautiful.xforeground .. "b3"),
                                    align = "right",
                                    valign = "bottom",
                                    font = beautiful.font or "sans 8",
                                    widget = wibox.widget.textbox
                                },
                                expand = "none",
                                layout = wibox.layout.align.horizontal
                            },
                            {
                                markup = helpers.colorize_text(n.message or "", beautiful.dashboard_box_fg),
                                align = "left",
                                font = beautiful.font_name .. "medium 8",
                                forced_width = dpi(165),
                                widget = wibox.widget.textbox
                            },
                            spacing = dpi(2),
                            layout = wibox.layout.fixed.vertical
                        },
                        expand = "none",
                        layout = wibox.layout.align.vertical
                    },
                    left = dpi(12),
                    widget = wibox.container.margin
                },
                layout = wibox.layout.align.horizontal
            },
            margins = dpi(8),
            widget = wibox.container.margin
        },
        bg = beautiful.xcolor0,
        shape = helpers.rrect(dpi(4)),
        forced_height = dpi(64),
        widget = wibox.container.background
    }

    box:buttons(gears.table.join(
        awful.button({}, 1, function() _G.remove_notif(box) end)
    ))

    box:connect_signal("mouse::enter", function() box.bg = beautiful.xcolor8 end)
    box:connect_signal("mouse::leave", function() box.bg = beautiful.xcolor0 end)

    return box
end

notifs_container:buttons(gears.table.join(
    awful.button({}, 4, nil, function()
        if #notifs_container.children <= 1 then return end
        local child = notifs_container.children[#notifs_container.children]
        notifs_container:remove(#notifs_container.children)
        notifs_container:insert(1, child)
    end),
    awful.button({}, 5, nil, function()
        if #notifs_container.children <= 1 then return end
        local child = notifs_container.children[1]
        notifs_container:remove(1)
        notifs_container:insert(#notifs_container.children + 1, child)
    end)
))

notifs_container:insert(1, notifs_empty)

naughty.connect_signal("request::display", function(n)
    if remove_notifs_empty then
        notifs_container:reset()
        remove_notifs_empty = false
    end

    local appicon = n.icon or n.app_icon or gears.color.recolor_image(beautiful.notification_icon or "", beautiful.xcolor4)
    notifs_container:insert(1, create_notif(appicon, n))
end)

local notifs = wibox.widget {
    {
        {
            notifs_text,
            nil,
            notifs_clear,
            expand = "none",
            layout = wibox.layout.align.horizontal
        },
        left = dpi(5),
        right = dpi(5),
        widget = wibox.container.margin
    },
    notifs_container,
    spacing = dpi(10),
    layout = wibox.layout.fixed.vertical
}

return notifs
