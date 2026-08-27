local awful = require("awful")
local gears = require("gears")

local system = {}

local function sink_volume(sink, step)
    if step == 0 then
        awful.spawn.with_shell("pactl set-sink-mute " .. sink .. " toggle 2>/dev/null || true")
        return
    end
    local cmd = "s=\"" .. sink .. "\"; step=" .. step .. "\n" ..
        "cur=$(pactl get-sink-volume \"$s\" 2>/dev/null | grep -o '[0-9]*%' | head -1 | tr -d '%')\n" ..
        "cur=${cur:-0}\n" ..
        "tgt=$((cur + step))\n" ..
        "[ \"$tgt\" -gt 100 ] && tgt=100\n" ..
        "[ \"$tgt\" -lt 0 ] && tgt=0\n" ..
        "pactl set-sink-volume \"$s\" \"${tgt}%\" 2>/dev/null || true"
    awful.spawn.with_shell(cmd)
end

function system.volume_control(step)
    sink_volume("system_sink", step)
end

function system.notifications_volume(step)
    sink_volume("notifications", step)
end

function system.music_control(state)
    local cmd
    if state == "toggle" then
        cmd = "playerctl -p spotify,mpd play-pause"
    elseif state == "prev" then
        cmd = "playerctl -p spotify,mpd previous"
    elseif state == "next" then
        cmd = "playerctl -p spotify,mpd next"
    end
    if not cmd then return end
    awful.spawn.with_shell(cmd)
end

function system.fake_escape()
    root.fake_input('key_press', "Escape")
    root.fake_input('key_release', "Escape")
end

function system.remote_watch(command, interval, output_file, callback)
    local run_the_thing = function()
        awful.spawn.easy_async_with_shell(command.." | tee "..output_file, function(out) callback(out) end)
    end

    local function get_file_mtime()
        local f = io.popen("stat -c %Y " .. output_file .. " 2>/dev/null")
        if f then
            local result = tonumber(f:read("*a"))
            f:close()
            return result
        end
        return nil
    end

    local function read_file()
        local f = io.open(output_file, "r")
        if f then
            local content = f:read("*a")
            f:close()
            return content
        end
        return nil
    end

    local timer
    local function tick()
        local mtime = get_file_mtime()
        if not mtime then
            run_the_thing()
            return
        end

        local diff = os.time() - mtime
        if diff >= interval then
            run_the_thing()
        else
            local cached = read_file()
            if cached then callback(cached) end
            timer:stop()
            gears.timer.start_new(interval - diff, function()
                run_the_thing()
                timer:again()
            end)
        end
    end

    timer = gears.timer {
        timeout = interval,
        call_now = false,
        autostart = true,
        single_shot = false,
        callback = tick
    }
    tick()
end

return system