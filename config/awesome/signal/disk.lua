-- Provides:
-- signal::disk
--      disks (table of {mount, used_pct, total_gb, used_gb})
local awful = require("awful")
local gears = require("gears")

local update_interval = 30

local function read_disks()
    awful.spawn.easy_async_with_shell(
        "lsblk -nlo NAME,TYPE,MOUNTPOINT 2>/dev/null | awk '$2==\"part\" && $3!=\"\"{print $3}' | while read m; do "
        .. "df -k \"$m\" 2>/dev/null | tail -1 | awk '{print $6, $5, $2, $3}' | sed 's/%//g'; "
        .. "done",
        function(stdout)
            local disks = {}
            for line in stdout:gmatch("[^\n]+") do
                local mount, pct, total_k, used_k = line:match("^(%S+)%s+(%d+)%s+(%d+)%s+(%d+)")
                if mount and pct then
                    table.insert(disks, {
                        mount = mount,
                        used_pct = tonumber(pct) or 0,
                        total_gb = total_k and math.floor(tonumber(total_k) / 1048576 * 10 + 0.5) / 10 or 0,
                        used_gb = used_k and math.floor(tonumber(used_k) / 1048576 * 10 + 0.5) / 10 or 0,
                    })
                end
            end
            if #disks > 0 then
                awesome.emit_signal("signal::disk", disks)
            end
        end
    )
end

gears.timer({
    timeout = update_interval,
    call_now = false,
    autostart = true,
    callback = read_disks
})

gears.timer.start_new(1, function()
    read_disks()
    return false
end)
