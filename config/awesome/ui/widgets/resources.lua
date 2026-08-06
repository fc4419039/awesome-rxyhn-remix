local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local helpers = require("helpers")

local resources_wibox = nil
local resources_visible = false
local hide_timer = nil
local disk_widgets = {}
local disk_container = nil
local cached_disks = {}
local cached_batt = nil

local pos_file = "/tmp/awesome-resources-pos"

local colors = {
    cpu    = beautiful.xcolor6,
    ram    = beautiful.xcolor2,
    temp   = beautiful.xcolor1,
    disk   = beautiful.xcolor5,
    batt   = beautiful.deco_green or beautiful.xcolor2,
}

local function read_temp()
    local f = io.open("/sys/class/thermal/thermal_zone0/temp", "r")
    if f then
        local val = tonumber(f:read("*a"))
        f:close()
        if val then return math.floor(val / 1000) end
    end
    return 0
end

local function circular_gauge(icon, color, initial_value, max_value)
    local arc = wibox.widget{
        colors = {color},
        bg = beautiful.xcolor8 .. "88",
        value = initial_value,
        min_value = 0,
        max_value = max_value,
        thickness = dpi(6),
        paddings = dpi(4),
        start_angle = math.pi * 3 / 2,
        widget = wibox.container.arcchart
    }

    local value_text = wibox.widget{
        font = beautiful.font_name .. "bold 9",
        align = "center",
        valign = "center",
        markup = helpers.colorize_text(tostring(initial_value), color),
        widget = wibox.widget.textbox
    }

    local icon_w = wibox.widget{
        font = beautiful.font_name .. "11",
        markup = helpers.colorize_text(icon, color),
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }

    local label = wibox.widget{
        font = beautiful.font_name .. "bold 8",
        align = "center",
        valign = "center",
        markup = helpers.colorize_text("", beautiful.dashboard_fg),
        widget = wibox.widget.textbox
    }

    local w = wibox.widget{
        {
            {
                icon_w,
                nil,
                {
                    arc,
                    nil,
                    value_text,
                    layout = wibox.layout.stack
                },
                expand = "none",
                layout = wibox.layout.align.vertical
            },
            label,
            spacing = dpi(0),
            layout = wibox.layout.fixed.vertical
        },
        margins = dpi(1),
        widget = wibox.container.margin
    }

    arc.forced_width = dpi(60)
    arc.forced_height = dpi(60)

    return w, arc, value_text, label
end

-- Cachear batería desde el inicio
awesome.connect_signal("signal::battery", function(value)
    if not value or type(value) ~= "number" then return end
    cached_batt = value
end)

-- Cachear discos desde el inicio
awesome.connect_signal("signal::disk", function(disks)
    cached_disks = disks
    if not disk_container then return end
    for _, d in ipairs(disks) do
        if not disk_widgets[d.mount] then
            local color = colors.disk
            if d.used_pct > 90 then color = beautiful.deco_red or beautiful.xcolor1
            elseif d.used_pct > 75 then color = beautiful.deco_yellow or beautiful.xcolor3 end
            local box, arc, txt, lbl = circular_gauge("", color, d.used_pct, 100)
            local short = d.mount == "/" and "SYSTEM" or (d.mount:match("/([^/]+)$") or d.mount)
            lbl.markup = helpers.colorize_text(short:upper(), beautiful.dashboard_fg)
            txt.markup = helpers.colorize_text(d.used_pct .. "%", color)
            disk_widgets[d.mount] = {box = box, arc = arc, txt = txt}
            disk_container:add(box)
        else
            local w = disk_widgets[d.mount]
            local color = colors.disk
            if d.used_pct > 90 then color = beautiful.deco_red or beautiful.xcolor1
            elseif d.used_pct > 75 then color = beautiful.deco_yellow or beautiful.xcolor3 end
            w.arc.value = d.used_pct
            w.arc.colors = {color}
            w.txt.markup = helpers.colorize_text(d.used_pct .. "%", color)
        end
    end
end)

local function get_bg_color()
    return "#0d0d1a"
end

local function save_pos(w)
    if not w then return end
    local g = w:geometry()
    local f = io.open(pos_file, "w")
    if f then
        f:write(g.x .. "," .. g.y .. "," .. g.width .. "," .. g.height)
        f:close()
    end
end

local function load_pos()
    local f = io.open(pos_file, "r")
    if f then
        local saved = f:read("*a")
        f:close()
        local sx, sy, sw, sh = saved:match("(-?%d+),(-?%d+),(-?%d+),(-?%d+)")
        if sx then
            return {x = tonumber(sx), y = tonumber(sy), width = tonumber(sw), height = tonumber(sh)}
        end
    end
    return nil
end

local function start_move(w)
    local g = w:geometry()
    local mx, my = mouse.coords().x, mouse.coords().y
    local ox, oy = g.x - mx, g.y - my
    mousegrabber.run(function(m)
        if not m.buttons[1] then
            save_pos(w)
            return false
        end
        w.x = ox + m.x
        w.y = oy + m.y
        return true
    end, "fleur")
end

local function create()
    if resources_wibox then return end

    local bg_color = get_bg_color()
    local screen = awful.screen.focused()
    local cpu_value = 0
    local ram_used = 0
    local ram_total = 0

    local batt_init = cached_batt or 50
    local temp_init = read_temp()
    local cpu_box, cpu_arc, cpu_text, cpu_label = circular_gauge("", colors.cpu, 0, 100)
    local ram_box, ram_arc, ram_text, ram_label = circular_gauge("", colors.ram, 0, 100)
    local temp_box, temp_arc, temp_text, temp_label = circular_gauge("", colors.temp, temp_init, 100)
    local batt_box, batt_arc, batt_text, batt_label = circular_gauge("", colors.batt, batt_init, 100)

    cpu_label.markup = helpers.colorize_text("CPU", beautiful.dashboard_fg)
    ram_label.markup = helpers.colorize_text("RAM", beautiful.dashboard_fg)
    temp_label.markup = helpers.colorize_text("TEMP", beautiful.dashboard_fg)
    batt_label.markup = helpers.colorize_text("BATT", beautiful.dashboard_fg)

    if cached_batt then
        local c = colors.batt
        if cached_batt < 20 then c = beautiful.deco_red or beautiful.xcolor1
        elseif cached_batt < 40 then c = beautiful.deco_yellow or beautiful.xcolor3 end
        batt_arc.value = cached_batt
        batt_arc.colors = {c}
        batt_text.markup = helpers.colorize_text(cached_batt .. "%", c)
    end

    awesome.connect_signal("signal::cpu", function(v)
        cpu_value = v or 0
        cpu_arc.value = cpu_value
        cpu_text.markup = helpers.colorize_text(cpu_value .. "%", colors.cpu)
    end)

    awesome.connect_signal("signal::ram", function(used, total)
        ram_used = used or 0
        ram_total = total or 1
        local pct = math.floor((ram_used / ram_total) * 100)
        ram_arc.value = pct
        local text = string.format("%.1fG", ram_used / 1024)
        ram_text.markup = helpers.colorize_text(text, colors.ram)
    end)

    local temp_timer = gears.timer{
        timeout = 2,
        autostart = false,
        callback = function()
            local t = read_temp()
            local color = colors.temp
            if t > 80 then color = beautiful.deco_red or beautiful.xcolor1
            elseif t > 65 then color = beautiful.deco_yellow or beautiful.xcolor3 end
            temp_arc.value = math.min(100, t)
            temp_arc.colors = {color}
            temp_text.markup = helpers.colorize_text(t .. "°C", color)
        end
    }

    temp_timer:start()
    temp_arc.value = math.min(100, temp_init)
    temp_text.markup = helpers.colorize_text(temp_init .. "°C", colors.temp)

    awesome.connect_signal("signal::battery", function(value)
        if not value or type(value) ~= "number" then return end
        cached_batt = value
        local c = colors.batt
        if value < 20 then c = beautiful.deco_red or beautiful.xcolor1
        elseif value < 40 then c = beautiful.deco_yellow or beautiful.xcolor3 end
        batt_arc.value = value
        batt_arc.colors = {c}
        batt_text.markup = helpers.colorize_text(value .. "%", c)
    end)

    disk_container = wibox.widget{spacing = dpi(10), layout = wibox.layout.fixed.horizontal}

    for _, d in ipairs(cached_disks) do
        local color = colors.disk
        if d.used_pct > 90 then color = beautiful.deco_red or beautiful.xcolor1
        elseif d.used_pct > 75 then color = beautiful.deco_yellow or beautiful.xcolor3 end
        local box, arc, txt, lbl = circular_gauge("", color, d.used_pct, 100)
        local short = d.mount == "/" and "SYSTEM" or (d.mount:match("/([^/]+)$") or d.mount)
        lbl.markup = helpers.colorize_text(short:upper(), beautiful.dashboard_fg)
        txt.markup = helpers.colorize_text(d.used_pct .. "%", color)
        disk_widgets[d.mount] = {box = box, arc = arc, txt = txt}
        disk_container:add(box)
    end

    local content = wibox.widget{
        {
            {
                text = "System Resources",
                font = beautiful.font_name .. "bold 12",
                align = "center",
                valign = "center",
                widget = wibox.widget.textbox
            },
            {
                cpu_box,
                ram_box,
                temp_box,
                batt_box,
                spacing = dpi(8),
                layout = wibox.layout.fixed.horizontal
            },
            {
                disk_container,
                spacing = dpi(8),
                layout = wibox.layout.fixed.horizontal
            },
            spacing = dpi(6),
            layout = wibox.layout.fixed.vertical
        },
        margins = dpi(12),
        widget = wibox.container.margin
    }

    resources_wibox = wibox({
        type = "dialog",
        screen = screen,
        height = dpi(300),
        width = dpi(340),
        shape = helpers.rrect(dpi(14)),
        bg = "#0d0d1a",
        ontop = true,
        visible = false,
        border_width = dpi(2),
        border_color = "#06b6d4",
    })

    local saved_pos = load_pos()
    if saved_pos then
        resources_wibox:geometry(saved_pos)
    else
        awful.placement.centered(resources_wibox, {honor_workarea = true})
        save_pos(resources_wibox)
    end

    resources_wibox:setup{
        content,
        bg = "#0d0d1a",
        shape = helpers.rrect(dpi(14)),
        widget = wibox.container.background
    }

    resources_wibox:buttons(gears.table.join(
        awful.button({"Mod4"}, 1, function() start_move(resources_wibox) end)
    ))

    resources_wibox:connect_signal("mouse::enter", function()
        if hide_timer then
            hide_timer:stop()
            hide_timer = nil
        end
    end)

    resources_wibox:connect_signal("mouse::leave", function()
        if resources_visible then
            hide_timer = gears.timer.start_new(3, function()
                toggle_resources()
                return false
            end)
        end
    end)
end

function toggle_resources()
    if not resources_wibox then
        local ok, err = pcall(create)
        if not ok then
            local naughty = require("naughty")
            naughty.notify({
                title = i18n.tr("widget.resources_error"),
                text = tostring(err),
                timeout = 10,
            })
            local f = io.open("/tmp/awesome-resources-error.log", "a")
            if f then
                f:write(os.date("%H:%M:%S") .. " " .. tostring(err) .. "\n")
                f:write(debug.traceback() .. "\n\n")
                f:close()
            end
            return
        end
    end

    if resources_visible then
        resources_wibox.visible = false
        resources_visible = false
        if hide_timer then
            hide_timer:stop()
            hide_timer = nil
        end
    else
        local s = awful.screen.focused()
        if not s then return end
        local saved_pos = load_pos()
        if saved_pos then
            resources_wibox:geometry(saved_pos)
        else
            awful.placement.centered(resources_wibox, {honor_workarea = true})
        end
        resources_wibox.visible = true
        resources_visible = true
        hide_timer = gears.timer.start_new(5, function()
            if resources_visible then
                toggle_resources()
            end
            return false
        end)
    end
end

_G.toggle_resources = toggle_resources

return {toggle = toggle_resources}
