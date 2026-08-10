local awful = require("awful")
local gfs = require('gears.filesystem')
local naughty = require("naughty")
local beautiful = require("beautiful")

local lock_screen = {}

local config_dir = gfs.get_configuration_dir()
package.cpath = package.cpath .. ";" .. config_dir .. "ui/lockscreen/lib/?.so;"

-- Buscar locker externo (más seguro - proceso separado)
local function find_external_locker()
    local lockers = {
        "xsecurelock",
        "i3lock",
        "slock",
        "physlock",
        "swaylock",
    }
    for _, locker in ipairs(lockers) do
        local handle = io.popen("which " .. locker .. " 2>/dev/null")
        if handle then
            local result = handle:read("*a")
            handle:close()
            if result and result ~= "" then
                return locker
            end
        end
    end
    return nil
end

local external_locker = find_external_locker()
lock_screen.using_external = external_locker ~= nil
lock_screen.external_locker = external_locker

-- Archivo para saber si ya mostramos la notificación
local notified_file = gfs.get_cache_dir() .. "/lockscreen_notified"

local function already_notified()
    local f = io.open(notified_file, "r")
    if f then f:close(); return true end
    return false
end

local function mark_notified()
    local f = io.open(notified_file, "w")
    if f then f:close() end
end

lock_screen.init = function()
    if external_locker then
        -- Usar locker externo (seguro: proceso separado con X11 grab real)
        lock_screen.authenticate = function(_)
            return true -- El locker externo maneja la autenticación
        end
        
        lock_screen.show = function()
            -- Spawn locker externo
            awful.spawn(external_locker, false)
        end
        
        -- Mostrar notificación solo la primera vez
        if not already_notified() then
            naughty.notify({
                title = "Lockscreen",
                text = "Usando locker externo seguro: " .. external_locker,
                timeout = 3,
                bg = beautiful.xcolor2,
                fg = beautiful.xforeground
            })
            mark_notified()
        end
    else
        -- Fallback: PAM (menos seguro - corre en proceso de AwesomeWM)
        local ok, pam = pcall(require, "liblua_pam")
        if ok then
            lock_screen.authenticate = function(password)
                return pam.auth_current_user(password)
            end
        else
            -- SECURITY: Si no hay PAM, no se puede desbloquear
            lock_screen.authenticate = function(_)
                naughty.notify({
                    title = "Lockscreen Error",
                    text = "Módulo PAM no encontrado (liblua_pam). No se puede autenticar.\nInstala: luarocks install lua-pam\nO instala un locker externo: xsecurelock, i3lock, slock",
                    timeout = 15,
                    bg = beautiful.xcolor1,
                    fg = beautiful.xforeground
                })
                return false
            end
        end
        
        lock_screen.show = function()
            require("ui.lockscreen.lockscreen")
            lock_screen_show()
        end
        
        -- Cargar el lockscreen original solo si no hay locker externo
        require("ui.lockscreen.lockscreen")
        
        -- Mostrar notificación solo la primera vez
        if not already_notified() then
            naughty.notify({
                title = "Lockscreen",
                text = "⚠ Usando PAM (menos seguro). Instala xsecurelock o i3lock para mejor seguridad.",
                timeout = 5,
                bg = beautiful.xcolor3,
                fg = beautiful.xforeground
            })
            mark_notified()
        end
    end
end

return lock_screen