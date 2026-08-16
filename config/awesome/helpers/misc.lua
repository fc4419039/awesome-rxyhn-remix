local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")

local misc = {}

function misc.resize_gaps(amt)
    local t = awful.screen.focused().selected_tag
    t.gap = t.gap + tonumber(amt)
    awful.layout.arrange(awful.screen.focused())
end

function misc.resize_padding(amt)
    local s = awful.screen.focused()
    local l = s.padding.left
    local r = s.padding.right
    local t = s.padding.top
    local b = s.padding.bottom
    s.padding = {
        left = l + amt,
        right = r + amt,
        top = t + amt,
        bottom = b + amt
    }
    awful.layout.arrange(awful.screen.focused())
end

function misc.find(rule)
    local function matcher(c) return awful.rules.match(c, rule) end
    local clients = client.get()
    local findex = gears.table.hasitem(clients, client.focus) or 1
    local start = gears.math.cycle(#clients, findex + 1)

    local matches = {}
    for c in awful.client.iterate(matcher, start) do
        matches[#matches + 1] = c
    end

    return matches
end

function misc.round(number, decimals)
    local power = 10 ^ decimals
    return math.floor(number * power) / power
end

return misc