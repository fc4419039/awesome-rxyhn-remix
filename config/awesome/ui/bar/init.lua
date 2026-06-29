-- Standard awesome library
local awful = require("awful")
local gears = require("gears")

-- Widget library
local wibox = require("wibox")

-- Theme handling library
local beautiful = require("beautiful")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

-- Rubato
local rubato = require("module.rubato")

-- Helpers
local helpers = require("helpers")

-- Función de seguridad para evitar crasheos por funciones globales no definidas
local function safe_run(func_name, ...)
    if _G[func_name] then _G[func_name](...) end
end

-- Helpers
-------------

local wrap_widget = function(widget)
    return {
        widget,
        margins = dpi(6),
        widget = wibox.container.margin
    }
end

-- Wibar
-----------

screen.connect_signal("request::desktop_decoration", function(s)

    -- dpi redondeado a entero (evita artifacts por posiciones fraccionales)
    local dpi = function(v) return math.floor(xresources.apply_dpi(v) + 0.5) end

    -- Launcher
    -------------

    local awesome_icon = wibox.widget {
        {
            widget = wibox.widget.imagebox,
            image = beautiful.awesome_logo,
            resize = true
        },
        margins = dpi(4),
        widget = wibox.container.margin
    }

    helpers.add_hover_cursor(awesome_icon, "hand2")

    -- Battery
    -------------

    local charge_icon = wibox.widget{
        bg = beautiful.xcolor8,
        widget = wibox.container.background,
        visible = false
    }

    local batt = wibox.widget{
        charge_icon,
        colors = {beautiful.xcolor2},
        bg = beautiful.xcolor8 .. "88",
        value = 50,
        min_value = 0,
        max_value = 100,
        thickness = dpi(4),
        paddings = dpi(2),
        start_angle = math.pi * 3 / 2,
        widget = wibox.container.arcchart
    }

    local function lerp_color(a, b, t)
        local function ch(h, i) return tonumber(h:sub(i, i+1), 16) end
        local r = math.floor(ch(a, 2) + (ch(b, 2) - ch(a, 2)) * t)
        local g = math.floor(ch(a, 4) + (ch(b, 4) - ch(a, 4)) * t)
        local bl = math.floor(ch(a, 6) + (ch(b, 6) - ch(a, 6)) * t)
        return string.format("#%02x%02x%02x", r, g, bl)
    end

    awesome.connect_signal("signal::battery", function(value)
        local c2 = beautiful.xcolor2
        local c3 = beautiful.xcolor3
        local c1 = beautiful.xcolor1
        local fill_color

        if value > 30 then
            local t = (value - 30) / 70
            fill_color = lerp_color(c3, c2, t)
        else
            local t = value / 30
            fill_color = lerp_color(c1, c3, t)
        end

        batt.colors = {fill_color}
        batt.value = value
    end)

    awesome.connect_signal("signal::charger", function(state)
        if state then
            charge_icon.visible = true
        else
            charge_icon.visible = false
        end
    end)

    -- Time
    ----------

    local hour = wibox.widget{
        font = beautiful.font_name .. "bold 14",
        format = "%I",
        align = "center",
        valign = "center",
        widget = wibox.widget.textclock
    }

    local min = wibox.widget{
        font = beautiful.font_name .. "bold 14",
        format = "%M",
        align = "center",
        valign = "center",
        widget = wibox.widget.textclock
    }

    local clock = wibox.widget{
        {
            {
                hour,
                min,
                spacing = dpi(5),
                layout = wibox.layout.fixed.vertical
            },
            top = dpi(5),
            bottom = dpi(5),
            widget = wibox.container.margin
        },
        bg = beautiful.lighter_bg,
        shape = helpers.rrect(beautiful.bar_radius),
        widget = wibox.container.background
    }

    -- Stats
    -----------

    local stats = wibox.widget{
        {
            wrap_widget(batt),
            clock,
            spacing = dpi(5),
            layout = wibox.layout.fixed.vertical
        },
        bg = beautiful.xcolor0,
        shape = helpers.rrect(beautiful.bar_radius),
        widget = wibox.container.background
    }

    -- Crear dashboard y tooltip por pantalla (antes de los botones que los referencian)
    require("ui.dashboard").create(s)
    require("ui.tooltip").create(s)

    stats:connect_signal("mouse::enter", function()
        stats.bg = beautiful.xcolor8
        if s.stats_tooltip_show then s.stats_tooltip_show() end
    end)

    stats:connect_signal("mouse::leave", function()
        stats.bg = beautiful.xcolor0
    end)

    -- Notification center
    -------------------------

    local notif_center = wibox({
        type = "dock",
        screen = s,
        height = s.geometry.height - dpi(50),
        width = dpi(300),
        shape = helpers.rrect(beautiful.notif_center_radius),
        ontop = true,
        visible = false
    })
    notif_center.y = dpi(25)

    local slide = rubato.timed{
        pos = s.geometry.x + dpi(-300),
        rate = 60,
        intro = 0.3,
        duration = 0.8,
        easing = rubato.quadratic,
        awestore_compat = true,
        subscribed = function(pos) notif_center.x = pos end
    }

    local notif_center_status = false

    slide.ended:subscribe(function()
        if notif_center_status then
            notif_center.visible = false
        end
    end)

    local notif_center_show = function()
        notif_center.visible = true
        slide:set(s.geometry.x + dpi(10) + dpi(50) + dpi(10))
        notif_center_status = false
    end

    local notif_center_hide = function()
        slide:set(s.geometry.x + dpi(-375))
        notif_center_status = true
    end

    local notif_center_toggle = function()
        if notif_center.visible then
            notif_center_hide()
        else
            notif_center_show()
        end
    end

    s.notif_center = require('ui.notifs.notif-center')(s)
    s.notif_center_wibox = notif_center

    notif_center:setup {
        s.notif_center,
        margins = dpi(15),
        widget = wibox.container.margin
    }

    local notif_center_button = wibox.widget{
        markup = helpers.colorize_text("", beautiful.xcolor4),
        font = beautiful.font_name .. "18",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }

    notif_center_button:connect_signal("mouse::enter", function()
        notif_center_button.markup = helpers.colorize_text(notif_center_button.text, beautiful.xcolor4 .. 55)
    end)

    notif_center_button:connect_signal("mouse::leave", function()
        notif_center_button.markup = helpers.colorize_text(notif_center_button.text, beautiful.xcolor4)
    end)

    notif_center_button:buttons(gears.table.join(
        awful.button({}, 1, function()
            notif_center_toggle()
        end)
    ))
    helpers.add_hover_cursor(notif_center_button, "hand2")

    -- Setup wibar
    -----------------

    s.mypromptbox = awful.widget.prompt()

    local layoutbox_buttons = gears.table.join(
        awful.button({}, 1, function() awful.layout.inc(1) end),
        awful.button({}, 3, function() awful.layout.inc(-1) end),
        awful.button({}, 4, function() awful.layout.inc(-1) end),
        awful.button({}, 5, function() awful.layout.inc(1) end)
    )

    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(layoutbox_buttons)

    local layoutbox = wibox.widget{
        s.mylayoutbox,
        margins = {bottom = dpi(7), left = dpi(8), right = dpi(8)},
        widget = wibox.container.margin
    }

    helpers.add_hover_cursor(layoutbox, "hand2")

    s.mywibar = awful.wibar({
        type = "dock",
        position = "left",
        screen = s,
        height = s.geometry.height - dpi(50),
        width = dpi(50),
        shape = helpers.rrect(beautiful.border_radius),
        bg = beautiful.darker_bg,
        ontop = true,
        visible = true,
    })

    s.mywibar.x = s.geometry.x + dpi(10)

    awesome_icon:buttons(gears.table.join(
        awful.button({}, 1, function()
            if s.dashboard_toggle then s.dashboard_toggle() end
        end)
    ))

    -- Ajusta padding del workarea según visibilidad de la barra
    -- bar.x = dpi(10), strut.width = dpi(50) → workarea.left = padding + strut
    local function wibar_update_padding(visible)
        local p = { right = dpi(5), top = dpi(15), bottom = dpi(15) }
        p.left = visible and (dpi(10) + dpi(10)) or 0
        s.padding = p
    end

    -- Toggle wibar con Ctrl+F
    s.wibar_visible = true
    _G["wibar_toggle"] = function()
        local fs = awful.screen.focused()
        if fs and fs.mywibar then
            fs.wibar_visible = not fs.wibar_visible
            fs.mywibar.visible = fs.wibar_visible
        end
    end

    local function hide_for_client(c)
        if c and c.valid and c.screen == s and s.mywibar then
            if c.fullscreen or c.maximized then
                s.mywibar.visible = false
                s.wibar_visible = false
                wibar_update_padding(false)
            else
                s.mywibar.visible = true
                s.wibar_visible = true
                wibar_update_padding(true)
            end
        end
    end

    client.connect_signal("property::fullscreen", hide_for_client)
    client.connect_signal("property::maximized", hide_for_client)

    -- Padding inicial (barra visible)
    wibar_update_padding(true)

    s.mytaglist = require("ui.widgets.pacman_taglist")(s)

    local taglist = wibox.widget{
        s.mytaglist,
        shape = beautiful.taglist_shape_focus,
        bg = beautiful.xcolor0,
        widget = wibox.container.background
    }

    -- Tasklist (client icons)
    local tasklist_buttons = gears.table.join(
        awful.button({}, 1, function(c)
            c:activate{context = "tasklist", action = "toggle_minimization"}
        end),
        awful.button({}, 2, function(c)
            c:activate{context = "tasklist", action = "toggle_minimization"}
        end),
        awful.button({}, 3, function()
            awful.menu.client_list{theme = {width = dpi(250)}}
        end),
        awful.button({}, 4, function()
            awful.client.focus.byidx(1)
        end),
        awful.button({}, 5, function()
            awful.client.focus.byidx(-1)
        end)
    )

    s.mytasklist = awful.widget.tasklist {
        screen = s,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
        layout = {
            spacing = dpi(4),
            layout = wibox.layout.fixed.vertical
        },
        widget_template = {
            {
                {
                    id = 'icon_role',
                    widget = wibox.widget.imagebox,
                    resize = true,
                },
                margins = dpi(5),
                widget = wibox.container.margin,
            },
            id = 'background_role',
            widget = wibox.container.background,
            create_callback = function(self, c, index, objects)
                self:connect_signal('mouse::enter', function()
                    if c.valid then
                        local title = c.name or "Unknown"
                        local class = c.class or ""
                        if self._tooltip then
                            self._tooltip.text = title .. "\n" .. class
                        else
                            self._tooltip = awful.tooltip({
                                objects = { self },
                                text = title .. "\n" .. class,
                            })
                        end
                    end
                end)
            end,
        },
    }

    s.mywibar:setup {
        {
            layout = wibox.layout.align.vertical,
            expand = "none",
            {
                awesome_icon,
                taglist,
                spacing = dpi(10),
                layout = wibox.layout.fixed.vertical
            },
            nil,
            {
                stats,
                notif_center_button,
                layoutbox,
                spacing = dpi(8),
                layout = wibox.layout.fixed.vertical
            }
        },
        margins = dpi(8),
        widget = wibox.container.margin
    }
end)
