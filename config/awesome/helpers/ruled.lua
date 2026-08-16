-- Wrapper para 'ruled' compatible con awesome estable 4.3 Y awesome-git.
-- En git, 'ruled' es un módulo propio de awesome (ruled.client/screen/tag/notification).
-- En 4.3 no existe: se emula sobre awful.rules (auto-aplicado vía
-- client.connect_signal("manage", awful.rules.apply)) y naughty.config.rules.
local awful = require("awful")
local naughty = require("naughty")

local ok, real = pcall(require, "ruled")
if ok and type(real) == "table" then
    return real
end

local ruled = {
    client = {},
    notification = {},
    screen = {},
    tag = {},
}

local function run_request_rules(_, sig, fn)
    if sig == "request::rules" then
        fn()
    end
end

ruled.client.connect_signal = run_request_rules
ruled.client.append_rule = function(rule)
    table.insert(awful.rules.rules, rule)
end

ruled.notification.connect_signal = run_request_rules
ruled.notification.append_rule = function(rule)
    table.insert(naughty.config.rules, rule)
end

ruled.screen.connect_signal = function() end
ruled.screen.append_rule = function() end
ruled.tag.connect_signal = function() end
ruled.tag.append_rule = function() end

return ruled
