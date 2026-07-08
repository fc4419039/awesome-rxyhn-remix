-- Provides:
-- signal::volume
--     percentage (integer)
--     muted (boolean)
local awful = require("awful")
local gears = require("gears")

local volume_old = -1
local muted_old = -1

local function emit_volume_info()
    -- Usa wpctl (WirePlumber) en vez de pactl para no agotar conexiones de pipewire-pulse
    awful.spawn.easy_async_with_shell("wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null", function(stdout)
        local volume = stdout and stdout:match("([%d%.]+)")
        local volume_int = volume and math.floor(tonumber(volume) * 100 + 0.5) or 0
        local muted = stdout and stdout:match("%[MUTED%]") ~= nil
        local muted_int = muted and 1 or 0

        if volume_int ~= volume_old or muted_int ~= muted_old then
            awesome.emit_signal("signal::volume", volume_int, muted)
            volume_old = volume_int
            muted_old = muted_int
        end
    end)
end

-- Ejecutar una vez al inicio para inicializar el widget/notificación
emit_volume_info()

-- Timer de polling: verificar cambios de volumen cada 0.5s vía wpctl
-- (evita pactl subscribe que agota las conexiones de pipewire-pulse)
local volume_timer = gears.timer {
    timeout = 0.5,
    autostart = true,
    call_now = false,
    callback = emit_volume_info
}

-- Matar procesos pactl subscribe que hayan quedado huérfanos
awful.spawn.with_shell("pkill -f 'pactl subscribe' 2>/dev/null; exit 0")

