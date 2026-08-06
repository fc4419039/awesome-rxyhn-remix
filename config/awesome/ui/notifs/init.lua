local naughty = require("naughty")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local dpi = beautiful.xresources.apply_dpi
local helpers = require("helpers")
local ruled = require("ruled")

local menubar = require("menubar")
local button_container = require('ui.widgets.button')
local i18n = require("i18n")

naughty.connect_signal("request::icon", function(n, context, hints)
    if context ~= "app_icon" then return end

    local path = menubar.utils.lookup_icon(hints.app_icon) or
                     menubar.utils.lookup_icon(hints.app_icon:lower())

    if path then n.icon = path end

end)

require("ui.notifs.popup")

naughty.config.defaults.ontop = true
naughty.config.defaults.screen = awful.screen.focused()
naughty.config.defaults.timeout = 3
naughty.config.defaults.title = i18n.tr("dash.notification")
naughty.config.defaults.position = "top_right"

-- Timeouts
naughty.config.presets.low.timeout = 3
naughty.config.presets.critical.timeout = 0

naughty.config.presets.normal = {
    font = beautiful.font_name .. "medium 10",
    fg = beautiful.fg_normal,
    bg = beautiful.bg_normal
}

naughty.config.presets.low = {
    font = beautiful.font_name .. "medium 10",
    fg = beautiful.fg_normal,
    bg = beautiful.bg_normal
}

naughty.config.presets.critical = {
    font = beautiful.font_name .. "medium 10",
    fg = beautiful.xcolor1,
    bg = beautiful.bg_normal,
    timeout = 0
}

naughty.config.presets.ok = naughty.config.presets.normal
naughty.config.presets.info = naughty.config.presets.normal
naughty.config.presets.warn = naughty.config.presets.critical

ruled.notification.connect_signal("request::rules", function()
    -- All notifications will match this rule.
    ruled.notification.append_rule {
        rule = {},
        properties = {screen = awful.screen.preferred, implicit_timeout = 6}
    }

    -- Firefox: ignorar notificaciones de baja urgencia (hover en videos, etc.)
    ruled.notification.append_rule {
        rule_any = {
            app_name = {"Firefox", "firefox"},
            urgency = {"low"},
        },
        properties = {ignored = true}
    }
end)

-- Reproducir sonido al recibir notificación (solo si no está en modo No Molestar)
naughty.connect_signal("request::display", function(n)

    if not _G.dont_disturb then
        local sound_file
        if n.urgency == "critical" then
            sound_file = "/usr/share/sounds/freedesktop/stereo/dialog-warning.oga"
        else
            sound_file = "/usr/share/sounds/freedesktop/stereo/message.oga"
        end
        awful.spawn("pw-play --target=notifications " .. sound_file, false)
    end

    local appicon = beautiful.notification_icon and gears.color.recolor_image(beautiful.notification_icon, beautiful.xcolor4)
    local time = os.date("%H:%M")

    local action_widget = {
        {
            {
                id = "text_role",
                align = "center",
                valign = "center",
                font = beautiful.font_name .. "medium 10",
                widget = wibox.widget.textbox
            },
            left = dpi(6),
            right = dpi(6),
            widget = wibox.container.margin
        },
        bg = beautiful.xcolor0,
        forced_height = dpi(25),
        forced_width = dpi(20),
        shape = gears.shape.rounded_rect,
        widget = wibox.container.background
    }

    local actions = wibox.widget {
        notification = n,
        base_layout = wibox.widget {
            spacing = dpi(8),
            layout = wibox.layout.flex.horizontal
        },
        widget_template = {
			{
				{
					{
						{
							id     = 'text_role',
							font   = beautiful.font_name .. 'medium 10',
							widget = wibox.widget.textbox
						},
						widget = wibox.container.place
					},
					widget = button_container
				},
				bg                 = beautiful.lighter_bg,
				shape              = gears.shape.rounded_rect,
				forced_height      = dpi(30),
				widget             = wibox.container.background
			},
			margins = 4,
			widget  = wibox.container.margin
		},
        style = {underline_normal = false, underline_selected = true},
        widget = naughty.list.actions
    }

    helpers.add_hover_cursor(actions, "hand2")

    naughty.layout.box {
        notification = n,
        type = "notification",
        bg = "#00000000",
        widget_template = {
            {
                {
                    {
                        {
                            {
                                {
                                    {
                                        {
                                            image = appicon,
                                            resize = true,
                                            widget = wibox.widget.imagebox
                                        },
                                        strategy = "max",
                                        height = dpi(20),
                                        widget = wibox.container.constraint
                                    },
                                    right = dpi(10),
                                    widget = wibox.container.margin
                                },
                                {
                                    markup = n.app_name,
                                    align = "left",
                                    font = beautiful.font_name .. "Bold 12",
                                    widget = wibox.widget.textbox
                                },
                                {
                                    markup = time,
                                    align = "right",
                                    font = beautiful.font_name .. "medium 10",
                                    widget = wibox.widget.textbox
                                },
                                layout = wibox.layout.align.horizontal
                            },
                            top = dpi(5),
                            left = dpi(20),
                            right = dpi(20),
                            bottom = dpi(5),
                            widget = wibox.container.margin
                        },
                        bg = beautiful.darker_bg,
                        widget = wibox.container.background
                    },
                    {
                        {
                            {
                                helpers.vertical_pad(10),
                                {
                                    {
                                        step_function = wibox.container.scroll
                                            .step_functions
                                            .waiting_nonlinear_back_and_forth,
                                        speed = 50,
                                        {
                                            markup = n.title,
                                            font = beautiful.font_name .. "Bold 12",
                                            align = "left",
                                            widget = wibox.widget.textbox
                                        },
                                        forced_width = dpi(250),
                                        widget = wibox.container.scroll
                                            .horizontal
                                    },
                                    {
                                        step_function = wibox.container.scroll
                                            .step_functions
                                            .waiting_nonlinear_back_and_forth,
                                        speed = 50,
                                        {
                                            markup = n.message,
                                            align = "left",
                                            font = beautiful.font_name .. "medium 10",
                                            widget = wibox.widget.textbox
                                        },
                                        forced_width = dpi(250),
                                        widget = wibox.container.scroll
                                            .horizontal
                                    },
                                    spacing = 0,
                                    layout = wibox.layout.flex.vertical
                                },
                                helpers.vertical_pad(10),
                                layout = wibox.layout.align.vertical
                            },
                            left = dpi(20),
                            right = dpi(20),
                            widget = wibox.container.margin
                        },
                        {
                            {
                                nil,
                                {
                                    {
                                        image = n.icon,
                                        resize = true,
                                        clip_shape = helpers.rrect(beautiful.notification_border_radius),
                                        widget = wibox.widget.imagebox
                                    },
                                    strategy = "max",
                                    height = dpi(50),
                                    widget = wibox.container.constraint
                                },
                                nil,
                                expand = "none",
                                layout = wibox.layout.align.vertical
                            },
                            top = dpi(10),
                            left = dpi(10),
                            right = dpi(10),
                            bottom = dpi(5),
                            widget = wibox.container.margin
                        },
                        layout = wibox.layout.fixed.horizontal
                    },
                    {
                        {actions, layout = wibox.layout.fixed.vertical},
                        margins = dpi(10),
                        visible = n.actions and #n.actions > 0,
                        widget = wibox.container.margin
                    },
                    layout = wibox.layout.fixed.vertical
                },
                top = dpi(5),
                bottom = dpi(5),
                widget = wibox.container.margin
            },
            bg = "#0d0d1ab3",
            shape = helpers.rrect(beautiful.border_radius),
            widget = wibox.container.background
        }
    }

	-- Destroy popups if dont_disturb mode is on
	-- Or if any screen's notif_center is visible
	local function any_notif_center_visible()
		for s in screen do
			if s.notif_center_wibox and s.notif_center_wibox.visible then
				return true
			end
		end
		return false
	end
	if _G.dont_disturb or any_notif_center_visible() then
		naughty.destroy_all_notifications(nil, 1)
	end


end)
