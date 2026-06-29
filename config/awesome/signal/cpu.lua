-- Provides:
-- signal::cpu
--      used percentage (integer)
local awful = require("awful")
local gears = require("gears")

local update_interval = 5

local prev_total, prev_idle

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

    if prev_total and prev_idle then
        local dtotal = total - prev_total
        local didle = idle - prev_idle
        if dtotal > 0 then
            awesome.emit_signal("signal::cpu", math.floor((dtotal - didle) * 100 / dtotal))
        end
    end

    prev_total = total
    prev_idle = idle
end

gears.timer({
    timeout = update_interval,
    call_now = false,
    autostart = true,
    callback = read_cpu
})

-- Delay first read so UI has time to connect signal listeners
gears.timer.start_new(1, function()
    read_cpu()
    return false
end)
