-- Standard awesome library
local gears = require("gears")
local awful = require("awful")

-- Theme handling library
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

-- Widget library
local wibox = require("wibox")

-- rubato
local rubato = require("module.rubato")

-- Helpers
local helpers = require("helpers")

-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------

local function centered_widget(widget)
    local w = wibox.widget{
        nil,
        {
            nil,
            widget,
            expand = "none",
            layout = wibox.layout.align.vertical
        },
        expand = "none",
        layout = wibox.layout.align.horizontal
    }
    return w
end

local function create_boxed_widget(widget_to_be_boxed, width, height, bg_color)
    local box_container = wibox.container.background()
    box_container.bg = bg_color
    box_container.forced_height = height
    box_container.forced_width = width
    box_container.shape = helpers.rrect(dpi(5))

    local boxed_widget = wibox.widget {
        {
            {
                widget_to_be_boxed,
                    top = dpi(4),
                    bottom = dpi(4),
                    left = dpi(4),
                    right = dpi(4),
                widget = wibox.container.margin
            },
            widget = box_container,
        },
        margins = dpi(2),
        color = "#00000000",
        widget = wibox.container.margin
    }
    return boxed_widget
end

-- Widget imports
local profile = require("ui.dashboard.profile")
local music   = require("ui.dashboard.music")
local media   = require("ui.dashboard.mediakeys")
local time    = require("ui.dashboard.time")
local date    = require("ui.dashboard.date")
local disk    = require("ui.dashboard.disk")
local weather = require("ui.dashboard.weather")
local stats   = require("ui.dashboard.stats")
local notifs  = require("ui.dashboard.notifs")
local todo    = require("ui.dashboard.todo")

-----------------------------------------------------------------------
-- Factory per-screen
-----------------------------------------------------------------------

local M = {}

function M.create(s)
    local screen_height = s.geometry.height

    local time_boxed    = create_boxed_widget(centered_widget(time), dpi(250), dpi(90), beautiful.transparent)
    local date_boxed    = create_boxed_widget(date, dpi(120), dpi(50), beautiful.dashboard_box_bg)
    local disk_boxed    = create_boxed_widget(disk, dpi(120), dpi(110), beautiful.dashboard_box_bg)
    local weather_boxed = create_boxed_widget(weather, dpi(120), dpi(130), beautiful.dashboard_box_bg)
    local stats_boxed   = create_boxed_widget(stats, dpi(115), dpi(185), beautiful.dashboard_box_bg)
    local todo_boxed    = create_boxed_widget(todo, dpi(120), dpi(120), beautiful.dashboard_box_bg)
    local notifs_boxed  = create_boxed_widget(notifs, dpi(245), dpi(185), beautiful.dashboard_box_bg)

    local dashboard = wibox({
        type = "dialog",
        screen = s,
        height = screen_height - dpi(30),
        width = beautiful.dashboard_width or dpi(300),
        shape = helpers.rrect(beautiful.border_radius),
        bg = beautiful.xbackground,
        ontop = true,
        visible = false
    })
    dashboard.y = dpi(15)

    local slide = rubato.timed{
        pos = s.geometry.x + dpi(-290),
        rate = 60,
        intro = 0.05,
        duration = 0.4,
        easing = rubato.quadratic,
        awestore_compat = true,
        subscribed = function(pos) dashboard.x = pos end
    }

    local dashboard_status = false

    slide.ended:subscribe(function()
        if dashboard_status then
            dashboard.visible = false
        end
    end)

    local function dashboard_show()
        dashboard.visible = true
        slide:set(s.geometry.x + dpi(64))
        dashboard_status = false
    end

    local function dashboard_hide()
        slide:set(s.geometry.x - 375)
        dashboard_status = true
    end

    s.dashboard_toggle = function()
        if dashboard.visible then
            dashboard_hide()
        else
            dashboard_show()
        end
    end

    local dashboard_hide_timer = gears.timer {
        timeout = 2,
        autostart = false,
        single_shot = true,
        callback = function()
            if dashboard.visible then dashboard_hide() end
        end
    }

    dashboard:connect_signal("mouse::enter", function()
        dashboard_hide_timer:stop()
    end)

    dashboard:connect_signal("mouse::leave", function()
        dashboard_hide_timer:again()
    end)

    local content = wibox.widget{
        {
            nil,
            {
                {
                    {
                        {
                            profile,
                            top = dpi(0),
                            bottom = dpi(0),
                            left = dpi(0),
                            right = dpi(0),
                            widget = wibox.container.margin
                        },
                        {
                            todo_boxed,
                            top = dpi(-4),
                            left = dpi(0),
                            right = dpi(0),
                            widget = wibox.container.margin
                        },
                        weather_boxed,
                        spacing = dpi(-2),
                        layout = wibox.layout.fixed.vertical
                    },
                    {
                        {
                            date_boxed,
                            top = dpi(6),
                            widget = wibox.container.margin
                        },
                        disk_boxed,
                        stats_boxed,
                        layout = wibox.layout.fixed.vertical
                    },
                    layout = wibox.layout.fixed.horizontal
                },
                {
                    music,
                    media,
                    layout = wibox.layout.fixed.horizontal
                },
                notifs_boxed,
                layout = wibox.layout.fixed.vertical
            },
            expand = "none",
            layout = wibox.layout.align.horizontal
        },
        margins = dpi(0),
        widget = wibox.container.margin
    }

    dashboard:setup {
        content,
        bg = beautiful.xbackground,
        shape = helpers.rrect(beautiful.dashboard_radius),
        widget = wibox.container.background
    }
end

-- Global fallback: toggle dashboard on the focused screen
_G.dashboard_toggle = function()
    local s = awful.screen.focused()
    if s and s.dashboard_toggle then
        s.dashboard_toggle()
    end
end

return M
