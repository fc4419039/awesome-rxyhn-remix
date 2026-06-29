-- Provides:
-- signal::cpu
--      used percentage (integer)
local awful = require("awful")
local gears = require("gears")

local update_interval = 5

local function read_cpu()
    local f = io.open("/proc/stat", "r")
    if not f then return end
    local line = f:read("*l")
    f:close()
    if not line then return end
    local _, _, user, nice, sys, idle = line:find("^cpu%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")
    if not user then return end
    local total = user + nice + sys + idle
    if total == 0 then return end
    awesome.emit_signal("signal::cpu", math.floor((total - idle) * 100 / total))
end

-- Use timer + direct /proc/stat reading instead of vmstat (which blocks for 1s)
gears.timer({
    timeout = update_interval,
    call_now = true,
    autostart = true,
    callback = read_cpu
})
