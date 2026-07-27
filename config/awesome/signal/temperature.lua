-- Provides:
-- signal::temperature (temp_celsius)
local awful = require("awful")
local gears = require("gears")

local update_interval = 5

local temp_script = [[ bash -c '
ZONE="/sys/class/thermal/thermal_zone0/temp"
if [ -f "$ZONE" ]; then
    cat "$ZONE"
else
    echo "0"
fi
' ]]

gears.timer({
    timeout = update_interval,
    call_now = false,
    autostart = true,
    callback = function()
        awful.spawn.easy_async_with_shell(temp_script, function(stdout)
            local temp = tonumber(stdout)
            if temp then
                awesome.emit_signal("signal::temperature", math.floor(temp / 1000))
            end
        end)
    end
})

-- First read
gears.timer.start_new(2, function()
    awful.spawn.easy_async_with_shell(temp_script, function(stdout)
        local temp = tonumber(stdout)
        if temp then
            awesome.emit_signal("signal::temperature", math.floor(temp / 1000))
        end
    end)
    return false
end)
