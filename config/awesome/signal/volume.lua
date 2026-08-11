-- Provides:
-- signal::volume
--     percentage (integer)
--     muted (boolean)
-- signal::notifications_volume
--     percentage (integer)
--     muted (boolean)
local awful = require("awful")
local gears = require("gears")

local volume_old = -1
local muted_old = -1
local notif_volume_old = -1
local notif_muted_old = -1

local function emit_volume_info()
    -- Una sola llamada a pactl por tick: lee system_sink y notifications por nombre
    -- (explícito, no @DEFAULT_AUDIO_SINK@) sin abrir conexiones persistentes.
    awful.spawn.easy_async_with_shell("pactl list sinks 2>/dev/null", function(stdout)
        local sys_vol, sys_muted, notif_vol, notif_muted
        local current
        for block in (stdout .. "\n\n"):gmatch("(.-)\n\n") do
            local name = block:match("Name: ([^\n]+)")
            if name == "system_sink" then
                current = "sys"
            elseif name == "notifications" then
                current = "notif"
            else
                current = nil
            end
            if current then
                local vol = block:match("Volume:.-(%d+)%%")
                local muted = block:find("Mute: yes") ~= nil
                if current == "sys" then
                    sys_vol, sys_muted = tonumber(vol), muted
                else
                    notif_vol, notif_muted = tonumber(vol), muted
                end
            end
        end

        sys_vol = math.min(100, sys_vol or 0)
        sys_muted = sys_muted == true
        notif_vol = math.min(100, notif_vol or 0)
        notif_muted = notif_muted == true

        if sys_vol ~= volume_old or sys_muted ~= muted_old then
            awesome.emit_signal("signal::volume", sys_vol, sys_muted)
            volume_old = sys_vol
            muted_old = sys_muted
        end
        if notif_vol ~= notif_volume_old or notif_muted ~= notif_muted_old then
            awesome.emit_signal("signal::notifications_volume", notif_vol, notif_muted)
            notif_volume_old = notif_vol
            notif_muted_old = notif_muted
        end
    end)
end

-- Ejecutar una vez al inicio para inicializar el widget/notificación
emit_volume_info()

-- Timer de polling: verificar cambios de volumen cada 0.5s
local volume_timer = gears.timer {
    timeout = 0.5,
    autostart = true,
    call_now = false,
    callback = emit_volume_info
}

-- Matar procesos pactl subscribe que hayan quedado huérfanos
awful.spawn.with_shell("pkill -f 'pactl subscribe' 2>/dev/null; exit 0")
