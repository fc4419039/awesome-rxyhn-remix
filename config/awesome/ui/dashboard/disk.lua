local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local helpers = require("helpers")

local disk_text = wibox.widget{
    font = beautiful.font_name .. "medium 8",
    markup = helpers.colorize_text("Disk", beautiful.dashboard_box_fg),
    valign = "center",
    widget = wibox.widget.textbox
}

local disk_badge = wibox.widget{
    font = beautiful.font_name .. "medium 8",
    markup = helpers.colorize_text("/", beautiful.xcolor1),
    valign = "center",
    widget = wibox.widget.textbox
}

local disk_stat = wibox.widget{
    colors = {beautiful.deco_cyan},
    bg = beautiful.darker_bg,
    value = 5,
    min_value = 0,
    max_value = 100,
    thickness = dpi(5),
    rounded_edge = true,
    start_angle = math.pi * 3 / 2,
    widget = wibox.container.arcchart
}

local disk_used = wibox.widget{
    font = beautiful.font_name .. "bold 10",
    markup = "0%",
    valign = "bottom",
    widget = wibox.widget.textbox
}

local disk_total = wibox.widget{
    font = beautiful.font_name .. "bold 8",
    markup = helpers.colorize_text("/0G", beautiful.xcolor8),
    valign = "bottom",
    widget = wibox.widget.textbox
}

local disk_widget = wibox.widget{
    {
        disk_text,
        nil,
        disk_badge,
        expand = "none",
        layout = wibox.layout.align.horizontal
    },
    {
        {
            {
                disk_stat,
                reflection = {horizontal = true},
                widget = wibox.container.mirror
            },
            {
                nil,
                {
                    nil,
                    {
                        disk_used,
                        disk_total,
                        spacing = dpi(1),
                        layout = wibox.layout.fixed.horizontal
                    },
                    expand = "none",
                    layout = wibox.layout.align.vertical
                },
                expand = "none",
                layout = wibox.layout.align.horizontal
            },
            layout = wibox.layout.stack
        },
        margins = dpi(10),
        widget = wibox.container.margin
    },
    layout = wibox.layout.fixed.vertical
}

local current_mount = "/"

awesome.connect_signal("signal::disk", function(disks)
    local root = nil
    for _, d in ipairs(disks) do
        if d.mount == "/" then
            root = d
            break
        end
    end
    if not root then
        root = disks[1]
    end
    if not root then return end

    local pct = root.used_pct
    local total = root.total_gb
    local used = root.used_gb

    disk_stat.max_value = 100
    disk_stat.value = pct

    if pct > 90 then
        disk_stat.colors = {beautiful.xcolor1}
    elseif pct > 75 then
        disk_stat.colors = {beautiful.deco_yellow}
    else
        disk_stat.colors = {beautiful.deco_cyan}
    end

    disk_used.markup = pct .. "%"
    disk_total.markup = helpers.colorize_text("/" .. total .. "G", beautiful.xcolor8)
    current_mount = root.mount
    disk_badge.markup = helpers.colorize_text(root.mount, beautiful.xcolor1)
end)

disk_widget:buttons(gears.table.join(
    awful.button({}, 1, function()
        awful.spawn("thunar")
    end),
    awful.button({}, 3, function()
        awful.spawn.easy_async_with_shell("df -h " .. current_mount .. " | tail -1", function(out)
            local naughty = require("naughty")
            naughty.notify({
                title = "Disco " .. current_mount,
                text = out,
                timeout = 10,
                width = dpi(400),
            })
        end)
    end)
))

return disk_widget
