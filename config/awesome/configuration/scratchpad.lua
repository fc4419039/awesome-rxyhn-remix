local beautiful = require("beautiful")
local bling = require("module.bling")

local scratchpad = bling.module.scratchpad({
    command = "kitty --class Scratchpad",
    rule = { instance = "Scratchpad" },
    sticky = false,
    autoclose = false,
    floating = true,
    geometry = {
        x = beautiful.xresources.apply_dpi(200),
        y = beautiful.xresources.apply_dpi(80),
        width = beautiful.xresources.apply_dpi(900),
        height = beautiful.xresources.apply_dpi(600),
    },
    reapply = true,
})

return scratchpad
