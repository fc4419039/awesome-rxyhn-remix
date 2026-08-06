-- Standard awesome library
local awful = require("awful")
require("awful.autofocus")
local gears = require("gears")
local gfs = gears.filesystem
local naughty = require("naughty")
local wibox = require("wibox")

-- Theme handling library
local beautiful = require("beautiful")


-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
naughty.connect_signal("request::display_error", function(message, startup)
    naughty.notification {
        urgency = "critical",
        title = i18n.tr(startup and "extras.error_title_startup" or "extras.error_title"),
        message = message
    }
end)

client.connect_signal("request::manage", function(c)
    -- Add missing icon to client
    if not c.icon then
        local icon = gears.surface(beautiful.awesome_logo)
        c.icon = icon._native
        icon:finish()
    end

    -- Evitar que programas abran en fullscreen al iniciar (Firefox restaura estado después del manage)
    local fs_guard
    fs_guard = function()
        if c.valid then
            c.fullscreen = false
        end
    end
    if c.fullscreen then
        c.fullscreen = false
    end
    c:connect_signal("property::fullscreen", fs_guard)
    gears.timer.start_new(3, function()
        if c.valid then
            pcall(c.disconnect_signal, c, "property::fullscreen", fs_guard)
        end
        return false
    end)

    -- Set the windows at the slave,
    if awesome.startup and not c.size_hints.user_position and
        not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

-- Archivos de estado para persistencia entre recargas
local state_dir = os.getenv("HOME") .. "/.cache/awesome"
os.execute("mkdir -p " .. state_dir)
local border_state_file = state_dir .. "/border-state"
local titlebar_state_file = state_dir .. "/titlebar-state"

-- Toggle de bordes para ventanas (NO afecta rofi, que dibuja sus propios bordes)
local window_borders_enabled = true

local f = io.open(border_state_file, "r")
if f then f:close(); window_borders_enabled = false end

local function update_window_borders()
    for _, c in ipairs(client.get()) do
        c.border_width = window_borders_enabled and beautiful.border_width or 0
    end
end
update_window_borders()

function toggle_window_borders()
    window_borders_enabled = not window_borders_enabled
    update_window_borders()
    if window_borders_enabled then
        os.remove(border_state_file)
    else
        local f = io.open(border_state_file, "w")
        if f then f:close() end
    end
    naughty.notify({
        text = window_borders_enabled and i18n.tr("extras.borders_on") or i18n.tr("extras.borders_off"),
        timeout = 2
    })
end

-- Toggle de titlebars para ventanas
local titlebar_builder = require("ui.decorations.titlebar")
local titlebars_enabled = true

local f = io.open(titlebar_state_file, "r")
if f then f:close(); titlebars_enabled = false end

function toggle_window_titlebars()
    titlebars_enabled = not titlebars_enabled
    local n = 0
    if titlebars_enabled then
        for _, c in ipairs(client.get()) do
            if not c.titlebar and not c.custom_decoration then
                titlebar_builder.setup(c)
                n = n + 1
            end
        end
        os.remove(titlebar_state_file)
    else
        for _, c in ipairs(client.get()) do
            if c.titlebar and not c.custom_decoration then
                c.titlebar:remove()
                n = n + 1
            end
        end
        local f = io.open(titlebar_state_file, "w")
        if f then f:close() end
    end
    naughty.notify({
        text = (titlebars_enabled and i18n.tr("extras.titlebars_on") or i18n.tr("extras.titlebars_off"))
            .. " " .. i18n.format("extras.windows_count", n),
        timeout = 3
    })
end

client.connect_signal("manage", function(c)
    c.border_width = window_borders_enabled and beautiful.border_width or 0
    if titlebars_enabled and not c.titlebar then
        titlebar_builder.setup(c)
    end
end)

-- Restaurar titlebars persistidos al recargar
if titlebars_enabled then
    gears.timer.start_new(1, function()
        for _, c in ipairs(client.get()) do
            if not c.titlebar then
                titlebar_builder.setup(c)
            end
        end
        return false
    end)
end

client.connect_signal("focus",
                      function(c) c.border_color = beautiful.border_focus end)

client.connect_signal("unfocus",
                      function(c) c.border_color = beautiful.border_normal end)


-- Hide all windows when a splash is shown
awesome.connect_signal("widgets::splash::visibility", function(vis)
    local t = screen.primary.selected_tag
    if vis then
        for idx, c in ipairs(t:clients()) do c.hidden = true end
    else
        for idx, c in ipairs(t:clients()) do c.hidden = false end
    end
end)


--Bling
----------

local bling = require("module.bling")

bling.module.flash_focus.enable()

-- Tag Preview
bling.widget.tag_preview.enable {
    show_client_content = true,
    placement_fn = function(c)
        local s = mouse.screen or awful.screen.focused()
        if s then c.screen = s end
        awful.placement.top_left(c, {
            margins = {
                top = 99,
                left = beautiful.wibar_width + 55
            }
        })
    end,
    scale = 0.15,
    honor_padding = true,
    honor_workarea = false,
    background_widget = wibox.widget {
        -- image = beautiful.wallpaper,
        -- horizontal_fit_policy = "fit",
        -- vertical_fit_policy = "fit",
        -- widget = wibox.widget.imagebox
        bg = beautiful.wibar_bg,
        widget = wibox.container.bg
    }
}

bling.widget.task_preview.enable {
    height = dpi(200),
    width = dpi(300),
    placement_fn = function(c)
        awful.placement.top(c, { margins = { top = dpi(100) } })
    end,
}

require('ui.widgets.window_switcher').enable()


