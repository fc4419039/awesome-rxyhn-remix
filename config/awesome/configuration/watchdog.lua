-- Global UI Watchdog (versión robusta)
-- Monitorea wibar, dashboard, notif_center, tooltip por screen
-- Solo alerta si widget EXISTE pero está roto (no si está oculto o no creado)
local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local helpers = require("helpers")

local watchdog_timer = nil
local attempts = {}
local grace_period = 60  -- segundos tras arranque antes de empezar a chequear
local started_at = os.time()

local function log(msg)
    local f = io.open("/tmp/awesome-watchdog.log", "a")
    if f then
        f:write(os.date("%H:%M:%S") .. " " .. msg .. "\n")
        f:close()
    end
end

local function get_wibar(s) return s and s.mywibar end
local function get_dashboard(s) return s and s.dashboard end
local function get_notif_center(s) return s and s.notif_center_wibox end
local function get_tooltip(s) return s and s.stats_tooltip_show end

-- Un widget está "roto" si EXISTE (no es nil) pero es inválido
local function is_broken(widget, name)
    if not widget then return false end  -- no existe aún = no está roto (lazy load)
    if name == "tooltip" then return type(widget) ~= "function" end
    return not widget.valid
end

-- Wibar: solo roto si existe pero inválido. Visible=false es normal (fullscreen, Ctrl+F)
-- Dashboard/NotifCenter/Tooltip: rotos si existen pero inválidos

local function recreate_wibar(s)
    log("Recreating wibar for screen " .. (s.index or "?"))
    if s._wibar_setup then
        pcall(function()
            if s.mywibar then
                s.mywibar.visible = false
                s.mywibar:remove()
            end
            s.mywibar = awful.wibar({
                type = "dock", position = "left", screen = s,
                height = s.geometry.height - dpi(30), width = dpi(44),
                shape = helpers.rrect(beautiful.border_radius),
                bg = beautiful.wibar_bg, ontop = true, visible = true,
            })
            s.mywibar.x = s.geometry.x + dpi(10)
            s.mywibar:setup(s._wibar_setup)
            if s._wibar_update_padding then s._wibar_update_padding(true) end
        end)
        return true
    end
    return false
end

local function recreate_dashboard(s)
    log("Recreating dashboard for screen " .. (s.index or "?"))
    local ok = pcall(function() require("ui.dashboard").create(s) end)
    return ok and s.dashboard_toggle
end

local function recreate_notif_center(s)
    log("Recreating notif_center for screen " .. (s.index or "?"))
    local ok = pcall(function()
        if s.notif_center_wibox then
            s.notif_center_wibox.visible = false
            s.notif_center_wibox:remove()
        end
        local nc = require('ui.notifs.notif-center')(s)
        s.notif_center_wibox = nc.wibox or nc
    end)
    return ok
end

local function recreate_tooltip(s)
    log("Recreating tooltip for screen " .. (s.index or "?"))
    return pcall(function() require("ui.tooltip").create(s) end)
end

local checks = {
    { name = "wibar",        get = get_wibar,        recreate = recreate_wibar },
    { name = "dashboard",    get = get_dashboard,    recreate = recreate_dashboard },
    { name = "notif_center", get = get_notif_center, recreate = recreate_notif_center },
    { name = "tooltip",      get = get_tooltip,      recreate = recreate_tooltip },
}

local function start()
    if watchdog_timer then watchdog_timer:stop() end

    watchdog_timer = gears.timer({
        timeout = 30,
        autostart = true,
        call_now = false,
        callback = function()
            -- Período de gracia: no chequear hasta 60s tras arranque
            if os.time() - started_at < grace_period then return end

            for s in screen do
                if s.valid then
                    for _, check in ipairs(checks) do
                        local key = s.index .. ":" .. check.name
                        local widget = check.get(s)

                        if is_broken(widget, check.name) then
                            attempts[key] = (attempts[key] or 0) + 1
                            log("WATCHDOG: " .. key .. " BROKEN (attempt " .. attempts[key] .. ")")

                            if attempts[key] <= 3 then
                                check.recreate(s)
                            elseif attempts[key] == 4 then
                                log("WATCHDOG: " .. key .. " failed 3x → awesome.restart()")
                                awesome.restart()
                            end
                        else
                            -- sano (o no existe aún por lazy load)
                            attempts[key] = 0
                        end
                    end
                end
            end
        end
    })
    log("Watchdog started (interval: 30s, grace: " .. grace_period .. "s)")
end

screen.connect_signal("removed", function(s)
    for _, check in ipairs(checks) do
        attempts[s.index .. ":" .. check.name] = nil
    end
end)

return { start = start }