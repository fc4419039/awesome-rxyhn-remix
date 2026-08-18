local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local gears = require("gears")
local helpers = require("helpers")
local rubato = require("module.rubato")
local color_temp_module = require("ui.system_menu.color_temp")

local volume_panel = {}
local panels = {}
local slider_active = { count = 0 }

local TEMP_PREFS_FILE = (os.getenv("HOME") or "/tmp") .. "/.config/awesome/.color_temp_prefs"
local TEMP_SCALE_FILE = (os.getenv("HOME") or "/tmp") .. "/.config/awesome/.color_temp_scale"

-- Map scale (0-100) to Kelvin (1000-10000)
local function scale_to_kelvin(scale_val)
    -- scale_val: 0 = 1000K (warm), 100 = 10000K (cool)
    local k = 1000 + (scale_val / 100) * 9000
    return math.floor(k + 0.5)
end

local function kelvin_to_scale(k)
    -- Map 1000-10000K to 0-100
    local scale = (k - 1000) / 9000 * 100
    return math.floor(scale + 0.5)
end

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

local function get_brightness()
    local f = io.popen("brightnessctl get 2>/dev/null")
    local out = f and f:read("*l") or ""
    if f then f:close() end
    local max_f = io.popen("brightnessctl max 2>/dev/null")
    local max = max_f and max_f:read("*l") or ""
    if max_f then max_f:close() end
    local cur = tonumber(out) or 0
    local mx = tonumber(max) or 100
    if mx > 0 then
        return math.floor((cur / mx) * 100 + 0.5)
    end
    return 0
end

-- Get current color temp scale value (0-100) from prefs file
local function get_color_temp_scale()
    local f = io.open(TEMP_SCALE_FILE, "r")
    if f then
        local val = tonumber(f:read("*l"))
        f:close()
        if val then
            return math.max(0, math.min(100, val))
        end
    end
    -- Default: map 6500K to scale
    return kelvin_to_scale(6500)
end

-- Get connected and active monitors
local function get_connected_monitors()
    local monitors = {}
    local proc = io.popen("xrandr --query 2>/dev/null")
    if proc then
        local stdout = proc:read("*a")
        proc:close()
        for line in stdout:gmatch("[^\r\n]+") do
            -- Match connected AND active (has resolution/position)
            local name, state = line:match("^([%w%-]+) connected (.*)")
            if name and state then
                -- Filter out disconnected/broken outputs
                if not state:find(" disconnected") and state ~= "" then
                    table.insert(monitors, name)
                end
            else
                -- Also match simple "connected" without extra state
                local name = line:match("^([%w%-]+) connected")
                if name then
                    table.insert(monitors, name)
                end
            end
        end
    end
    return monitors
end

-- Apply color temp from scale value (0-100), with monitor detection
local function set_color_temp_scale(scale_val)
    scale_val = math.max(0, math.min(100, scale_val))
    local kelvin = scale_to_kelvin(scale_val)

    -- Save scale value for persistence
    local f = io.open(TEMP_SCALE_FILE, "w")
    if f then
        f:write(tostring(scale_val))
        f:close()
    end

    -- Get connected and active monitors
    local monitors = get_connected_monitors()

    for _, m in ipairs(monitors) do
        if m and m ~= "" then
            local r, g, b = color_temp_module.temp_to_gamma(kelvin)
            awful.spawn({"xrandr", "--output", m, "--gamma", string.format("%.4f:%.4f:%.4f", r, g, b)})

            -- Save kelvin value in prefs file for color_temp module compatibility
            local entries = {}
            local pf = io.open(TEMP_PREFS_FILE, "r")
            if pf then
                for line in pf:lines() do
                    local mon, t = line:match("([^=]+)=(.+)")
                    if mon and t and mon ~= m then
                        entries[#entries + 1] = mon .. "=" .. t
                    end
                end
                pf:close()
            end
            entries[#entries + 1] = m .. "=" .. kelvin
            local wf = io.open(TEMP_PREFS_FILE, "w")
            if wf then
                wf:write(table.concat(entries, "\n") .. "\n")
                wf:close()
            end
        end
    end

    -- Notify other parts of the system about the change
    awesome.emit_signal("volume_panel::color_temp_changed", scale_val, kelvin)
end

local function make_brightness_row(panel_w)
    local brightness = get_brightness()

    local name_label = wibox.widget{
        markup = helpers.colorize_text("Brillo", beautiful.xforeground),
        font = beautiful.font_name .. "bold 10",
        align = "left",
        valign = "center",
        forced_width = panel_w - dpi(128),
        forced_height = dpi(20),
        widget = wibox.widget.textbox
    }

    local value_label = wibox.widget{
        markup = helpers.colorize_text(brightness .. "%", beautiful.xcolor5),
        font = beautiful.font_name .. "bold 10",
        align = "right",
        valign = "center",
        forced_width = dpi(46),
        widget = wibox.widget.textbox
    }

    local slider = wibox.widget{
        bar_shape = helpers.rrect(dpi(4)),
        bar_height = dpi(6),
        bar_color = beautiful.darker_bg,
        bar_active_color = beautiful.xcolor5,
        handle_shape = gears.shape.circle,
        handle_width = dpi(14),
        handle_color = beautiful.xcolor5,
        handle_border_width = 0,
        minimum = 0,
        maximum = 100,
        value = math.min(100, brightness),
        forced_height = dpi(24),
        widget = wibox.widget.slider
    }

    local dragging = false
    local committing = false

    slider:connect_signal("property::value", function(_, value)
        if committing then return end
        local v = math.floor(value + 0.5)
        value_label.markup = helpers.colorize_text(v .. "%", beautiful.xcolor5)
        awful.spawn.with_shell("brightnessctl set " .. v .. "% -q")
    end)

    slider:connect_signal("button::press", function()
        dragging = true
        slider_active.count = slider_active.count + 1
    end)
    slider:connect_signal("button::release", function()
        dragging = false
        slider_active.count = math.max(0, slider_active.count - 1)
        committing = true
        local v = math.floor(slider:get_value() + 0.5)
        value_label.markup = helpers.colorize_text(v .. "%", beautiful.xcolor5)
        awful.spawn.with_shell("brightnessctl set " .. v .. "% -q")
        -- Bloquear property::value espurios por 300ms para evitar rollback
        gears.timer.start_new(0.3, function()
            committing = false
        end)
    end)

    local row = wibox.widget{
        name_label,
        nil,
        value_label,
        layout = wibox.layout.align.horizontal
    }

    local row_container = wibox.widget{
        row,
        slider,
        spacing = dpi(2),
        layout = wibox.layout.fixed.vertical
    }
    row_container = wibox.container.margin(row_container, dpi(10), dpi(10), dpi(8), dpi(8))
    row_container = wibox.widget{
        row_container,
        bg = beautiful.dashboard_box_bg,
        shape = helpers.rrect(beautiful.border_radius),
        widget = wibox.container.background
    }

    return row_container
end

local function make_color_temp_row(panel_w)
    local current_scale = get_color_temp_scale()

    local name_label = wibox.widget{
        markup = helpers.colorize_text("Temp Color", beautiful.xforeground),
        font = beautiful.font_name .. "bold 10",
        align = "left",
        valign = "center",
        forced_width = panel_w - dpi(128),
        forced_height = dpi(20),
        widget = wibox.widget.textbox
    }

    local value_label = wibox.widget{
        markup = helpers.colorize_text(current_scale .. "%", beautiful.xcolor6),
        font = beautiful.font_name .. "bold 10",
        align = "right",
        valign = "center",
        forced_width = dpi(46),
        widget = wibox.widget.textbox
    }

    local cold_label = wibox.widget{
        markup = helpers.colorize_text("1", beautiful.xcolor4),
        font = beautiful.font_name .. "8",
        align = "left",
        valign = "center",
        widget = wibox.widget.textbox
    }

    local warm_label = wibox.widget{
        markup = helpers.colorize_text("100", beautiful.xcolor3),
        font = beautiful.font_name .. "8",
        align = "right",
        valign = "center",
        widget = wibox.widget.textbox
    }

    local labels_row = wibox.widget{
        cold_label,
        nil,
        warm_label,
        layout = wibox.layout.align.horizontal
    }

    local slider = wibox.widget{
        bar_shape = helpers.rrect(dpi(4)),
        bar_height = dpi(6),
        bar_color = beautiful.darker_bg,
        bar_active_color = beautiful.xcolor6,
        handle_shape = gears.shape.circle,
        handle_width = dpi(14),
        handle_color = beautiful.xcolor6,
        handle_border_width = 0,
        minimum = 0,
        maximum = 100,
        value = current_scale,
        forced_height = dpi(24),
        widget = wibox.widget.slider
    }

    local dragging = false
    local committing = false

    slider:connect_signal("property::value", function(_, value)
        if committing then return end
        local v = math.floor(value + 0.5)
        value_label.markup = helpers.colorize_text(v .. "%", beautiful.xcolor6)
        set_color_temp_scale(v)
    end)

    slider:connect_signal("button::press", function()
        dragging = true
        slider_active.count = slider_active.count + 1
    end)
    slider:connect_signal("button::release", function()
        dragging = false
        slider_active.count = math.max(0, slider_active.count - 1)
        committing = true
        local v = math.floor(slider:get_value() + 0.5)
        value_label.markup = helpers.colorize_text(v .. "%", beautiful.xcolor6)
        set_color_temp_scale(v)
        -- Bloquear cualquier property::value espurio por 300ms
        gears.timer.start_new(0.3, function()
            committing = false
        end)
    end)

    local header_row = wibox.widget{
        name_label,
        nil,
        value_label,
        layout = wibox.layout.align.horizontal
    }

    local row = wibox.widget{
        header_row,
        slider,
        labels_row,
        spacing = dpi(4),
        layout = wibox.layout.fixed.vertical
    }

    row = wibox.container.margin(row, 0, 0, dpi(8), dpi(8))

    local row_container = wibox.widget{
        row,
        bg = beautiful.dashboard_box_bg,
        shape = helpers.rrect(beautiful.border_radius),
        widget = wibox.container.background
    }

    return row_container
end

local function make_row(name, color, vol, muted, set_vol, toggle_mute)
    local panel_w = beautiful.dashboard_width or dpi(280)
    local name_label = wibox.widget{
        markup = helpers.colorize_text(name, beautiful.xforeground),
        font = beautiful.font_name .. "bold 10",
        align = "left",
        valign = "center",
        forced_width = panel_w - dpi(128),
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
        markup = helpers.colorize_text(muted and "" or "", muted and beautiful.xcolor8 or color),
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

    local row_dragging = false
    local row_committing = false

    slider:connect_signal("property::value", function(_, value)
        if row_committing then return end
        local v = math.floor(value + 0.5)
        value_label.markup = helpers.colorize_text(v .. "%", color)
        set_vol(v)
    end)

    slider:connect_signal("button::press", function()
        row_dragging = true
        slider_active.count = slider_active.count + 1
    end)
    slider:connect_signal("button::release", function()
        row_dragging = false
        slider_active.count = math.max(0, slider_active.count - 1)
        row_committing = true
        local v = math.floor(slider:get_value() + 0.5)
        value_label.markup = helpers.colorize_text(v .. "%", color)
        set_vol(v)
        -- Bloquear property::value espurios por 300ms para evitar rollback
        gears.timer.start_new(0.3, function()
            row_committing = false
        end)
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

local function create_panel(s)
    local panel_w = beautiful.dashboard_width or dpi(280)
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
    local hide_func = nil

    local title = wibox.widget{
        markup = helpers.colorize_text("Centro de Control", beautiful.xforeground),
        font = beautiful.font_name .. "bold 12",
        align = "left",
        valign = "center",
        forced_height = dpi(40),
        widget = wibox.widget.textbox
    }

    local esc_hint = wibox.widget{
        markup = helpers.colorize_text("ESC", beautiful.xcolor6),
        font = beautiful.font_name .. "8",
        align = "right",
        valign = "center",
        forced_height = dpi(16),
        widget = wibox.widget.textbox
    }

    -- Flexible spacer to push ESC to the right edge
    local spacer = wibox.widget{
        forced_width = 0,
        forced_height = 0,
        widget = wibox.widget.textbox
    }

    -- Header: title on left, esc pegado a la esquina derecha
    local top_row = wibox.widget{
        title,
        spacer,
        esc_hint,
        layout = wibox.layout.align.horizontal
    }
    top_row = wibox.container.margin(top_row, dpi(16), dpi(0), dpi(8), dpi(8))

     -- Icon buttons row (wifi tiene icono interno más grande)
     local power_btn = wibox.widget{
         markup = helpers.colorize_text("⏻", beautiful.xcolor3),
         font = beautiful.font_name .. "bold 20",
         align = "center",
         valign = "center",
         forced_width = dpi(48),
         forced_height = dpi(48),
         widget = wibox.widget.textbox
     }

     local bluetooth_btn = wibox.widget{
         markup = helpers.colorize_text("", beautiful.xcolor5),
         font = beautiful.font_name .. "bold 20",
         align = "center",
         valign = "center",
         forced_width = dpi(48),
         forced_height = dpi(48),
         widget = wibox.widget.textbox
     }

     local wifi_btn = wibox.widget{
         markup = helpers.colorize_text("", beautiful.xcolor4),
         font = beautiful.font_name .. "bold 26",
         align = "center",
         valign = "center",
         forced_width = dpi(48),
         forced_height = dpi(48),
         widget = wibox.widget.textbox
     }

     local function make_icon_box(widget, size)
         local box = wibox.widget{
             widget,
             bg = beautiful.dashboard_box_bg,
             shape = gears.shape.circle,
             forced_width = dpi(size),
             forced_height = dpi(size),
             widget = wibox.container.background
         }
         box:connect_signal("mouse::enter", function()
             box.bg = beautiful.lighter_bg
         end)
         box:connect_signal("mouse::leave", function()
             box.bg = beautiful.dashboard_box_bg
         end)
         return box
     end

     local power_box = make_icon_box(power_btn, 48)
     local bluetooth_box = make_icon_box(bluetooth_btn, 48)
     local wifi_box = make_icon_box(wifi_btn, 48)

     -- Función para actualizar el color del icono de wifi (cyan activado, rojo apagado)
     local function update_wifi_color()
         awful.spawn.easy_async_with_shell("nmcli radio wifi 2>/dev/null", function(stdout)
             local wifi_state = stdout:gsub("%s", "")
             if wifi_state == "enabled" then
                 wifi_btn.markup = helpers.colorize_text("", beautiful.xcolor4)
             else
                 wifi_btn.markup = helpers.colorize_text("", "#ef4444")
             end
         end)
     end
     update_wifi_color()

    local icon_row = wibox.container.margin(wibox.widget{
        power_box,
        bluetooth_box,
        wifi_box,
        spacing = dpi(12),
        layout = wibox.layout.fixed.horizontal
    }, 0, 0, dpi(4), dpi(4))

    -- Icons row centered
    local icon_row_centered = wibox.container.margin(wibox.widget{
        nil,
        icon_row,
        nil,
        layout = wibox.layout.align.horizontal
    }, dpi(16), dpi(16), 0, dpi(2))

    local function hide()
        if hide_func then
            hide_func()
        end
    end

    power_btn:buttons(gears.table.join(
        awful.button({}, 1, function()
            hide()
            awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/powermenu.sh")
        end)
    ))

    bluetooth_btn:buttons(gears.table.join(
        awful.button({}, 1, function()
            hide()
            awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/bluetooth.sh")
        end)
    ))

    wifi_btn:buttons(gears.table.join(
        awful.button({}, 1, function()
            hide()
            awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/network.sh")
        end)
    ))

    local header = wibox.widget{
        {
            top_row,
            icon_row_centered,
            layout = wibox.layout.fixed.vertical
        },
        layout = wibox.layout.align.horizontal
    }

    local rows_container = wibox.widget{
        spacing = dpi(10),
        layout = wibox.layout.fixed.vertical
    }

function refresh()
         if slider_active.count > 0 then return end
         update_wifi_color()
         rows_container:reset()

        -- Brightness control section (first)
        local sep1 = wibox.widget{
            bg = beautiful.darker_bg,
            forced_height = dpi(1),
            widget = wibox.container.background
        }
        sep1 = wibox.container.margin(sep1, dpi(12), dpi(12), dpi(2), dpi(2))
        rows_container:add(sep1)

        rows_container:add(make_brightness_row(panel_w))

        -- Volume controls
        local sep_vol = wibox.widget{
            bg = beautiful.darker_bg,
            forced_height = dpi(1),
            widget = wibox.container.background
        }
        sep_vol = wibox.container.margin(sep_vol, dpi(12), dpi(12), dpi(2), dpi(2))
        rows_container:add(sep_vol)

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

        -- Application volumes
        local sep_app = wibox.widget{
            bg = beautiful.darker_bg,
            forced_height = dpi(1),
            widget = wibox.container.background
        }
        sep_app = wibox.container.margin(sep_app, dpi(12), dpi(12), dpi(2), dpi(2))
        rows_container:add(sep_app)

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

        -- Color temp control section (last)
        local sep2 = wibox.widget{
            bg = beautiful.darker_bg,
            forced_height = dpi(1),
            widget = wibox.container.background
        }
        sep2 = wibox.container.margin(sep2, dpi(12), dpi(12), dpi(2), dpi(2))
        rows_container:add(sep2)

        rows_container:add(make_color_temp_row(panel_w))

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

    hide_func = function()
        slide:set(s.geometry.x - panel_w)
        popup_open = false
        refresh_timer:stop()
        gears.timer.start_new(0.3, function()
            if not popup_open then popup.visible = false end
        end)
    end

    local function show()
        refresh()
        popup.visible = true
        refresh_timer:start()
        slide:set(s.geometry.x + dpi(64))
        popup_open = true
    end

    popup._show = show
    popup._hide = hide_func
    popup._toggle = function()
        if popup_open then hide_func() else show() end
    end

    local popup_hide_timer = gears.timer {
        timeout = 2,
        autostart = false,
        single_shot = true,
        callback = function()
            if popup.visible then hide_func() end
        end
    }

    popup:connect_signal("mouse::enter", function()
        popup_hide_timer:stop()
    end)

    popup:connect_signal("mouse::leave", function()
        popup_hide_timer:again()
    end)

    popup:buttons(gears.table.join(
        awful.button({}, 3, function() hide_func() end)
    ))

    local grabber
    popup:connect_signal("property::visible", function()
        if popup.visible then
            grabber = awful.keygrabber.run(function(_, key, event)
                if event == "press" and key == "Escape" then hide_func() end
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
