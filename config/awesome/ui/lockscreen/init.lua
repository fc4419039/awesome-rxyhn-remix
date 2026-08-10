local awful = require("awful")
local gfs = require('gears.filesystem')
local naughty = require("naughty")
local beautiful = require("beautiful")

local lock_screen = {}

local config_dir = gfs.get_configuration_dir()
package.cpath = package.cpath .. ";" .. config_dir .. "ui/lockscreen/lib/?.so;"

-- Watchdog: proceso separado que lanza un locker externo si AwesomeWM muere
-- estando bloqueado (crash, Ctrl+Super+R, kill, etc.). Ver lockscreen-watchdog.sh
local watchdog = os.getenv("HOME") .. "/.config/awesome/scripts/lockscreen-watchdog.sh"

-- Archivo de estado: marca que el bloqueo está activo. Si AwesomeWM muere
-- bloqueado y se reinicia, este archivo indica que seguimos bloqueados.
local function state_file()
    local cache = os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")
    return cache .. "/lockscreen/awesome-locked"
end

local env_file = (os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")) .. "/lockscreen/x-session-env"

local function is_locked_file()
    local f = io.open(state_file(), "r")
    if f then f:close(); return true end
    return false
end

-- Activa/desactiva el bloqueo del sistema (archivo de estado + watchdog).
lock_screen.set_locked = function(v)
    if v then
        local dir = state_file():match("^(.*)/[^/]+$")
        os.execute("mkdir -p '" .. dir .. "'")
        local h = io.open(state_file(), "w")
        if h then h:close() end
        local envf = io.open(env_file, "w")
        if envf then
            envf:write("DISPLAY=" .. (os.getenv("DISPLAY") or "") .. "\n")
            envf:write("XAUTHORITY=" .. (os.getenv("XAUTHORITY") or "") .. "\n")
            envf:close()
        end
        -- Cachear XAUTHORITY legible para el watchdog post-crash
        local xauth = os.getenv("XAUTHORITY")
        if xauth and xauth ~= "" then
            local cache_dir = env_file:match("^(.*)/[^/]+$")
            os.execute("cp '" .. xauth .. "' '" .. cache_dir .. "/xauth-cache' 2>/dev/null")
        end
        os.execute("setsid '" .. watchdog .. "' start >/dev/null 2>&1 &")
    else
        os.execute("'" .. watchdog .. "' stop")
        os.remove(env_file)
        os.remove(state_file())
    end
end

-- Hook llamado por lockscreen.lua al desbloquear correctamente
lock_screen_on_unlock = function()
    lock_screen.set_locked(false)
    if lock_screen.crash_recovered then
        -- Tras un crash, recargar Awesome para limpiar grab de teclas
        awful.spawn.with_shell("echo 'awesome.restart()' | awesome-client >/dev/null 2>&1")
        lock_screen.crash_recovered = nil
    end
end

-- Fail-secure: PAM falló en el lockscreen visual. Se lanza un locker externo
-- (slock/i3lock/xsecurelock) en un proceso a parte que impone un grab de
-- teclado real sobre el servidor X. Mientras awesome sigue activo con el
-- visual oculto, el locker externo mantiene la pantalla bloqueada y solo se
-- desbloquea con su propia autenticación. Cuando el usuario desbloquea el
-- locker externo (exit 0), se le avisa a awesome para restaurar el estado.
lock_screen.fall_back_to_external = function()
    if not lock_screen.external_locker then
        -- Sin locker externo no hay fail-secure. Avisar y mantener el visual.
        naughty.notify({
            title = "Lockscreen",
            text = "PAM falló y no hay locker externo instalado. La pantalla sigue bloqueada. Instala i3lock/slock/xsecurelock.",
            timeout = 8,
            bg = beautiful.xcolor1,
            fg = beautiful.xforeground
        })
        return
    end
    local locker = lock_screen.external_locker
    -- Construir el comando con flags apropiados para cada locker.
    -- i3lock necesita -n (nofork) para que easy_async_with_shell espere a su
    -- salida real (0 = desbloqueado con éxito) en lugar de retornar al instante.
    local cmd
    if locker == "i3lock" then
        cmd = string.format("%s -n -e", locker)
    elseif locker == "slock" then
        cmd = string.format("%s -m", locker)
    else
        cmd = locker
    end
    -- Lanzar el locker externo (i3lock/slock/xsecurelock) como proceso a parte.
    -- Este impone un grab de teclado real sobre el servidor X, ajena a awesome,
    -- de modo que la pantalla sólo se desbloquea con su propia autenticación.
    -- awful.spawn.easy_async_with_shell no bloquea el event loop de awesome y
    -- ejecuta el callback cuando el locker TERMINA: exit_code 0 significa que el
    -- usuario se desbloqueó con éxito, en cuyo caso liberamos el estado.
    -- Cualquier otra salida (fallo/violencia) deja el bloqueo activo.
    awful.spawn.easy_async_with_shell(
        string.format("%s >/dev/null 2>&1", cmd),
        -- callback: (stdout, stderr, exit_reason, exit_code)
        function(_stdout, _stderr, _exit_reason, exit_code)
            if exit_code == 0 then
                -- Desbloqueado a través del locker externo.
                if lock_screen_on_unlock then lock_screen_on_unlock() end
            end
        end
    )
end

-- Llamado internamente (por el callback del locker externo) cuando el usuario
-- desbloquea el locker externo con éxito.
lock_screen._external_unlocked = function()
    if lock_screen_on_unlock then lock_screen_on_unlock() end
end

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
    -- Si AwesomeWM murió estando bloqueado y fue reiniciado, el archivo de
    -- estado sigue presente: el watchdog ya debe estar lanzando un locker
    -- externo. Seguimos bloqueados.
    local recovered = is_locked_file()
    lock_screen.crash_recovered = recovered

    local external_locker = find_external_locker()
    lock_screen.using_external = external_locker ~= nil
    lock_screen.external_locker = external_locker

    -- PAM siempre es la autenticación primaria del lockscreen visual.
    -- Un locker externo (slock/i3lock/xsecurelock) solo se usa como
    -- fail-secure: si PAM rechaza la contraseña, el lockscreen visual
    -- lanza el locker externo (grab de teclado real en un proceso a parte)
    -- y cede el control. Ver lockscreen.lua (grab_password).
    local ok, pam = pcall(require, "liblua_pam")
    if ok then
        lock_screen.authenticate = function(password)
            return pam.auth_current_user(password)
        end
    else
        -- SECURITY: Si no hay PAM, no se puede autenticar contra el lockscreen.
        -- Notificación clara; el usuario no podrá desbloquear con este método.
        lock_screen.authenticate = function(_)
            naughty.notify({
                title = "Lockscreen Error",
                text = "Módulo PAM no encontrado (liblua_pam). No se puede autenticar.\nInstala: luarocks install lua-pam",
                timeout = 15,
                bg = beautiful.xcolor1,
                fg = beautiful.xforeground
            })
            return false
        end
    end

    -- Cargar el lockscreen visual (construye lock_screen_box y lock_screen_show)
    require("ui.lockscreen.lockscreen")

    lock_screen.show = function()
        lock_screen.set_locked(true)
        lock_screen_show()
    end

    if recovered then
        -- AwesomeWM volvió estando bloqueado: el watchdog ya lanza un locker
        -- externo. Re-bloqueamos visualmente con PAM también, por si el
        -- usuario desea desbloquear con este lockscreen. Si PAM falla,
        -- grab_password lanzará el locker externo.
        --
        -- Si el watchdog YA lanzó i3lock/slock, NO mostrar el visual (evita
        -- conflicto de keyboard grab). El locker externo mantiene bloqueada
        -- la pantalla hasta que el usuario se autentique.
        local locker_running = false
        local handle = io.popen("pgrep -x i3lock >/dev/null 2>&1 && echo yes || echo no")
        if handle then
            if handle:read("*l") == "yes" then locker_running = true end
            handle:close()
        end

        if not locker_running then
            naughty.notify({
                title = "Lockscreen",
                text = "Recuperado tras reinicio: re-bloqueando. Si cierra sesión o "
                    .. "falla PAM, el watchdog/ locker externo mantienen la pantalla bloqueada.",
                timeout = 5,
                bg = beautiful.xcolor3,
                fg = beautiful.xforeground
            })
            lock_screen.show()
        else
            -- El watchdog ya lanzó un locker externo: respetar su control
            naughty.notify({
                title = "Lockscreen",
                text = "Recuperado tras crash: locker externo ya está activo. "
                    .. "Desbloquéalo con tu contraseña.",
                timeout = 5,
                bg = beautiful.xcolor3,
                fg = beautiful.xforeground
            })
        end
    elseif not already_notified() then
        local msg
        if external_locker then
            msg = "Lockscreen visual + PAM activo. Si PAM falla, se lanza "
                .. external_locker .. " (bloqueo externo fail-secure)."
        else
            msg = "Usando PAM en el lockscreen visual.\nInstala slock/i3lock/"
                .. "xsecurelock para un bloqueo fail-secure en caso de fallo."
        end
        naughty.notify({
            title = "Lockscreen",
            text = msg,
            timeout = 5,
            bg = beautiful.xcolor2,
            fg = beautiful.xforeground
        })
        mark_notified()
    end
end

return lock_screen
