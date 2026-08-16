local awful = require("awful")
local gfs = require("gears.filesystem")

local state_dir = os.getenv("HOME") .. "/.cache/awesome"
local focus_file = state_dir .. "/focused-client-data"

-- Recarga estándar y confiable de AwesomeWM.
-- awesome.restart() preserva las ventanas (las re-adopta el servidor X)
-- y reconstruye la wibar con sus iconos. Sin superposiciones ni parpadeos raros.
local function restart()
    -- Guardar SIEMPRE el tag actual (1-5) + window_id si hay cliente enfocado
    local s = awful.screen.focused()
    local current_tag = s.selected_tag
    local tag_idx = current_tag and current_tag.index or 1

    local f = io.open(focus_file, "w")
    if f then
        -- Formato: window_id|0,tag_idx
        local win_id = (client.focus and client.focus.window) and tostring(client.focus.window) or "0"
        f:write(win_id .. "|" .. tostring(tag_idx))
        f:close()
    end
    awesome.restart()
end

return { restart = restart, focus_file = focus_file }
