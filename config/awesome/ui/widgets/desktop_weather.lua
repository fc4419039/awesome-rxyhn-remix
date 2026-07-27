local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local gears = require("gears")
local helpers = require("helpers")

local desktop_weather = {}

local function create_widget(s)
    if s.desktop_weather then return end
    local screen_geo = s.geometry

    local icon_w = wibox.widget{
        font = "icomoon 42",
        markup = helpers.colorize_text("", beautiful.xcolor2),
        align = "center",
        valign = "center",
        forced_width = dpi(60),
        forced_height = dpi(50),
        widget = wibox.widget.textbox
    }

    local temp_w = wibox.widget{
        font = "Quicksand Light 24",
        markup = helpers.colorize_text("--°", beautiful.xforeground),
        align = "center",
        valign = "center",
        forced_height = dpi(30),
        widget = wibox.widget.textbox
    }

    local desc_w = wibox.widget{
        font = beautiful.font_name .. "9",
        markup = helpers.colorize_text("Loading...", beautiful.dashboard_fg),
        align = "center",
        valign = "center",
        forced_height = dpi(14),
        widget = wibox.widget.textbox
    }

    local sep = wibox.widget{
        forced_width = dpi(40),
        forced_height = dpi(1),
        shape = gears.shape.rounded_bar,
        color = beautiful.xcolor8 .. "44",
        widget = wibox.separator
    }

    local extra_w = wibox.widget{
        font = beautiful.font_name .. "8",
        markup = "",
        align = "center",
        valign = "center",
        forced_height = dpi(12),
        widget = wibox.widget.textbox
    }

    awesome.connect_signal("signal::weather", function(temperature, description, icon_markup, condition, humidity, wind_speed)
        local units = _G.weather_units or "metric"
        local symbol = units == "imperial" and "°F" or "°C"

        icon_w.markup = icon_markup or helpers.colorize_text("", beautiful.xcolor2)

        if not temperature or temperature == 999 then
            temp_w.markup = helpers.colorize_text("--°", beautiful.dashboard_fg)
            desc_w.markup = helpers.colorize_text("Sin datos", beautiful.dashboard_fg)
            extra_w.markup = ""
        else
            temp_w.markup = helpers.colorize_text(temperature .. symbol, beautiful.xforeground)
            desc_w.markup = helpers.colorize_text(description or "", beautiful.dashboard_fg)
            local parts = {}
            if humidity and humidity > 0 then
                parts[#parts+1] = "💧 " .. humidity .. "%"
            end
            if wind_speed and wind_speed > 0 then
                parts[#parts+1] = "🌬 " .. string.format("%.0f", wind_speed) .. " m/s"
            end
            extra_w.markup = helpers.colorize_text(table.concat(parts, "  "), beautiful.xcolor8)
        end
    end)

    local content = wibox.widget{
        icon_w, temp_w, desc_w, sep, extra_w,
        spacing = dpi(2),
        layout = wibox.layout.fixed.vertical
    }

    local container = wibox.widget{
        {
            content,
            margins = dpi(10),
            widget = wibox.container.margin
        },
        bg = "#00000000",
        widget = wibox.container.background
    }

    local pos_file = "/tmp/awesome-desktop-weather-pos-" .. s.index

    local w = wibox{
        type = "desktop",
        screen = s,
        width = dpi(140),
        height = dpi(150),
        x = screen_geo.x + dpi(80),
        y = screen_geo.y + dpi(100),
        bg = "#00000000",
        visible = true,
        border_width = 0,
        border_color = "#00000000",
        ontop = false,
        below = true,
        skip_taskbar = true,
        focusable = false
    }

    local function save_pos()
        local g = w:geometry()
        local f = io.open(pos_file, "w")
        if f then
            f:write(g.x .. "," .. g.y .. "," .. g.width .. "," .. g.height)
            f:close()
        end
    end

    local function start_move()
        local g = w:geometry()
        local mx, my = mouse.coords().x, mouse.coords().y
        local ox, oy = g.x - mx, g.y - my
        mousegrabber.run(function(m)
            if not m.buttons[1] then save_pos(); return false end
            w.x = ox + m.x
            w.y = oy + m.y
            return true
        end, "fleur")
    end

    local function start_resize()
        local g = w:geometry()
        local mx, my = mouse.coords().x, mouse.coords().y
        local ow, oh = g.width, g.height
        local ox, oy = g.x, g.y
        local edge = dpi(10)
        local rfx, rfy = "right", "bottom"
        if mx <= ox + edge then rfx = "left" elseif mx < ox + ow - edge then rfx = nil end
        if my <= oy + edge then rfy = "top" elseif my < oy + oh - edge then rfy = nil end
        if not rfx and not rfy then rfx = "right"; rfy = "bottom"
        elseif not rfx then rfx = "right" elseif not rfy then rfy = "bottom" end

        mousegrabber.run(function(m)
            if not m.buttons[3] then save_pos(); return false end
            local dx, dy = m.x - mx, m.y - my
            local nw, nh = ow, oh
            local nx, ny = ox, oy
            if rfx == "left" then nw = math.max(dpi(100), ow - dx); nx = ox + (ow - nw)
            elseif rfx == "right" then nw = math.max(dpi(100), ow + dx) end
            if rfy == "top" then nh = math.max(dpi(100), oh - dy); ny = oy + (oh - nh)
            elseif rfy == "bottom" then nh = math.max(dpi(100), oh + dy) end
            w:geometry({x = nx, y = ny, width = nw, height = nh})
            return true
        end, "bottom_right_corner")
    end

    local active_menu = nil

    local function open_settings()
        if active_menu then active_menu:hide(); active_menu = nil; return end
        active_menu = awful.menu({
            items = {
                { "Aumentar", function()
                    local g = w:geometry()
                    w:geometry({width = g.width + dpi(20), height = g.height + dpi(20)})
                    save_pos()
                end},
                { "Disminuir", function()
                    local g = w:geometry()
                    w:geometry({width = math.max(dpi(100), g.width - dpi(20)), height = math.max(dpi(100), g.height - dpi(20))})
                    save_pos()
                end},
                { "Ocultar", function()
                    w.visible = false
                end},
            },
            theme = { width = dpi(160), font = beautiful.font_name .. "10" }
        })
        active_menu:show({ coords = { x = mouse.coords().x, y = mouse.coords().y } })
    end

    container:buttons(gears.table.join(
        awful.button({}, 3, open_settings),
        awful.button({"Mod4"}, 1, start_move),
        awful.button({"Mod4"}, 3, start_resize)
    ))

    w:setup{
        container,
        widget = wibox.container.background
    }

    local f = io.open(pos_file, "r")
    if f then
        local saved = f:read("*a")
        f:close()
        local sx, sy, sw, sh = saved:match("(-?%d+),(-?%d+),(-?%d+),(-?%d+)")
        if sx then
            w:geometry({x = tonumber(sx), y = tonumber(sy), width = tonumber(sw), height = tonumber(sh)})
        end
    end

    s.desktop_weather = w
end

screen.connect_signal("request::desktop_decoration", create_widget)

return desktop_weather
