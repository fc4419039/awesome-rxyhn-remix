-- Provides:
-- signal::ram
--      used (integer - mega bytes)
--      total (integer - mega bytes)
local awful = require("awful")
local gears = require("gears")

local update_interval = 20

local function read_ram()
    local f = io.open("/proc/meminfo", "r")
    if not f then return end
    local total_kb, available_kb
    for line in f:lines() do
        if line:match("^MemTotal:") then
            total_kb = tonumber(line:match("(%d+)"))
        elseif line:match("^MemAvailable:") then
            available_kb = tonumber(line:match("(%d+)"))
        end
        if total_kb and available_kb then break end
    end
    f:close()
    if not total_kb or not available_kb then return end
    local total_mb = math.floor(total_kb / 1024)
    local used_mb = math.floor((total_kb - available_kb) / 1024)
    awesome.emit_signal("signal::ram", used_mb, total_mb)
end

gears.timer({
    timeout = update_interval,
    call_now = true,
    autostart = true,
    callback = read_ram
})
