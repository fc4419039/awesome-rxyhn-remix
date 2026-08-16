local awful = require("awful")
local gfs = require("gears.filesystem")

local state_dir = os.getenv("HOME") .. "/.cache/awesome"
local focus_file = state_dir .. "/focused-client-data"

-- Recarga estándar y confiable de AwesomeWM.
-- awesome.restart() preserva las ventanas (las re-adopta el servidor X)
-- y reconstruye la wibar con sus iconos. Sin superposiciones ni parpadeos raros.
local function restart()
    -- Guardar window ID y etiqueta del cliente enfocado antes de reiniciar
    -- window ID (X11) es estable tras awesome.restart() para ventanas que sobreviven
    if client.focus and client.focus.window then
        local f = io.open(focus_file, "w")
        if f then
            local tag_idx = 1
            local tags = client.focus:tags()
            if tags and tags[1] then
                tag_idx = tags[1].index
            end
            f:write(tostring(client.focus.window) .. "," .. tostring(tag_idx))
            f:close()
        end
    else
        os.remove(focus_file)
    end
    awesome.restart()
end

return { restart = restart, focus_file = focus_file }
