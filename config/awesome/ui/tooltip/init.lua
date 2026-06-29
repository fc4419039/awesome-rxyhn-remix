local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local wibox = require("wibox")
local rubato = require("module.rubato")
local helpers = require("helpers")
local naughty = require("naughty")

local function create_boxed_widget(widget_to_be_boxed, width, height, inner_pad)
    local box_container = wibox.container.background()
    box_container.bg = beautiful.xcolor0
    box_container.forced_height = height
    box_container.forced_width = width
    box_container.shape = helpers.rrect(beautiful.tooltip_box_border_radius)

    local inner = dpi(0)
    if inner_pad then inner = beautiful.tooltip_box_margin end

    local boxed_widget = wibox.widget {
        {
            {
                widget_to_be_boxed,
                margins = inner,
                widget = wibox.container.margin
            },
            widget = box_container,
        },
        margins = beautiful.tooltip_gap / 2,
        color = "#FF000000",
        widget = wibox.container.margin
    }
    return boxed_widget
end

local M = {}

function M.create(s)
    -- Battery
    -------------

    local batt_bar = wibox.widget {
        max_value = 100,
        value = 20,
        background_color = beautiful.transparent,
        color = beautiful.xcolor8,
        widget = wibox.widget.progressbar
    }

    local batt_bar_container = wibox.widget {
        batt_bar,
        direction = "east",
        widget = wibox.container.rotate
    }

    local batt_icon = wibox.widget{
        markup = helpers.colorize_text("", beautiful.xcolor1),
        font = beautiful.icon_font_name .. "Round 18",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }

    local batt_icon_container = wibox.widget{
        nil,
        {
            nil,
            batt_icon,
            expand = "none",
            layout = wibox.layout.align.vertical
        },
        expand = "none",
        layout = wibox.layout.align.horizontal
    }

    local batt_pct = wibox.widget{
        font = beautiful.font_name .. "bold 12",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }

    local batt = wibox.widget{
        {
            batt_bar_container,
            batt_icon_container,
            layout = wibox.layout.stack
        },
        batt_pct,
        layout = wibox.layout.fixed.vertical
    }

    local batt_val = 0
    local batt_charger

    awesome.connect_signal("signal::battery", function(value)
        batt_val = value
        awesome.emit_signal("widget::battery")
    end)

    awesome.connect_signal("signal::charger", function(state)
        batt_charger = state
        awesome.emit_signal("widget::battery")
    end)

    awesome.connect_signal("widget::battery", function()
        local b = ""
        local fill_color = beautiful.xcolor2

        if batt_val >= 88 and batt_val <= 100 then
            b = ""
        elseif batt_val >= 76 and batt_val < 88 then
            b = ""
        elseif batt_val >= 64 and batt_val < 76 then
            b = ""
        elseif batt_val >= 52 and batt_val < 64 then
            b = ""
        elseif batt_val >= 40 and batt_val < 52 then
            b = ""
        elseif batt_val >= 28 and batt_val < 40 then
            b = ""
        elseif batt_val >= 16 and batt_val < 28 then
            b = ""
        else
            b = ""
        end

        if batt_charger then
            b = ""
            if batt_val >= 11 and batt_val <= 30 then
                fill_color = beautiful.xcolor3
            elseif batt_val <= 10 then
                fill_color = beautiful.xcolor1
            end
        else
            if batt_val >= 11 and batt_val <= 30 then
                fill_color = beautiful.xcolor3
            elseif batt_val <= 10 then
                fill_color = beautiful.xcolor1
            end
        end

        batt_bar.value = batt_val
        batt_icon.markup = helpers.colorize_text(b, fill_color)
        batt_pct.markup = helpers.colorize_text(batt_val .. "%", fill_color)
    end)


    -- Date
    ---------

    local date_day = wibox.widget{
        font = beautiful.font_name .. "bold 10",
        format = helpers.colorize_text("%A", beautiful.xcolor4),
        align = "center",
        valign = "center",
        widget = wibox.widget.textclock
    }

    local date_month = wibox.widget{
        font = beautiful.font_name .. "bold 14",
        format = "%d %B %Y",
        align = "center",
        valign = "center",
        widget = wibox.widget.textclock
    }

    local date = wibox.widget{
        date_day,
        nil,
        date_month,
        layout = wibox.layout.align.vertical
    }


    -- Separator
    ---------------

    local separator = wibox.widget{
        {
        bg = beautiful.xcolor5,
        shape = helpers.rrect(dpi(5)),
        forced_width = dpi(3),
        widget = wibox.container.background
        },
        right = dpi(5),
        widget = wibox.container.margin
    }


    -- Analog clock
    ------------------

    local analog_clock = require("ui.widgets.analog_clock").widget
    local analog_clock_api = require("ui.widgets.analog_clock")


    -- UpTime
    ------------

    local uptime_label = wibox.widget{
        font = beautiful.font_name .. "medium 9",
        markup = helpers.colorize_text("Uptime", beautiful.xcolor5),
        valign = "center",
        widget = wibox.widget.textbox
    }

    local uptime_text = wibox.widget {
        font = beautiful.font_name .. "bold 13",
        markup = helpers.colorize_text("-", beautiful.xcolor5),
        valign = "center",
        widget = wibox.widget.textbox
    }

    awesome.connect_signal("signal::uptime", function(uptime_value)
        uptime_text.markup = uptime_value
    end)

    local wifi_uptime_icon = wibox.widget{
        markup = helpers.colorize_text("", beautiful.xcolor2),
        font = beautiful.icon_font_name .. "Round 14",
        valign = "center",
        widget = wibox.widget.textbox
    }

    wifi_uptime_icon:connect_signal("mouse::enter", function()
        wifi_uptime_icon.markup = helpers.colorize_text("", beautiful.xcolor15)
    end)
    wifi_uptime_icon:connect_signal("mouse::leave", function()
        local c = wifi_connected_ssid ~= "" and beautiful.xcolor2 or beautiful.xcolor1
        local icon = wifi_connected_ssid ~= "" and "" or ""
        wifi_uptime_icon.markup = helpers.colorize_text(icon, c)
    end)
    wifi_uptime_icon:buttons(gears.table.join(
        awful.button({}, 1, function()
            awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/network.sh")
        end)
    ))
    helpers.add_hover_cursor(wifi_uptime_icon, "hand2")

    local bt_uptime_icon = wibox.widget{
        markup = helpers.colorize_text("", beautiful.xcolor4),
        font = beautiful.icon_font_name .. "Round 14",
        valign = "center",
        widget = wibox.widget.textbox
    }

    bt_uptime_icon:connect_signal("mouse::enter", function()
        bt_uptime_icon.markup = helpers.colorize_text("", beautiful.xcolor15)
    end)
    bt_uptime_icon:connect_signal("mouse::leave", function()
        bt_uptime_icon.markup = helpers.colorize_text("", beautiful.xcolor4)
    end)
    bt_uptime_icon:buttons(gears.table.join(
        awful.button({}, 1, function()
            awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/bluetooth.sh")
        end)
    ))
    helpers.add_hover_cursor(bt_uptime_icon, "hand2")

    local uptime_container = wibox.widget{
        separator,
        {
            uptime_label,
            nil,
            {
                uptime_text,
                wifi_uptime_icon,
                bt_uptime_icon,
                spacing = dpi(5),
                layout = wibox.layout.fixed.horizontal
            },
            layout = wibox.layout.align.vertical
        },
        layout = wibox.layout.align.horizontal
    }


    -- WiFi interactivo
    --------------------

    local wifi_networks_list = wibox.widget {
        spacing = dpi(4),
        layout = wibox.layout.fixed.vertical
    }

    local wifi_status_text = wibox.widget{
        font = beautiful.font_name .. "medium 9",
        markup = helpers.colorize_text("Scanning...", beautiful.dashboard_box_fg),
        valign = "center",
        widget = wibox.widget.textbox
    }

    local wifi_icon_w = wibox.widget{
        markup = helpers.colorize_text("", beautiful.xcolor2),
        font = beautiful.icon_font_name .. "Round 14",
        valign = "center",
        widget = wibox.widget.textbox
    }

    local wifi_refresh_btn = wibox.widget{
        markup = helpers.colorize_text("", beautiful.xcolor4),
        font = beautiful.font_name .. "bold 12",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }

    local wifi_rows = {}
    local wifi_scroll_pos = 0
    local wifi_max_visible = 5
    local wifi_connected_ssid = ""
    local wifi_pw_buf = ""
    local wifi_pw_active = false
    local wifi_pw_ssid = ""

    local function shell_escape(s)
        return s:gsub("'", "'\\''")
    end

    local function wifi_parse_error(output)
        if output:match("successfully") then
            return nil, nil
        end
        if output:match("already") then
            return nil, nil
        end
        if output:match("Secrets were required") or output:match("no secret") then
            return "error", "Contraseña requerida"
        end
        if output:match("password is not valid") or output:match("password too short") then
            return "error", "Contraseña muy corta o inválida (mín. 8 caracteres)"
        end
        if output:match("incorrect") or output:match("wrong") or output:match("Invalid properties") then
            return "error", "Contraseña incorrecta"
        end
        if output:match("could not be found") then
            return "error", "Red no encontrada"
        end
        if output:match("not available") then
            return "error", "Red no disponible"
        end
        if output:match("No network with SSID") then
            return "error", "No se encontró la red"
        end
        if output:match("timeout") or output:match("timed out") then
            return "error", "Tiempo de conexión agotado"
        end
        local err = output:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
        if err == "" then
            return "error", "Error de conexión desconocido"
        end
        return "error", err
    end

    local function wifi_update_display()
        if wifi_pw_active then
            awful.keygrabber.stop()
            wifi_pw_active = false
            wifi_pw_buf = ""
        end
        wifi_networks_list:reset()
        local start = wifi_scroll_pos + 1
        local finish = math.min(start + wifi_max_visible - 1, #wifi_rows)
        for i = start, finish do
            wifi_networks_list:add(wifi_rows[i])
        end
    end

    wifi_networks_list:buttons(gears.table.join(
        awful.button({}, 4, function()
            if wifi_scroll_pos > 0 then
                wifi_scroll_pos = wifi_scroll_pos - 1
                wifi_update_display()
            end
        end),
        awful.button({}, 5, function()
            if wifi_scroll_pos + wifi_max_visible < #wifi_rows then
                wifi_scroll_pos = wifi_scroll_pos + 1
                wifi_update_display()
            end
        end)
    ))

    local function wifi_scan()
        if wifi_pw_active then
            awful.keygrabber.stop()
            wifi_pw_active = false
            wifi_pw_buf = ""
        end
        wifi_networks_list:reset()
        wifi_networks_list:insert(1, wibox.widget {
            markup = helpers.colorize_text("Scanning...", beautiful.dashboard_box_fg),
            font = beautiful.font_name .. "medium 8",
            widget = wibox.widget.textbox
        })

        awful.spawn.easy_async_with_shell("nmcli -t -f SSID,SIGNAL,SECURITY device wifi list --rescan yes 2>/dev/null | head -20", function(stdout)
            wifi_rows = {}
            wifi_scroll_pos = 0
            if stdout == "" then
                wifi_networks_list:reset()
                wifi_networks_list:insert(1, wibox.widget {
                    markup = helpers.colorize_text("No networks found", beautiful.xcolor8),
                    font = beautiful.font_name .. "medium 8",
                    widget = wibox.widget.textbox
                })
                return
            end

            local seen = {}
            for line in stdout:gmatch("[^\n]+") do
                local ssid, signal, security = line:match("^(.*):(%d+):([^:]*)$")
                if ssid and ssid ~= "" and not seen[ssid] then
                    seen[ssid] = true
                    local sig = tonumber(signal) or 0
                    local connected = (ssid == wifi_connected_ssid)
                    local sig_color = connected and beautiful.xcolor2 or sig > 70 and beautiful.xcolor2 or sig > 30 and beautiful.xcolor3 or beautiful.xcolor1
                    local sig_bars = sig > 70 and "●●●" or sig > 50 and "●●○" or sig > 25 and "●○○" or "○○○"
                    local sec_color = security == "" and beautiful.xcolor2 or beautiful.xcolor3
                    local sec_text = security == "" and "" or ""

                    local row = wibox.widget {
                        {
                            {
                                markup = helpers.colorize_text(ssid, connected and beautiful.xcolor2 or beautiful.xforeground),
                                font = beautiful.font_name .. "medium 8",
                                valign = "center",
                                widget = wibox.widget.textbox
                            },
                            nil,
                            {
                                markup = helpers.colorize_text(sig_bars, sig_color) .. "  " .. helpers.colorize_text(sec_text, sec_color),
                                font = beautiful.font_name .. "medium 8",
                                valign = "center",
                                widget = wibox.widget.textbox
                            },
                            layout = wibox.layout.align.horizontal
                        },
                        margins = dpi(4),
                        widget = wibox.container.margin
                    }

                    row:connect_signal("mouse::enter", function()
                        row.bg = beautiful.xcolor8
                    end)
                    row:connect_signal("mouse::leave", function()
                        row.bg = beautiful.transparent
                    end)
                    row:buttons(gears.table.join(
                        awful.button({}, 1, function()
                            if security ~= "" then
                                if wifi_pw_active then
                                    awful.keygrabber.stop()
                                end
                                wifi_pw_active = true
                                wifi_pw_buf = ""
                                wifi_pw_ssid = ssid

                                wifi_networks_list:reset()
                                wifi_networks_list:add(wibox.widget {
                                    markup = helpers.colorize_text("Password for:", beautiful.dashboard_box_fg),
                                    font = beautiful.font_name .. "medium 7",
                                    widget = wibox.widget.textbox
                                })
                                wifi_networks_list:add(wibox.widget {
                                    markup = helpers.colorize_text(ssid, beautiful.xcolor3),
                                    font = beautiful.font_name .. "bold 9",
                                    widget = wibox.widget.textbox
                                })
                                local pw_display = wibox.widget {
                                    markup = helpers.colorize_text("Password: ", beautiful.xcolor3),
                                    font = beautiful.font_name .. "medium 8",
                                    valign = "center",
                                    widget = wibox.widget.textbox
                                }
                                wifi_networks_list:add(wibox.widget {
                                    {
                                        nil,
                                        pw_display,
                                        layout = wibox.layout.align.horizontal
                                    },
                                    margins = dpi(4),
                                    widget = wibox.container.margin
                                })
                                wifi_networks_list:add(wibox.widget {
                                    markup = helpers.colorize_text("[Enter] connect  [Esc] cancel", beautiful.xcolor5),
                                    font = beautiful.font_name .. "medium 6",
                                    widget = wibox.widget.textbox
                                })

                                awful.keygrabber.run(function(mod, key, event)
                                    if event ~= "press" then return end
                                    if key == "Return" then
                                        awful.keygrabber.stop()
                                        wifi_pw_active = false
                                        if wifi_pw_buf ~= "" then
                                            wifi_networks_list:reset()
                                            wifi_networks_list:add(wibox.widget {
                                                markup = helpers.colorize_text("Connecting...", beautiful.xcolor3),
                                                font = beautiful.font_name .. "medium 8",
                                                widget = wibox.widget.textbox
                                            })
                                            awful.spawn.easy_async_with_shell("nmcli device wifi connect '" .. shell_escape(ssid) .. "' password '" .. shell_escape(wifi_pw_buf) .. "' 2>&1", function(stdout)
                                                local level, msg = wifi_parse_error(stdout)
                                                if level then
                                                    naughty.notify({title = "WiFi Error", text = msg, timeout = 5, bg = beautiful.xcolor1})
                                                else
                                                    naughty.notify({title = "WiFi", text = "Conectado a " .. ssid, timeout = 3, bg = beautiful.xcolor2})
                                                end
                                                wifi_scan()
                                            end)
                                        else
                                            wifi_scan()
                                        end
                                        return true
                                    elseif key == "Escape" then
                                        awful.keygrabber.stop()
                                        wifi_pw_active = false
                                        wifi_scan()
                                        return true
                                    elseif key == "BackSpace" then
                                        wifi_pw_buf = wifi_pw_buf:sub(1, -2)
                                        pw_display.markup = helpers.colorize_text("Password: ", beautiful.xcolor3) .. helpers.colorize_text(string.rep("●", #wifi_pw_buf), beautiful.xforeground)
                                    elseif #key == 1 then
                                        wifi_pw_buf = wifi_pw_buf .. key
                                        pw_display.markup = helpers.colorize_text("Password: ", beautiful.xcolor3) .. helpers.colorize_text(string.rep("●", #wifi_pw_buf), beautiful.xforeground)
                                    end
                                end)
                            else
                                awful.spawn.easy_async_with_shell("nmcli device wifi connect '" .. shell_escape(ssid) .. "' 2>&1", function(stdout)
                                    local level, msg = wifi_parse_error(stdout)
                                    if level then
                                        naughty.notify({title = "WiFi Error", text = msg, timeout = 5, bg = beautiful.xcolor1})
                                    else
                                        naughty.notify({title = "WiFi", text = "Conectado a " .. ssid, timeout = 3, bg = beautiful.xcolor2})
                                    end
                                    wifi_scan()
                                end)
                            end
                        end)
                    ))

                    table.insert(wifi_rows, {row = row, signal = sig, connected = connected})
                end
            end

            table.sort(wifi_rows, function(a, b)
                if a.connected ~= b.connected then
                    return a.connected
                end
                return a.signal > b.signal
            end)

            local sorted = {}
            for _, item in ipairs(wifi_rows) do
                table.insert(sorted, item.row)
            end
            wifi_rows = sorted

            wifi_update_display()
        end)
    end

    local function wifi_update_status()
        awful.spawn.easy_async_with_shell("iwgetid -r 2>/dev/null", function(stdout)
            local ssid = stdout:gsub("^%s*(.-)%s*$", "%1")
            if ssid and ssid ~= "" then
                wifi_connected_ssid = ssid
                wifi_status_text.markup = helpers.colorize_text(ssid, beautiful.xcolor2)
                wifi_icon_w.markup = helpers.colorize_text("", beautiful.xcolor2)
                wifi_uptime_icon.markup = helpers.colorize_text("", beautiful.xcolor2)
            else
                wifi_connected_ssid = ""
                wifi_status_text.markup = helpers.colorize_text("Disconnected", beautiful.xcolor1)
                wifi_icon_w.markup = helpers.colorize_text("", beautiful.xcolor1)
                wifi_uptime_icon.markup = helpers.colorize_text("", beautiful.xcolor1)
            end
        end)
    end

    wifi_refresh_btn:connect_signal("mouse::enter", function()
        wifi_refresh_btn.markup = helpers.colorize_text("", beautiful.xcolor15)
    end)
    wifi_refresh_btn:connect_signal("mouse::leave", function()
        wifi_refresh_btn.markup = helpers.colorize_text("", beautiful.xcolor4)
    end)
    wifi_refresh_btn:buttons(gears.table.join(
        awful.button({}, 1, function()
            if wifi_pw_active then return end
            wifi_refresh_btn.markup = helpers.colorize_text("", beautiful.xcolor3)
            wifi_scan()
        end)
    ))

    local wifi_header = wibox.widget {
        wifi_icon_w,
        wifi_status_text,
        nil,
        wifi_refresh_btn,
        layout = wibox.layout.align.horizontal
    }

    local wifi_content = wibox.widget {
        {
            wifi_header,
            margins = dpi(4),
            widget = wibox.container.margin
        },
        wifi_networks_list,
        layout = wibox.layout.fixed.vertical
    }

    local wifi_boxed = create_boxed_widget(wifi_content, dpi(180), dpi(220), true)


    -- Stats tooltip (Wired)
    --------------------------

    local batt_boxed = create_boxed_widget(batt, dpi(50), dpi(110))
    local uptime_boxed = create_boxed_widget(uptime_container, dpi(170), dpi(50), true)
    local analog_clock_boxed = create_boxed_widget(analog_clock, dpi(110), dpi(110), true)

    -- Tooltip size
    local tooltip_height = dpi(420)
    local tooltip_width = dpi(200)

    local stats_tooltip = wibox({
        type = "dock",
        screen = s,
        height = tooltip_height,
        width = tooltip_width,
        shape = helpers.rrect(beautiful.tooltip_border_radius),
        bg = beautiful.transparent,
        ontop = true,
        visible = false
    })

    awful.placement.bottom_left(stats_tooltip, {
        margins = {
            left = 82,
            bottom = dpi(33)
        }
    })

    stats_tooltip:setup {
        {
            {
                {
                    {
                        date,
                        {
                            analog_clock_boxed,
                            batt_boxed,
                            layout = wibox.layout.fixed.horizontal
                        },
                        layout = wibox.layout.fixed.vertical
                    },
                    layout = wibox.layout.fixed.horizontal
                },
                {
                    uptime_boxed,
                    layout = wibox.layout.fixed.horizontal
                },
                wifi_boxed,
                layout = wibox.layout.fixed.vertical
            },
            margins = beautiful.tooltip_gap,
            widget = wibox.container.margin
        },
        shape = helpers.rrect(beautiful.tooltip_border_radius),
        bg = beautiful.tooltip_bg,
        widget = wibox.container.background
    }

    local inactivity_timer = gears.timer {
        timeout = 5,
        autostart = false,
        single_shot = true,
        callback = function()
            s.stats_tooltip_hide()
        end
    }

    stats_tooltip:connect_signal("mouse::enter", function()
        inactivity_timer:again()
    end)

    stats_tooltip:connect_signal("mouse::leave", function()
        inactivity_timer:again()
    end)

    stats_tooltip:connect_signal("property::visible", function()
        if stats_tooltip.visible then
            inactivity_timer:again()
        end
    end)

    s.stats_tooltip_show = function()
        local f = io.open("/proc/uptime", "r")
        if f then
            local line = f:read("*l")
            f:close()
            if line then
                local up_seconds = tonumber(line:match("^(%d+%.?%d*)"))
                if up_seconds then
                    local days = math.floor(up_seconds / 86400)
                    local hours = math.floor((up_seconds % 86400) / 3600)
                    local minutes = math.floor((up_seconds % 3600) / 60)
                    local text = days > 0 and string.format("%dd %dh %dm", days, hours, minutes)
                        or hours > 0 and string.format("%dh %dm", hours, minutes)
                        or string.format("%dm", minutes)
                    uptime_text.markup = helpers.colorize_text(text, beautiful.xcolor5)
                end
            end
        end
        wifi_update_status()
        wifi_scan()
        analog_clock_api.start()
        stats_tooltip.visible = true
        inactivity_timer:again()
    end

    s.stats_tooltip_hide = function()
        inactivity_timer:stop()
        if wifi_pw_active then
            awful.keygrabber.stop()
            wifi_pw_active = false
            wifi_pw_buf = ""
        end
        analog_clock_api.stop()
        stats_tooltip.visible = false
    end

    s.stats_tooltip_visible = function()
        return stats_tooltip.visible
    end

    s.stats_panel_toggle = function()
        if stats_tooltip.visible then
            s.stats_tooltip_hide()
        else
            s.stats_tooltip_show()
        end
    end
end

-- Global fallbacks: operan en la pantalla enfocada
_G.stats_panel_toggle = function()
    local s = awful.screen.focused()
    if s and s.stats_panel_toggle then
        s.stats_panel_toggle()
    end
end

_G.stats_tooltip_hide = function()
    local s = awful.screen.focused()
    if s and s.stats_tooltip_hide then
        s.stats_tooltip_hide()
    end
end

_G.stats_tooltip = {}
setmetatable(_G.stats_tooltip, {
    __index = function(t, k)
        if k == "visible" then
            local s = awful.screen.focused()
            return s and s.stats_tooltip_visible and s.stats_tooltip_visible()
        end
    end
})

return M
