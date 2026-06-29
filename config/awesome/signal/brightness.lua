-- Provides:
-- signal::brightness
--      percentage (integer)
local awful = require("awful")

-- Subscribe to backlight changes
-- Requires inotify-tools
local brightness_subscribe_script = [[
   bash -c "
   while (inotifywait -e modify /sys/class/backlight/?*/brightness -qq) do echo; done
"]]

local brightness_script = [[
   sh -c "
   brightnessctl i | grep -oP '\(\K[^%\)]+'
"]]

local emit_brightness_info = function()
    awful.spawn.with_line_callback(brightness_script, {
        stdout = function(line)
            local percentage = math.floor(tonumber(line) or 0)
            awesome.emit_signal("signal::brightness", percentage)
        end
    })
end

-- Run once to initialize widgets
emit_brightness_info()

-- Kill old inotifywait process de forma limpia
awful.spawn.easy_async_with_shell("pkill -f 'inotifywait -e modify /sys/class/backlight'", function ()
    -- Update brightness status with each line printed
    awful.spawn.with_line_callback(brightness_subscribe_script, {
        stdout = function(_)
            emit_brightness_info()
        end
    })
end)
