-- Lazy loader for heavy UI modules
-- Usage: local dashboard = require("ui.lazy").load("dashboard")
local gears = require("gears")
local cache = {}

local function load(name)
    if cache[name] then return cache[name] end

    local ok, module = pcall(require, "ui." .. name)
    if ok then
        cache[name] = module
        return module
    end

    -- Fallback: create minimal placeholder
    cache[name] = {
        create = function(s) end,
        toggle = function() end,
    }
    return cache[name]
end

local function preload(name)
    gears.timer.delayed_call(function()
        load(name)
    end)
end

return {
    load = load,
    preload = preload,
}