local awful = require("awful")

-- Recarga estándar y confiable de AwesomeWM.
-- awesome.restart() preserva las ventanas (las re-adopta el servidor X)
-- y reconstruye la wibar con sus iconos. Sin superposiciones ni parpadeos raros.
local function restart()
    awesome.restart()
end

return { restart = restart }
