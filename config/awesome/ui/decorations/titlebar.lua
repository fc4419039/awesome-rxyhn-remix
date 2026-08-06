local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local helpers = require("helpers")
local i18n = require("i18n")


local function create_title_button(c, color_focus, color_unfocus)
    local tb = wibox.widget {
        forced_width = dpi(12),
        forced_height = dpi(12),
        bg = color_unfocus,
        shape = function(cr, w, h) gears.shape.circle(cr, w, h) end,
        widget = wibox.container.background
    }

    local function update()
        tb.bg = client.focus == c and color_focus or color_unfocus
    end
    update()

    c:connect_signal("focus", update)
    c:connect_signal("unfocus", update)

    tb:connect_signal("mouse::enter", function() tb.bg = color_focus end)
    tb:connect_signal("mouse::leave", update)

    return tb
end

local function setup_titlebar(c)
    if c.class == "firefox" or c.class == "Firefox" or c.class == "Navigator" then return end
    local buttons = gears.table.join(
        awful.button({}, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            if c.maximized then c.maximized = false end
            awful.mouse.client.move(c)
        end),
        awful.button({}, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    local close = create_title_button(c, beautiful.deco_red, beautiful.deco_gray)
    close:connect_signal("button::press", function() c:kill() end)

    local max = create_title_button(c, beautiful.deco_purple, beautiful.deco_gray)
    max:connect_signal("button::press", function() c.maximized = not c.maximized end)

    local float = create_title_button(c, beautiful.deco_blue, beautiful.deco_gray)
    float:connect_signal("button::press", function() awful.client.floating.toggle(c) end)

    local title_text = wibox.widget {
        text = c.name or "",
        font = (beautiful.font_name or "Sans ") .. "Bold 9",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }

    c:connect_signal("property::name", function()
        title_text.text = c.name or ""
    end)

    local vpn_icon = wibox.widget {
        font = "Symbols Nerd Font 12",
        markup = "",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }

    local vpn_tooltip = awful.tooltip {
        objects = { vpn_icon },
        text = i18n.tr("tb.vpn_checking"),
        mode = "outside",
        preferred_positions = { "bottom", "top" },
        margins = dpi(4)
    }

    local function update_vpn()
        awful.spawn.easy_async_with_shell(
            "ip -o link show 2>/dev/null | awk -F': ' '/tun[0-9]|tap[0-9]|wg[0-9]|vpn/ {print $2; found=1} END {if(!found) print \"disconnected\"}'",
            function(stdout)
                local iface = stdout and stdout:match("^([%w-]+)")
                if iface and iface ~= "disconnected" then
                    vpn_icon.markup = helpers.colorize_text("", beautiful.xcolor2)
                    vpn_tooltip.text = i18n.format("tb.vpn_connected", iface)
                else
                    vpn_icon.markup = helpers.colorize_text("", beautiful.xcolor1)
                    vpn_tooltip.text = i18n.tr("tb.vpn_disconnected")
                end
            end
        )
    end

    update_vpn()
    gears.timer {
        timeout = 30,
        autostart = true,
        call_now = false,
        callback = update_vpn
    }

    local ip_text = wibox.widget {
        font = beautiful.font_name .. "Bold 9",
        text = " ... ",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }

    local ip_tooltip = awful.tooltip {
        objects = { ip_text },
        text = i18n.tr("tb.public_ip"),
        mode = "outside",
        preferred_positions = { "bottom", "top" },
        margins = dpi(4)
    }

    local function update_ip()
        awful.spawn.easy_async_with_shell(
            "curl -s --max-time 5 ifconfig.me 2>/dev/null || echo '...'",
            function(stdout)
                local ip = stdout and stdout:match("([%d%.]+)")
                if ip then
                    ip_text.markup = helpers.colorize_text(ip, beautiful.xcolor6)
                    ip_tooltip.text = i18n.format("tb.public_ip_value", ip)
                end
            end
        )
    end

    update_ip()
    gears.timer {
        timeout = 300,
        autostart = true,
        call_now = false,
        callback = update_ip
    }

    local wifi_icon = wibox.widget {
        font = "Symbols Nerd Font 12",
        markup = "",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }

    local wifi_tooltip = awful.tooltip {
        objects = { wifi_icon },
        text = i18n.tr("tb.wifi_checking"),
        mode = "outside",
        preferred_positions = { "bottom", "top" },
        margins = dpi(4)
    }

    wifi_icon:connect_signal("button::press", function()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/network.sh")
    end)

    local function update_wifi()
        awful.spawn.easy_async_with_shell(
            "LC_ALL=C nmcli -t -f WIFI radio 2>/dev/null | grep -q enabled && echo 'on' || echo 'off'",
            function(stdout)
                local radio = stdout and stdout:match("(%w+)")
                if radio == "on" then
                    awful.spawn.easy_async_with_shell(
                        "LC_ALL=C nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | head -1 | cut -d: -f2-",
                        function(ssid_out)
                            local ssid = ssid_out and ssid_out:match("^(.+)$")
                            if ssid and ssid ~= "" then
                                wifi_icon.markup = helpers.colorize_text("", beautiful.deco_cyan)
                                wifi_tooltip.text = i18n.format("tb.wifi_ssid", ssid)
                            else
                                wifi_icon.markup = helpers.colorize_text("", beautiful.deco_red)
                                wifi_tooltip.text = i18n.tr("tb.wifi_disconnected")
                            end
                        end
                    )
                else
                    wifi_icon.markup = helpers.colorize_text("", beautiful.xcolor8)
                    wifi_tooltip.text = i18n.tr("tb.wifi_off")
                end
            end
        )
    end

    update_wifi()
    gears.timer {
        timeout = 30,
        autostart = true,
        call_now = false,
        callback = update_wifi
    }

    local right_container = wibox.widget {
        wifi_icon,
        ip_text,
        vpn_icon,
        spacing = dpi(8),
        layout = wibox.layout.fixed.horizontal
    }

    local right_container_margin = wibox.widget {
        right_container,
        left = dpi(6),
        right = dpi(12),
        widget = wibox.container.margin
    }

    local bar_bg = wibox.widget {
        {
            {
                {
                    {
                        close,
                        max,
                        float,
                        spacing = dpi(8),
                        layout = wibox.layout.fixed.horizontal
                    },
                    left = dpi(12),
                    widget = wibox.container.margin
                },
                {
                    title_text,
                    widget = wibox.container.place
                },
                right_container_margin,
                layout = wibox.layout.align.horizontal
            },
            margins = dpi(8),
            widget = wibox.container.margin
        },
        bg = "#0a1419e6",
        shape = helpers.prrect(beautiful.border_radius, true, true, false, false),
        widget = wibox.container.background
    }

    awful.titlebar(c, {
        position = "top",
        size = beautiful.titlebar_size,
        bg = "#0a1419e6"
    }):setup{
        bar_bg,
        buttons = buttons,
        layout = wibox.layout.flex.horizontal
    }
end

client.connect_signal("request::titlebars", setup_titlebar)

return { setup = setup_titlebar }

