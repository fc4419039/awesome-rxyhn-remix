local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local gears = require("gears")
local helpers = require("helpers")
local rubato = require("module.rubato")

local volume_panel = {}
local panels = {}

local function sink_vol(sink)
    local f = io.popen("pactl get-sink-volume " .. sink .. " 2>/dev/null")
    local out = f and f:read("*a") or ""
    if f then f:close() end
    return tonumber(out:match("(%d+)%%")) or 100
end

local function sink_muted(sink)
    local f = io.popen("pactl get-sink-mute " .. sink .. " 2>/dev/null")
    local out = f and f:read("*a") or ""
    if f then f:close() end
    return out:find("Mute: yes") ~= nil
end

local function get_sink_inputs()
    local f = io.popen("pactl list sink-inputs 2>/dev/null")
    local stdout = f and f:read("*a") or ""
    if f then f:close() end

    local apps = {}
    local current = nil
    for line in (stdout .. "\n"):gmatch("(.-)\n") do
        local sid = line:match("^Sink Input #(%d+)")
        if sid then
            if current then apps[#apps + 1] = current end
            current = { id = sid, props = {}, vol = 100, muted = false }
        elseif current then
            local prop_k, prop_v = line:match("^%s+([%w%.]+)%s*=%s*\"(.*)\"")
            if prop_k then
                current.props[prop_k] = prop_v
            else
                local v = line:match("^%s+Volume:.-(%d+)%%")
                if v then current.vol = tonumber(v) end
                if line:find("Mute: yes") then
                    current.muted = true
                elseif line:find("Mute:") then
                    current.muted = false
                end
            end
        end
    end
    if current then apps[#apps + 1] = current end

    -- Quitar streams internos (loopbacks)
    local result = {}
    for _, app in ipairs(apps) do
        local mname = app.props["media.name"] or ""
        if not mname:find("^loopback%-") then
            result[#result + 1] = app
        end
    end

    table.sort(result, function(a, b)
        local na = a.props["application.name"] or ""
        local nb = b.props["application.name"] or ""
        return na < nb
    end)

    return result
end

local function create_panel(s)
    local panel_w = dpi(320)
    local screen_height = s.geometry.height

    local popup = wibox({
        type = "dialog",
        screen = s,
        width = panel_w,
        height = screen_height - dpi(30),
        shape = helpers.rrect(beautiful.border_radius),
        bg = beautiful.xbackground,
        ontop = true,
        visible = false,
        border_width = dpi(1),
        border_color = "#06b6d433",
    })

    popup.y = dpi(15)
    popup.x = s.geometry.x - panel_w

    local slide = rubato.timed{
        pos = s.geometry.x - panel_w,
        rate = 60,
        intro = 0.05,
        duration = 0.3,
        easing = rubato.quadratic,
        awestore_compat = true,
        subscribed = function(pos) popup.x = pos end
    }

    local popup_open = false
    local dragging = false

    local esc_hint = wibox.widget{
        markup = helpers.colorize_text("ESC para cerrar", beautiful.xcolor6),
        font = beautiful.font_name .. "8",
        align = "center",
        valign = "center",
        forced_height = dpi(16),
        widget = wibox.widget.textbox
    }

    local title = wibox.widget{
        markup = helpers.colorize_text("Control de Volumen", beautiful.xforeground),
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

    local rows_container = wibox.widget{
        spacing = dpi(10),
        layout = wibox.layout.fixed.vertical
    }

    local function make_row(name, color, vol, muted, set_vol, toggle_mute)
        local name_label = wibox.widget{
            markup = helpers.colorize_text(name, beautiful.xforeground),
            font = beautiful.font_name .. "bold 10",
            align = "left",
            valign = "center",
            forced_width = panel_w - dpi(170),
            forced_height = dpi(20),
            widget = wibox.widget.textbox
        }

        local value_label = wibox.widget{
            markup = helpers.colorize_text(vol .. "%", color),
            font = beautiful.font_name .. "bold 10",
            align = "right",
            valign = "center",
            forced_width = dpi(46),
            widget = wibox.widget.textbox
        }

        local mute_icon = wibox.widget{
            markup = helpers.colorize_text(muted and "" or "", muted and beautiful.xcolor8 or color),
            font = beautiful.font_name .. "bold 12",
            align = "center",
            valign = "center",
            widget = wibox.widget.textbox
        }

        local mute_btn = wibox.widget{
            {
                mute_icon,
                margins = dpi(2),
                widget = wibox.container.margin
            },
            bg = beautiful.dashboard_box_bg,
            shape = helpers.rrect(dpi(5)),
            forced_width = dpi(24),
            forced_height = dpi(24),
            widget = wibox.container.background
        }

        mute_btn:connect_signal("mouse::enter", function()
            mute_btn.bg = beautiful.lighter_bg
        end)
        mute_btn:connect_signal("mouse::leave", function()
            mute_btn.bg = beautiful.dashboard_box_bg
        end)

        local slider = wibox.widget{
            bar_shape = helpers.rrect(dpi(4)),
            bar_height = dpi(6),
            bar_color = beautiful.darker_bg,
            bar_active_color = color,
            handle_shape = gears.shape.circle,
            handle_width = dpi(14),
            handle_color = color,
            handle_border_width = 0,
            minimum = 0,
            maximum = 100,
            value = math.min(100, vol),
            forced_height = dpi(24),
            widget = wibox.widget.slider
        }

        slider:connect_signal("property::value", function(_, value)
            local v = math.floor(value + 0.5)
            value_label.markup = helpers.colorize_text(v .. "%", color)
            set_vol(v)
        end)

        slider:connect_signal("button::press", function()
            dragging = true
        end)
        slider:connect_signal("button::release", function()
            dragging = false
            refresh()
        end)

        local right_side = wibox.widget{
            mute_btn,
            value_label,
            spacing = dpi(6),
            layout = wibox.layout.fixed.horizontal
        }

        local header_row = wibox.widget{
            name_label,
            nil,
            right_side,
            layout = wibox.layout.align.horizontal
        }

        local w = wibox.widget{
            header_row,
            slider,
            spacing = dpi(2),
            layout = wibox.layout.fixed.vertical
        }

        w = wibox.container.margin(w, dpi(10), dpi(10), dpi(8), dpi(8))
        w = wibox.widget{
            w,
            bg = beautiful.dashboard_box_bg,
            shape = helpers.rrect(beautiful.border_radius),
            widget = wibox.container.background
        }

        mute_btn:buttons(gears.table.join(
            awful.button({}, 1, function()
                toggle_mute()
                refresh()
            end)
        ))

        return w
    end

    local function refresh()
        if dragging then return end
        rows_container:reset()

        rows_container:add(make_row(
            "Sistema",
            beautiful.xcolor4,
            sink_vol("system_sink"),
            sink_muted("system_sink"),
            function(v) awful.spawn.with_shell("pactl set-sink-volume system_sink " .. v .. "% 2>/dev/null || true") end,
            function() awful.spawn.with_shell("pactl set-sink-mute system_sink toggle 2>/dev/null || true") end
        ))

        rows_container:add(make_row(
            "Notificaciones",
            beautiful.xcolor6,
            sink_vol("notifications"),
            sink_muted("notifications"),
            function(v) awful.spawn.with_shell("pactl set-sink-volume notifications " .. v .. "% 2>/dev/null || true") end,
            function() awful.spawn.with_shell("pactl set-sink-mute notifications toggle 2>/dev/null || true") end
        ))

        local sep = wibox.widget{
            bg = beautiful.darker_bg,
            forced_height = dpi(1),
            widget = wibox.container.background
        }
        sep = wibox.container.margin(sep, dpi(12), dpi(12), dpi(2), dpi(2))
        rows_container:add(sep)

        local apps = get_sink_inputs()
        if #apps == 0 then
            local no_apps = wibox.widget{
                markup = helpers.colorize_text("Ninguna aplicación reproduciendo audio", beautiful.xcolor8),
                font = beautiful.font_name .. "10",
                align = "center",
                valign = "center",
                forced_height = dpi(60),
                widget = wibox.widget.textbox
            }
            rows_container:add(no_apps)
        else
            for _, app in ipairs(apps) do
                local name = app.props["application.name"] or app.props["media.name"] or ("App #" .. app.id)
                rows_container:add(make_row(
                    name,
                    beautiful.xcolor3,
                    app.vol,
                    app.muted,
                    function(v) awful.spawn.with_shell("pactl set-sink-input-volume " .. app.id .. " " .. v .. "% 2>/dev/null || true") end,
                    function() awful.spawn.with_shell("pactl set-sink-input-mute " .. app.id .. " toggle 2>/dev/null || true") end
                ))
            end
        end

        rows_container:emit_signal("widget::layout_changed")
    end

    local content = wibox.container.margin(rows_container, dpi(16), dpi(16), 0, dpi(16))

    local main_layout = wibox.layout.fixed.vertical()
    main_layout:add(header)
    main_layout:add(content)

    popup:set_widget(main_layout)

    local refresh_timer = gears.timer {
        timeout = 1,
        autostart = false,
        single_shot = false,
        callback = function()
            if popup.visible then refresh() end
        end
    }

    local function show()
        refresh()
        popup.visible = true
        refresh_timer:start()
        slide:set(s.geometry.x + dpi(64))
        popup_open = true
    end

    local function hide()
        slide:set(s.geometry.x - panel_w)
        popup_open = false
        refresh_timer:stop()
        gears.timer.start_new(0.3, function()
            if not popup_open then popup.visible = false end
        end)
    end

    popup._show = show
    popup._hide = hide
    popup._toggle = function()
        if popup_open then hide() else show() end
    end

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

    popup:buttons(gears.table.join(
        awful.button({}, 3, function() hide() end)
    ))

    local grabber
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

    return popup
end

function volume_panel.toggle(s)
    s = s or awful.screen.focused()
    local p = panels[s]
    if not p then
        p = create_panel(s)
        panels[s] = p
    end
    p:_toggle()
end

return volume_panel
