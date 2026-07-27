local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local beautiful = require("beautiful")

local update_interval = 30
local last_notified = 0

local bat_path = "/sys/class/power_supply/BAT0"
local ac_path = "/sys/class/power_supply/AC"

awful.spawn.easy_async_with_shell(
    "for p in /sys/class/power_supply/BAT*; do [ -f \"$p/capacity\" ] && echo \"$p\" && break; done",
    function(stdout)
        local found = stdout and stdout:match("^%s*(.-)%s*$")
        if found and found ~= "" then bat_path = found end
    end
)

awful.spawn.easy_async_with_shell(
    "for p in /sys/class/power_supply/AC* /sys/class/power_supply/ADP*; do [ -f \"$p/online\" ] && echo \"$p\" && break; done",
    function(stdout)
        local found = stdout and stdout:match("^%s*(.-)%s*$")
        if found and found ~= "" then ac_path = found end
    end
)

local function read_battery()
    awful.spawn.easy_async_with_shell("cat " .. bat_path .. "/capacity", function(stdout)
        local val = stdout and tonumber(stdout:match("%d+"))
        if val then
            awesome.emit_signal("signal::battery", val)
        end
    end)
end

local function read_charger()
    awful.spawn.easy_async_with_shell("cat " .. ac_path .. "/online", function(out)
        awesome.emit_signal("signal::charger", tonumber(out) == 1)
    end)
end

-- Battery low notifications
awesome.connect_signal("signal::battery", function(val)
    if val and val <= 15 and val ~= last_notified then
        awful.spawn.easy_async_with_shell("cat " .. ac_path .. "/online", function(out)
            if tonumber(out) ~= 1 then
                local urgency = val <= 5 and "critical" or "normal"
                local title = val <= 5 and "⚠️ Battery critical!" or "Battery low"
                local text = val <= 5 and "Shutting down soon..." or "Plug in the charger"
                naughty.notify{
                    title = title,
                    text = text .. " (" .. val .. "%)",
                    timeout = 10,
                    bg = val <= 5 and beautiful.xcolor1 or beautiful.xcolor3,
                    fg = beautiful.xforeground,
                    urgency = urgency,
                }
                last_notified = val
            end
        end)
    end
    if val and val > 15 then
        last_notified = 0
    end
end)

-- Battery timer
gears.timer({
    timeout = update_interval,
    call_now = true,
    autostart = true,
    callback = read_battery
})

-- Charger on startup
read_charger()

-- Listen for AC plug/unplug events
awful.spawn.easy_async_with_shell("pkill -f 'acpi_listen'", function()
    awful.spawn.with_line_callback("acpi_listen", {
        stdout = function(line)
            if line:find("ac_adapter") then
                read_charger()
            end
        end
    })
end)
