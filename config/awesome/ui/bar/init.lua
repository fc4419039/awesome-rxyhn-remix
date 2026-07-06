-- Standard awesome library
local awful = require("awful")
local gears = require("gears")

-- Widget library
local wibox = require("wibox")

-- Theme handling library
local beautiful = require("beautiful")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

-- Rubato
local rubato = require("module.rubato")

-- Helpers
local helpers = require("helpers")

-- Función de seguridad para evitar crasheos por funciones globales no definidas
local function safe_run(func_name, ...)
    if _G[func_name] then _G[func_name](...) end
end

-- Helpers
-------------

local wrap_widget = function(widget)
    return {
        widget,
        margins = dpi(4),
        widget = wibox.container.margin
    }
end

-- Wibar
-----------

-- Variables globales por pantalla (para los handlers de señal que actualizan widgets)
local screen_batts = setmetatable({}, {__mode = "k"})
local screen_chargers = setmetatable({}, {__mode = "k"})

-- Función de lerp para color de batería
local function lerp_color(a, b, t)
    local function ch(h, i) return tonumber(h:sub(i, i+1), 16) end
    local r = math.floor(ch(a, 2) + (ch(b, 2) - ch(a, 2)) * t)
    local g = math.floor(ch(a, 4) + (ch(b, 4) - ch(a, 4)) * t)
    local bl = math.floor(ch(a, 6) + (ch(b, 6) - ch(a, 6)) * t)
    return string.format("#%02x%02x%02x", r, g, bl)
end

awesome.connect_signal("signal::battery", function(value)
    if not value or type(value) ~= "number" then return end
    local c2 = beautiful.deco_green or beautiful.xcolor2
    local c3 = beautiful.deco_yellow or beautiful.xcolor3
    local c1 = beautiful.deco_red or beautiful.xcolor1
    local fill_color

    if value > 20 then
        fill_color = c2
    else
        local t = value / 20
        fill_color = lerp_color(c1, c3, t)
    end

    for scr, data in pairs(screen_batts) do
        pcall(function()
            if data and data.batt then
                data.batt.colors = {fill_color}
                data.batt.value = value
            end
        end)
    end
end)

awesome.connect_signal("signal::charger", function(state)
    for scr, data in pairs(screen_chargers) do
        pcall(function()
            if data and data.charge_icon and data.charge_icon.visible ~= nil then
                data.charge_icon.visible = state
            end
        end)
    end
end)

-- Handlers de fullscreen/unmanage (conectados UNA sola vez)
client.connect_signal("property::fullscreen", function(c)
    for scr in screen do
        if scr._hide_for_client then
            scr._hide_for_client(c)
        end
    end
end)
client.connect_signal("property::maximized", function(c)
    for scr in screen do
        if scr._hide_for_client then
            scr._hide_for_client(c)
        end
    end
end)

client.connect_signal("unmanage", function()
    for scr in screen do
        if scr._on_unmanage then
            scr._on_unmanage()
        end
    end
end)

-- Wibar por pantalla
screen.connect_signal("request::desktop_decoration", function(s)

    -- dpi redondeado a entero (evita artifacts por posiciones fraccionales)
    local dpi = function(v) return math.floor(xresources.apply_dpi(v) + 0.5) end

    -- Pantalla de error segura
    local safe_pcall = function(f, ...)
        local ok, err = pcall(f, ...)
        if not ok then
            local log = io.open("/tmp/awesome-wibar-errors.log", "a")
            if log then
                log:write(os.date("%H:%M:%S") .. " " .. tostring(err) .. "\n")
                log:close()
            end
        end
    end

    -- Si ya existe wibar funcional, salir (evita recreación en hotplug)
    if s.mywibar then
        local ok, w = pcall(s.mywibar.get_widget, s.mywibar)
        if ok and w then return end
        -- Wibar existe pero no tiene widgets → limpiar y recrear
        pcall(function() s.mywibar.visible = false end)
        pcall(function() s.mywibar:remove() end)
        s.mywibar = nil
    end

    local ok_init, err_init = pcall(function()

    -- Launcher
    -------------

    local awesome_icon = wibox.widget {
        {
            widget = wibox.widget.imagebox,
            image = beautiful.awesome_logo,
            resize = true
        },
        margins = dpi(2),
        widget = wibox.container.margin
    }

    helpers.add_hover_cursor(awesome_icon, "hand2")

    -- Battery
    -------------

    local charge_icon = wibox.widget{
        bg = beautiful.xcolor8,
        widget = wibox.container.background,
        visible = false
    }

    local batt = wibox.widget{
        charge_icon,
        colors = {beautiful.xcolor2},
        bg = beautiful.xcolor8 .. "88",
        value = 50,
        min_value = 0,
        max_value = 100,
        thickness = dpi(4),
        paddings = dpi(2),
        start_angle = math.pi * 3 / 2,
        widget = wibox.container.arcchart
    }

    screen_batts[s] = {batt = batt}
    screen_chargers[s] = {charge_icon = charge_icon}

    -- Time
    ----------

    local hour = wibox.widget{
        font = beautiful.font_name .. "bold 12",
        format = "%I",
        align = "center",
        valign = "center",
        widget = wibox.widget.textclock
    }

    local min = wibox.widget{
        font = beautiful.font_name .. "bold 12",
        format = "%M",
        align = "center",
        valign = "center",
        widget = wibox.widget.textclock
    }

    local clock = wibox.widget{
        {
            {
                hour,
                min,
                spacing = dpi(3),
                layout = wibox.layout.fixed.vertical
            },
            top = dpi(3),
            bottom = dpi(3),
            widget = wibox.container.margin
        },
        bg = beautiful.lighter_bg,
        shape = helpers.rrect(beautiful.bar_radius),
        widget = wibox.container.background
    }

    -- Stats
    -----------

    local stats = wibox.widget{
        {
            wrap_widget(batt),
            clock,
            spacing = dpi(3),
            layout = wibox.layout.fixed.vertical
        },
        bg = beautiful.xcolor0,
        shape = helpers.rrect(beautiful.bar_radius),
        widget = wibox.container.background
    }

    -- Crear dashboard, tooltip y system menu por pantalla
    local ok_dash, err_dash = pcall(function() require("ui.dashboard").create(s) end)
    if not ok_dash then
        local f = io.open("/tmp/awesome-wibar-errors.log", "a")
        if f then f:write(os.date("%H:%M:%S") .. " DASHBOARD ERROR: " .. tostring(err_dash) .. "\n"); f:close() end
        error(err_dash)
    end
    local ok_tip, err_tip = pcall(function() require("ui.tooltip").create(s) end)
    if not ok_tip then
        local f = io.open("/tmp/awesome-wibar-errors.log", "a")
        if f then f:write(os.date("%H:%M:%S") .. " TOOLTIP ERROR: " .. tostring(err_tip) .. "\n"); f:close() end
        error(err_tip)
    end
    local ok_menu, err_menu = pcall(function() require("ui.system_menu")(s) end)
    if not ok_menu then
        local f = io.open("/tmp/awesome-wibar-errors.log", "a")
        if f then f:write(os.date("%H:%M:%S") .. " SYSTEM_MENU ERROR: " .. tostring(err_menu) .. "\n"); f:close() end
        error(err_menu)
    end

    stats:connect_signal("mouse::enter", function()
        stats.bg = beautiful.xcolor8
        if s.stats_tooltip_show then s.stats_tooltip_show() end
        awesome.emit_signal("stats::mouse_enter")
    end)

    stats:connect_signal("mouse::leave", function()
        stats.bg = beautiful.xcolor0
        awesome.emit_signal("stats::mouse_leave")
    end)

    -- Notification center
    -------------------------

    local notif_center = wibox({
        type = "dock",
        screen = s,
        height = s.geometry.height - dpi(50),
        width = dpi(280),
        shape = helpers.rrect(beautiful.notif_center_radius),
        ontop = true,
        visible = false
    })
    notif_center.y = dpi(25)

    local slide = rubato.timed{
        pos = s.geometry.x + dpi(-280),
        rate = 60,
        intro = 0.05,
        duration = 0.4,
        easing = rubato.quadratic,
        awestore_compat = true,
        subscribed = function(pos) notif_center.x = pos end
    }

    local notif_center_status = false

    local notif_center_hide_timer = nil

    slide.ended:subscribe(function()
        if notif_center_status then
            notif_center.visible = false
        end
    end)

    local notif_center_show = function()
        notif_center.visible = true
        slide:set(s.geometry.x + dpi(10) + dpi(44) + dpi(10))
        notif_center_status = false
        if notif_center_hide_timer then notif_center_hide_timer:stop() end
        notif_center_hide_timer = gears.timer.start_new(2, function()
            notif_center_hide()
            return false
        end)
    end

    local notif_center_hide = function()
        if notif_center_hide_timer then
            notif_center_hide_timer:stop()
            notif_center_hide_timer = nil
        end
        slide:set(s.geometry.x + dpi(-355))
        notif_center_status = true
    end

    notif_center:connect_signal("mouse::enter", function()
        if notif_center_hide_timer then
            notif_center_hide_timer:stop()
            notif_center_hide_timer = nil
        end
    end)

    notif_center:connect_signal("mouse::leave", function()
        if notif_center_hide_timer then notif_center_hide_timer:stop() end
        notif_center_hide_timer = gears.timer.start_new(2, function()
            notif_center_hide()
            return false
        end)
    end)

    local notif_center_toggle = function()
        if notif_center.visible then
            notif_center_hide()
        else
            notif_center_show()
        end
    end

    s.notif_center = require('ui.notifs.notif-center')(s)
    s.notif_center_wibox = notif_center

    local nc_content = wibox.widget{
        s.notif_center,
        margins = dpi(15),
        widget = wibox.container.margin
    }
    notif_center:set_widget(nc_content)

    local notif_center_button = wibox.widget{
        markup = helpers.colorize_text("", beautiful.xcolor4),
        font = beautiful.font_name .. "22",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }

    notif_center_button:connect_signal("mouse::enter", function()
        notif_center_button.markup = helpers.colorize_text("", beautiful.xcolor4 .. 55)
    end)

    notif_center_button:connect_signal("mouse::leave", function()
        notif_center_button.markup = helpers.colorize_text("", beautiful.xcolor4)
    end)

    notif_center_button:buttons(gears.table.join(
        awful.button({}, 1, function()
            notif_center_toggle()
        end)
    ))
    helpers.add_hover_cursor(notif_center_button, "hand2")

    -- Setup wibar
    -----------------

    s.mypromptbox = awful.widget.prompt()

    local layoutbox_buttons = gears.table.join(
        awful.button({}, 1, function() awful.layout.inc(1) end),
        awful.button({}, 3, function() awful.layout.inc(-1) end),
        awful.button({}, 4, function() awful.layout.inc(-1) end),
        awful.button({}, 5, function() awful.layout.inc(1) end)
    )

    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(layoutbox_buttons)

    local layoutbox = wibox.widget{
        s.mylayoutbox,
        margins = {bottom = dpi(7), left = dpi(6), right = dpi(6)},
        widget = wibox.container.margin
    }

    s.mywibar = awful.wibar({
        type = "dock",
        position = "left",
        screen = s,
        height = s.geometry.height - dpi(50),
        width = dpi(44),
        shape = helpers.rrect(beautiful.border_radius),
        bg = beautiful.wibar_bg,
        ontop = true,
        visible = true,
    })

    s.mywibar.x = s.geometry.x + dpi(10)

    awesome_icon:buttons(gears.table.join(
        awful.button({}, 1, function()
            if s.dashboard_toggle then s.dashboard_toggle() end
        end)
    ))

    -- Ajusta padding del workarea según visibilidad de la barra
    -- bar.x = dpi(10), strut.width = dpi(50) → workarea.left = padding + strut
    local function wibar_update_padding(visible)
        local p = { right = dpi(0), top = dpi(15), bottom = dpi(15) }
        p.left = visible and (dpi(10)) or 0
        s.padding = p
        awful.layout.arrange(s)
    end

    -- Toggle wibar con Ctrl+F
    s.wibar_visible = true
    _G["wibar_toggle"] = function()
        local fs = awful.screen.focused()
        if fs and fs.mywibar then
            fs.wibar_visible = not fs.wibar_visible
            fs.mywibar.visible = fs.wibar_visible
            local p = { right = dpi(0), top = dpi(15), bottom = dpi(15) }
            p.left = fs.wibar_visible and (dpi(10)) or 0
            fs.padding = p
            awful.layout.arrange(fs)
        end
    end

    local function hide_for_client(c)
        if c and c.valid and c.screen == s and s.mywibar then
            if c.fullscreen or c.maximized then
                s.mywibar.visible = false
                s.wibar_visible = false
                wibar_update_padding(false)
            else
                s.mywibar.visible = true
                s.wibar_visible = true
                wibar_update_padding(true)
            end
        end
    end

    -- Guardar referencias para los handlers globales (conectados UNA vez arriba)
    s._hide_for_client = function(c) safe_pcall(hide_for_client, c) end
    s._on_unmanage = function()
        safe_pcall(function()
            if s.mywibar and not s.mywibar.visible then
                local still_full = false
                for _, cl in ipairs(client.get(s)) do
                    if cl.valid and (cl.fullscreen or cl.maximized) then
                        still_full = true
                        break
                    end
                end
                if not still_full then
                    s.mywibar.visible = true
                    s.wibar_visible = true
                    wibar_update_padding(true)
                end
            end
        end)
    end

    -- Padding inicial (barra visible)
    wibar_update_padding(true)

    s.mytaglist = require("ui.widgets.pacman_taglist")(s)

    local taglist = wibox.widget{
        s.mytaglist,
        shape = beautiful.taglist_shape_focus,
        bg = beautiful.xcolor0,
        widget = wibox.container.background
    }

    -- Tasklist (client icons)
    local tasklist_buttons = gears.table.join(
        awful.button({}, 1, function(c)
            c:activate{context = "tasklist", action = "toggle_minimization"}
        end),
        awful.button({}, 2, function(c)
            c:activate{context = "tasklist", action = "toggle_minimization"}
        end),
        awful.button({}, 3, function()
            awful.menu.client_list{theme = {width = dpi(250)}}
        end),
        awful.button({}, 4, function()
            awful.client.focus.byidx(1)
        end),
        awful.button({}, 5, function()
            awful.client.focus.byidx(-1)
        end)
    )

    s.mytasklist = awful.widget.tasklist {
        screen = s,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
        layout = {
            spacing = dpi(4),
            layout = wibox.layout.fixed.vertical
        },
        widget_template = {
            {
                {
                    id = 'icon_role',
                    widget = wibox.widget.imagebox,
                    resize = true,
                },
                margins = dpi(3),
                widget = wibox.container.margin,
            },
            id = 'background_role',
            widget = wibox.container.background,
            create_callback = function(self, c, index, objects)
                self:connect_signal('mouse::enter', function()
                    if c.valid then
                        local title = c.name or "Unknown"
                        local class = c.class or ""
                        if self._tooltip then
                            self._tooltip.text = title .. "\n" .. class
                        else
                            self._tooltip = awful.tooltip({
                                objects = { self },
                                text = title .. "\n" .. class,
                            })
                        end
                    end
                end)
            end,
        },
    }

    s._wibar_setup = {
        {
            layout = wibox.layout.align.vertical,
            expand = "none",
            {
                awesome_icon,
                taglist,
                spacing = dpi(6),
                layout = wibox.layout.fixed.vertical
            },
            nil,
            {
                stats,
                notif_center_button,
                layoutbox,
                spacing = dpi(5),
                layout = wibox.layout.fixed.vertical
            }
        },
        margins = dpi(6),
        widget = wibox.container.margin
    }

    s.mywibar:setup(s._wibar_setup)

    end) -- pcall wrapper

    if not ok_init then
        local log_init = io.open("/tmp/awesome-wibar-errors.log", "a")
        if log_init then
            log_init:write(os.date("%H:%M:%S") .. " WIBAR ERROR: " .. tostring(err_init) .. "\n")
            log_init:close()
        end
        -- Limpiar wibar parcialmente creado
        pcall(function()
            if s.mywibar then
                s.mywibar.visible = false
                s.mywibar:remove()
                s.mywibar = nil
            end
        end)
        return
    end

    local log_init = io.open("/tmp/awesome-wibar-errors.log", "a")
    if log_init then
        log_init:write(os.date("%H:%M:%S") .. " Wibar initialized\n")
        log_init:close()
    end

    -- Timer de salud: verifica cada 30s si la barra tiene widgets
    local health_attempts = 0
    local health_timer = gears.timer.start_new(30, function()
        pcall(function()
            if not (s and s.mywibar) then return true end
            local ok, w = pcall(s.mywibar.get_widget, s.mywibar)
            if ok and w then health_attempts = 0; return true end
            ok, w = pcall(function() return s.mywibar._widget end)
            if ok and w then health_attempts = 0; return true end
            -- Si llegamos aquí, la barra perdió sus widgets
            health_attempts = health_attempts + 1
            local log = io.open("/tmp/awesome-wibar-errors.log", "a")
            if log then
                log:write(os.date("%H:%M:%S") .. " Wibar lost widgets (attempt " .. health_attempts .. ")\n")
                log:close()
            end
            -- Intentar recuperar la barra re-configurándola
            pcall(function()
                if s._wibar_setup then
                    s.mywibar:setup(s._wibar_setup)
                end
            end)
            -- Si falla 3 veces seguidas, reiniciar
            if health_attempts >= 3 then
                local log2 = io.open("/tmp/awesome-wibar-errors.log", "a")
                if log2 then
                    log2:write(os.date("%H:%M:%S") .. " Wibar recovery failed 3 times, restarting...\n")
                    log2:close()
                end
                awesome.restart()
            end
        end)
        return true
    end)

    -- Limpiar timer al desconectar la pantalla
    s._wibar_health_timer = health_timer
end)

screen.connect_signal("removed", function(s)
    if s._wibar_health_timer then
        s._wibar_health_timer:stop()
        s._wibar_health_timer = nil
    end
end)
