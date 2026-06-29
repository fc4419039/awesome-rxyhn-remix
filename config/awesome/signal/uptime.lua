-- Provides:
-- signal::uptime
--      up (string)
local awful = require("awful")
local gears = require("gears")

local update_interval = 60

local function format_uptime(seconds)
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    if days > 0 then
        return string.format("%dd %dh %dm", days, hours, minutes)
    elseif hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    else
        return string.format("%dm", minutes)
    end
end

local function read_uptime()
    local f = io.open("/proc/uptime", "r")
    if not f then return end
    local line = f:read("*l")
    f:close()
    if not line then return end
    local up_seconds = tonumber(line:match("^(%d+%.?%d*)"))
    if up_seconds then
        awesome.emit_signal("signal::uptime", format_uptime(up_seconds))
    end
end

gears.timer({
    timeout = update_interval,
    call_now = true,
    autostart = true,
    callback = read_uptime
})

