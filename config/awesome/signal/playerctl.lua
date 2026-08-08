local bling = require("module.bling")

-- El backend lib de bling no gestiona los players de Chromium/Opera GX
-- (instancias tipo "chromium.instanceXXXX") de forma fiable. Usamos el
-- backend CLI con la misma lista de players que el resto de widgets.
local ok, playerctl = pcall(bling.signal.playerctl.cli, { player = {"firefox", "spotify", "%any"} })
playerctl = ok and playerctl or { connect_signal = function() end }

return playerctl
