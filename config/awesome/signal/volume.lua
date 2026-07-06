-- Provides:
-- signal::volume
--     percentage (integer)
--     muted (boolean)
local awful = require("awful")

local volume_old = -1
local muted_old = -1

local function emit_volume_info()
    -- Comando moderno y rápido compatible con PipeWire para obtener volumen y mute a la vez
    awful.spawn.easy_async_with_shell("pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null; pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null", function(stdout)

        -- Extraer el porcentaje de volumen (ej: 50%)
        local volume = stdout and stdout:match("(%d+)%%")
        local volume_int = tonumber(volume) or 0

        -- Extraer si está en mute (Mute: yes / Mute: no)
        local muted = stdout and stdout:match("Mute: yes") ~= nil
        local muted_int = muted and 1 or 0

        -- Solo enviar la señal si hubo un cambio real
        if volume_int ~= volume_old or muted_int ~= muted_old then
            awesome.emit_signal("signal::volume", volume_int, muted)
            volume_old = volume_int
            muted_old = muted_int
        end
    end)
end

-- Ejecutar una vez al inicio para inicializar el widget/notificación
emit_volume_info()

-- Script en bucle que duerme hasta que PipeWire detecte un cambio de volumen o de default sink
local volume_script = [[bash -c "LANG=C pactl subscribe 2>/dev/null | grep --line-buffered -E \"Event 'change' on (sink|server)\""]]

-- Matar solo pactl subscribe de monitoreo de volumen (no el de notification-router.sh)
awful.spawn.easy_async_with_shell("pkill -f 'pactl subscribe.*Event'", function()
    -- Escuchar en tiempo real cada evento de audio
    awful.spawn.with_line_callback(volume_script, {
        stdout = function(line)
            emit_volume_info()
        end
    })
end)

