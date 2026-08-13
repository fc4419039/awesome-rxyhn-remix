local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local gears = require("gears")
local helpers = require("helpers")
local i18n = require("i18n")
local rubato = require("module.rubato")

local color_temp = {}

local prefs_file = (os.getenv("HOME") or "/tmp") .. "/.config/awesome/.color_temp_prefs"

local function save_temp(monitor, temp)
    local entries = {}
    local f = io.open(prefs_file, "r")
    if f then
        for line in f:lines() do
            local m, t = line:match("([^=]+)=(.+)")
            if m and t and m ~= monitor then
                entries[#entries + 1] = m .. "=" .. t
            end
        end
        f:close()
    end
    entries[#entries + 1] = monitor .. "=" .. temp
    f = io.open(prefs_file, "w")
    if f then
        f:write(table.concat(entries, "\n") .. "\n")
        f:close()
    end
end

local function load_temp(monitor, default)
    local f = io.open(prefs_file, "r")
    if f then
        for line in f:lines() do
            local m, t = line:match("([^=]+)=(.+)")
            if m == monitor then
                f:close()
                return tonumber(t) or default
            end
        end
        f:close()
    end
    return default
end

local function temp_to_gamma(temp)
    local t = temp / 100
    local r, g, b

    if t <= 66 then
        r = 255
    else
        r = t - 60
        r = 329.698727446 * (r ^ -0.1332047592)
        r = math.min(255, math.max(0, r))
    end

    if t <= 66 then
        g = t
        g = 99.4708025861 * math.log(g) - 161.1195681661
        g = math.min(255, math.max(0, g))
    else
        g = t - 60
        g = 288.1221695283 * (g ^ -0.0755148492)
        g = math.min(255, math.max(0, g))
    end

    if t >= 66 then
        b = 255
    elseif t <= 19 then
        b = 0
    else
        b = t - 10
        b = 138.5177312231 * math.log(b) - 305.0447927307
        b = math.min(255, math.max(0, b))
    end

    return r / 255, g / 255, b / 255
end

local function set_monitor_gamma(monitor, r, g, b)
    awful.spawn({
        "xrandr", "--output", monitor, "--gamma",
        string.format("%.4f:%.4f:%.4f", r, g, b)
    })
end

local function get_connected_monitors(callback)
    awful.spawn.easy_async_with_shell("xrandr --query | grep ' connected'", function(stdout)
        local monitors = {}
        for line in stdout:gmatch("[^\r\n]+") do
            local name = line:match("^([%w%-]+) connected")
            if name then
                table.insert(monitors, name)
            end
        end
        callback(monitors)
    end)
end

function color_temp.create(s)
    local monitors = {}
    local monitor_widgets = {}
    local screen_height = s.geometry.height
    local grabber = nil

    local popup = wibox({
        type = "dialog",
        screen = s,
        width = beautiful.dashboard_width or dpi(280),
        height = screen_height - dpi(30),
        shape = helpers.rrect(beautiful.border_radius),
        bg = beautiful.xbackground,
        ontop = true,
        visible = false,
        border_width = dpi(1),
        border_color = "#06b6d433",
    })

    popup.y = dpi(15)
    popup.x = s.geometry.x - dpi(290)

    local slide = rubato.timed{
        pos = s.geometry.x - dpi(290),
        rate = 60,
        intro = 0.05,
        duration = 0.3,
        easing = rubato.quadratic,
        awestore_compat = true,
        subscribed = function(pos) popup.x = pos end
    }

    local popup_open = false

    local function create_monitor_widget(monitor_name)
        local current_temp = load_temp(monitor_name, 6500)

        local name_label = wibox.widget{
            markup = helpers.colorize_text(monitor_name, beautiful.xforeground),
            font = beautiful.font_name .. "bold 10",
            align = "left",
            valign = "center",
            widget = wibox.widget.textbox
        }

        local temp_value = wibox.widget{
            markup = helpers.colorize_text(current_temp .. "K", beautiful.xcolor6),
            font = beautiful.font_name .. "bold 10",
            align = "right",
            valign = "center",
            forced_width = dpi(90),
            widget = wibox.widget.textbox
        }

        local slider = wibox.widget{
            bar_shape = helpers.rrect(dpi(4)),
            bar_height = dpi(6),
            bar_color = beautiful.darker_bg,
            bar_active_color = beautiful.xcolor6,
            handle_shape = gears.shape.circle,
            handle_width = dpi(16),
            handle_color = beautiful.xcolor6,
            handle_border_width = 0,
            minimum = 1000,
            maximum = 20000,
            value = current_temp,
            forced_height = dpi(24),
            widget = wibox.widget.slider
        }

        local orig_set_value = slider.set_value
        slider.set_value = function(self, value)
            local w = self._drag_width
            if w then
                local min = self:get_minimum()
                local max = self:get_maximum()
                local interval = max - min
                local hw = self._private.handle_width or beautiful.slider_handle_width or 0
                if interval > 0 and w > hw then
                    value = min + math.floor(((value - min) * w - hw * interval / 2) / (w - hw))
                end
            end
            orig_set_value(self, value)
        end

        slider:connect_signal("button::press", function(self, _, _, button_id, _, geo)
            if button_id ~= 1 then return end
            self._drag_width = geo.widget_width
            self:set_value(self:get_value())
        end)

        slider:connect_signal("button::release", function(self)
            self._drag_width = nil
        end)

        slider:set_value(current_temp)

        local warm_label = wibox.widget{
            markup = helpers.colorize_text(i18n.tr("ct.warm") or "☀ Warm", beautiful.xcolor3),
            font = beautiful.font_name .. "8",
            align = "left",
            valign = "center",
            widget = wibox.widget.textbox
        }

        local cool_label = wibox.widget{
            markup = helpers.colorize_text(i18n.tr("ct.cool") or "❄ Cool", beautiful.xcolor4),
            font = beautiful.font_name .. "8",
            align = "right",
            valign = "center",
            widget = wibox.widget.textbox
        }

        local labels_row = wibox.widget{
            warm_label,
            nil,
            cool_label,
            layout = wibox.layout.align.horizontal
        }

        local header_row = wibox.widget{
            name_label,
            nil,
            temp_value,
            layout = wibox.layout.align.horizontal
        }

        local widget = wibox.widget{
            header_row,
            slider,
            labels_row,
            spacing = dpi(4),
            layout = wibox.layout.fixed.vertical
        }

        widget = wibox.container.margin(widget, 0, 0, dpi(8), dpi(8))

        slider:connect_signal("property::value", function(_, value)
            local temp = math.floor(value)
            temp_value.markup = helpers.colorize_text(temp .. "K", beautiful.xcolor6)
            local r, g, b = temp_to_gamma(temp)
            set_monitor_gamma(monitor_name, r, g, b)
            save_temp(monitor_name, temp)
        end)

        return {widget = widget, slider = slider, temp_value = temp_value, monitor = monitor_name}
    end

    local monitors_container = wibox.widget{
        spacing = dpi(12),
        layout = wibox.layout.fixed.vertical
    }

    local function refresh_monitors()
        get_connected_monitors(function(detected_monitors)
            monitors = detected_monitors
            monitors_container:reset()
            monitor_widgets = {}

            if #monitors == 0 then
                local no_monitors = wibox.widget{
                    markup = helpers.colorize_text(i18n.tr("ct.no_monitors") or "No monitors connected", beautiful.xcolor8),
                    font = beautiful.font_name .. "10",
                    align = "center",
                    valign = "center",
                    forced_height = dpi(100),
                    widget = wibox.widget.textbox
                }
                monitors_container:add(no_monitors)
            else
                for _, monitor in ipairs(monitors) do
                    local mw = create_monitor_widget(monitor)
                    table.insert(monitor_widgets, mw)
                    monitors_container:add(mw.widget)
                end
            end
            monitors_container:emit_signal("widget::layout_changed")
        end)
    end

    local function show()
        refresh_monitors()
        popup.visible = true
        slide:set(s.geometry.x + dpi(64))
        popup_open = true
    end

    local function hide()
        slide:set(s.geometry.x - dpi(290))
        popup_open = false
        gears.timer.start_new(0.3, function()
            if not popup_open then popup.visible = false end
        end)
    end

    popup._show = show
    popup._hide = hide

    local function toggle()
        if popup_open then hide() else show() end
    end
    popup._toggle = toggle

    local popup_hide_timer = gears.timer {
        timeout = 2,
        autostart = false,
        single_shot = true,
        callback = function()
            if popup.visible then hide() end
        end
    }

    popup:connect_signal("mouse::enter", function()
        popup_hide_timer:stop()
    end)

    popup:connect_signal("mouse::leave", function()
        popup_hide_timer:again()
    end)

    local esc_hint = wibox.widget{
        markup = helpers.colorize_text(i18n.tr("ct.esc_hint") or "ESC to close", beautiful.xcolor6),
        font = beautiful.font_name .. "8",
        align = "center",
        valign = "center",
        forced_height = dpi(16),
        widget = wibox.widget.textbox
    }

    local title = wibox.widget{
        markup = helpers.colorize_text(i18n.tr("ct.title") or "Color Temperature", beautiful.xforeground),
        font = beautiful.font_name .. "bold 12",
        align = "center",
        valign = "center",
        forced_height = dpi(40),
        widget = wibox.widget.textbox
    }

    local header = wibox.widget{
        {
            esc_hint,
            title,
            layout = wibox.layout.fixed.vertical
        },
        layout = wibox.layout.align.horizontal
    }
    header = wibox.container.margin(header, dpi(16), dpi(16), dpi(8), dpi(8))

    local content = wibox.container.margin(monitors_container, dpi(16), dpi(16), 0, dpi(16))

    local main_layout = wibox.layout.fixed.vertical()
    main_layout:add(header)
    main_layout:add(content)

    popup:set_widget(main_layout)

    popup:buttons(gears.table.join(
        awful.button({}, 3, function() hide() end)
    ))

    popup:connect_signal("property::visible", function()
        if popup.visible then
            grabber = awful.keygrabber.run(function(_, key, event)
                if event == "press" and key == "Escape" then hide() end
            end)
        else
            if grabber then pcall(awful.keygrabber.stop, grabber) end
            grabber = nil
        end
    end)

    -- Initial sync detection
    local function detect_monitors_sync()
        local handle = io.popen("xrandr --query | grep ' connected'")
        if handle then
            local stdout = handle:read("*a")
            handle:close()
            monitors = {}
            for line in stdout:gmatch("[^\r\n]+") do
                local name = line:match("^([%w%-]+) connected")
                if name then
                    table.insert(monitors, name)
                end
            end
            monitors_container:reset()
            monitor_widgets = {}

            if #monitors == 0 then
                local no_monitors = wibox.widget{
                    markup = helpers.colorize_text(i18n.tr("ct.no_monitors") or "No monitors connected", beautiful.xcolor8),
                    font = beautiful.font_name .. "10",
                    align = "center",
                    valign = "center",
                    forced_height = dpi(100),
                    widget = wibox.widget.textbox
                }
                monitors_container:add(no_monitors)
            else
                for _, monitor in ipairs(monitors) do
                    local mw = create_monitor_widget(monitor)
                    table.insert(monitor_widgets, mw)
                    monitors_container:add(mw.widget)
                end
            end
            monitors_container:emit_signal("widget::layout_changed")
        end
    end

    detect_monitors_sync()

    return popup
end

function color_temp.apply_saved()
    local f = io.open(prefs_file, "r")
    if f then
        for line in f:lines() do
            local m, t = line:match("([^=]+)=(.+)")
            if m and t then
                local temp = tonumber(t)
                if temp then
                    local r, g, b = temp_to_gamma(temp)
                    set_monitor_gamma(m, r, g, b)
                end
            end
        end
        f:close()
    end
end

return color_temp