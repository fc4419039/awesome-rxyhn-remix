local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local gears = require("gears")
local helpers = require("helpers")
local i18n = require("i18n")

local desktop_sysmon = {}

local function create_widget(s)
    if s.desktop_sysmon then return end
    local screen_geo = s.geometry
    local base_w = 270
    local base_h = 90

    local function read_temp()
        local f = io.open("/sys/class/thermal/thermal_zone0/temp", "r")
        if f then
            local val = tonumber(f:read("*a"))
            f:close()
            if val then return math.floor(val / 1000) end
        end
        return 0
    end

    local gauge_size = dpi(42)
    local icon_size = dpi(16)

    local cpu_color = beautiful.deco_cyan
    local ram_color = beautiful.deco_green
    local temp_color = beautiful.deco_yellow
    local disk_color = beautiful.deco_purple

    local function make_arc(color)
        return wibox.widget{
            colors = {color},
            bg = beautiful.xcolor8 .. "33",
            value = 0,
            min_value = 0,
            max_value = 100,
            thickness = dpi(4),
            paddings = dpi(4),
            start_angle = math.pi * 3 / 2,
            forced_width = gauge_size,
            forced_height = gauge_size,
            widget = wibox.container.arcchart
        }
    end

    local function make_val(color)
        return wibox.widget{
            font = beautiful.font_name .. "bold 8",
            align = "center",
            valign = "center",
            markup = helpers.colorize_text("--", color),
            forced_width = gauge_size,
            forced_height = gauge_size,
            widget = wibox.widget.textbox
        }
    end

    local cpu_arc = make_arc(cpu_color)
    local ram_arc = make_arc(ram_color)
    local temp_arc = make_arc(temp_color)
    local disk_arc = make_arc(disk_color)

    local cpu_val = make_val(cpu_color)
    local ram_val = make_val(ram_color)
    local temp_val = make_val(temp_color)
    local disk_val = make_val(disk_color)

    local function make_gauge_widget(icon, arc, val, label_text, color)
        local icon_w = wibox.widget{
            font = beautiful.icon_font_name .. "13",
            markup = helpers.colorize_text(icon, color),
            align = "center",
            valign = "center",
            forced_width = gauge_size,
            forced_height = icon_size,
            widget = wibox.widget.textbox
        }

        local arc_stack = wibox.widget{
            arc, val,
            layout = wibox.layout.stack
        }

        local label_w = wibox.widget{
            font = beautiful.font_name .. "6",
            align = "center",
            valign = "center",
            markup = helpers.colorize_text(label_text, color .. "99"),
            forced_width = gauge_size,
            forced_height = dpi(10),
            widget = wibox.widget.textbox
        }

        local glow = wibox.widget{
            {
                arc_stack,
                margins = dpi(6),
                widget = wibox.container.margin
            },
            bg = color .. "08",
            shape = gears.shape.circle,
            forced_width = gauge_size + dpi(12),
            forced_height = gauge_size + dpi(12),
            widget = wibox.container.background
        }

        return wibox.widget{
            {
                icon_w,
                glow,
                label_w,
                spacing = dpi(0),
                layout = wibox.layout.fixed.vertical
            },
            widget = wibox.container.place
        }
    end

    local gauges = wibox.widget{
        {
            make_gauge_widget("", cpu_arc, cpu_val, "CPU", cpu_color),
            make_gauge_widget("", ram_arc, ram_val, "RAM", ram_color),
            make_gauge_widget(" ", temp_arc, temp_val, "TEMP", temp_color),
            make_gauge_widget("", disk_arc, disk_val, "DISK", disk_color),
            spacing = dpi(4),
            layout = wibox.layout.fixed.horizontal
        },
        widget = wibox.container.place
    }

    awesome.connect_signal("signal::cpu", function(v)
        local c = cpu_color
        if v > 80 then c = beautiful.deco_red or beautiful.xcolor1
        elseif v > 60 then c = beautiful.deco_yellow or beautiful.xcolor3 end
        cpu_arc.value = v or 0
        cpu_arc.colors = {c}
        cpu_val.markup = helpers.colorize_text((v or 0) .. "%", c)
    end)

    awesome.connect_signal("signal::ram", function(used, total)
        local pct = total > 0 and math.floor((used / total) * 100) or 0
        local c = ram_color
        if pct > 80 then c = beautiful.deco_red or beautiful.xcolor1
        elseif pct > 60 then c = beautiful.deco_yellow or beautiful.xcolor3 end
        ram_arc.value = pct
        ram_arc.colors = {c}
        local text = string.format("%.1fG", used / 1024)
        ram_val.markup = helpers.colorize_text(text, c)
    end)

    local temp_timer = gears.timer{
        timeout = 3,
        autostart = true,
        callback = function()
            local t = read_temp()
            local c = temp_color
            if t > 80 then c = beautiful.deco_red or beautiful.xcolor1
            elseif t > 65 then c = beautiful.deco_yellow or beautiful.xcolor3 end
            temp_arc.value = math.min(100, t)
            temp_arc.colors = {c}
            temp_val.markup = helpers.colorize_text(t .. "°C", c)
        end
    }

    awesome.connect_signal("signal::disk", function(disks)
        if not disks or #disks == 0 then return end
        local d = nil
        for _, dsk in ipairs(disks) do
            if dsk.mount == "/" then d = dsk; break end
        end
        if not d then d = disks[1] end
        local c = disk_color
        if d.used_pct > 90 then c = beautiful.deco_red or beautiful.xcolor1
        elseif d.used_pct > 75 then c = beautiful.deco_yellow or beautiful.xcolor3 end
        disk_arc.value = d.used_pct
        disk_arc.colors = {c}
        disk_val.markup = helpers.colorize_text(d.used_pct .. "%", c)
    end)

    local container = wibox.widget{
        {
            gauges,
            margins = dpi(4),
            widget = wibox.container.margin
        },
        bg = "#00000000",
        widget = wibox.container.background
    }

    local current_scale = 1
    local pos_file = os.getenv("HOME") .. "/.config/awesome/.desktop-sysmon-pos-" .. s.index

    local w = wibox{
        type = "desktop",
        screen = s,
        width = dpi(base_w),
        height = dpi(base_h),
        x = screen_geo.x + dpi(80),
        y = screen_geo.y + screen_geo.height - dpi(200),
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
        local rfx = "right"
        local rfy = "bottom"
        if mx <= ox + edge then rfx = "left"
        elseif mx < ox + ow - edge then rfx = nil end
        if my <= oy + edge then rfy = "top"
        elseif my < oy + oh - edge then rfy = nil end
        if not rfx and not rfy then rfx = "right"; rfy = "bottom"
        elseif not rfx then rfx = "right"
        elseif not rfy then rfy = "bottom" end

        local cursor = "bottom_right_corner"
        mousegrabber.run(function(m)
            if not m.buttons[3] then save_pos(); return false end
            local dx, dy = m.x - mx, m.y - my
            local nw, nh = ow, oh
            local nx, ny = ox, oy
            if rfx == "left" then nw = math.max(dpi(160), ow - dx); nx = ox + (ow - nw)
            elseif rfx == "right" then nw = math.max(dpi(160), ow + dx) end
            if rfy == "top" then nh = math.max(dpi(40), oh - dy); ny = oy + (oh - nh)
            elseif rfy == "bottom" then nh = math.max(dpi(40), oh + dy) end
            w:geometry({x = nx, y = ny, width = nw, height = nh})
            return true
        end, cursor)
    end

    local active_menu = nil

    local function open_settings()
        if active_menu then active_menu:hide(); active_menu = nil; return end
        active_menu = awful.menu({
            items = {
                { i18n.tr("dw.increase"), function()
                    current_scale = math.min(2, current_scale + 0.1)
                    w:geometry({width = dpi(base_w * current_scale), height = dpi(base_h * current_scale)})
                end},
                { i18n.tr("dw.decrease"), function()
                    current_scale = math.max(0.5, current_scale - 0.1)
                    w:geometry({width = dpi(base_w * current_scale), height = dpi(base_h * current_scale)})
                end},
                { i18n.tr("dw.hide"), function()
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
            current_scale = tonumber(sw) / dpi(base_w)
        end
    end

    s.desktop_sysmon = w
end

screen.connect_signal("request::desktop_decoration", create_widget)

return desktop_sysmon
