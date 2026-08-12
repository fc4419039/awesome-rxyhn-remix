-- helpers.lua
-- Functions that you use more than once and in different files would
-- be nice to define here.
local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local wibox = require("wibox")
local naughty = require("naughty")
local helpers = {}

helpers.misc = {}

function helpers.misc.case_insensitive_pattern(s)
    return s:gsub("%a", function(c) return "[" .. c:lower() .. c:upper() .. "]" end)
end

function helpers.contains(_table, _c)
	for _, c in ipairs(_table) do
		if _c == c then
			return true
		end
	end
	return false
end

function helpers.find(rule)
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

-- Adds a maximized mask to a screen
function helpers.screen_mask(s, bg)
    local mask = wibox({
        visible = false,
        ontop = true,
        type = "splash",
        screen = s
    })
    awful.placement.maximize(mask)
    mask.bg = bg
    return mask
end

function helpers.custom_shape(cr, width, height)
    cr:move_to(0, height / 25)
    cr:line_to(height / 25, 0)
    cr:line_to(width, 0)
    cr:line_to(width, height - height / 25)
    cr:line_to(width - height / 25, height)
    cr:line_to(0, height)
    cr:close_path()
end

-- Resize gaps on the fly

helpers.resize_gaps = function(amt)
    local t = awful.screen.focused().selected_tag
    t.gap = t.gap + tonumber(amt)
    awful.layout.arrange(awful.screen.focused())
end

-- Resize padding on the fly

helpers.resize_padding = function(amt)
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

-- Create rounded rectangle shape (in one line)

helpers.rrect = function(radius)
    return function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, radius)
    end
end

-- Create pi

helpers.pie = function(width, height, start_angle, end_angle, radius)
    return function(cr)
        gears.shape.pie(cr, width, height, start_angle, end_angle, radius)
    end
end

-- Create parallelogram

helpers.prgram = function(height, base)
    return function(cr, width)
        gears.shape.parallelogram(cr, width, height, base)
    end
end

-- Create partially rounded rect

helpers.prrect = function(radius, tl, tr, br, bl)
    return function(cr, width, height)
        gears.shape.partially_rounded_rect(cr, width, height, tl, tr, br, bl,
                                           radius)
    end
end

-- Create rounded bar

helpers.rbar = function(width, height)
    return function(cr)
        gears.shape.rounded_bar(cr, width, height)
    end
end

-- Markup helper

function helpers.colorize_text(txt, fg)
    return "<span foreground='" .. fg .. "'>" .. (txt or "") .. "</span>"
end

-- Ajusta una wibox al tamaño natural de su contenido (tight fit).
-- Sin esto, una wibox sin width/height explícito queda en 1x1.
function helpers.fit_wibox(w, s)
    if not w or not w.valid then return end
    local widget = w:get_widget()
    if not widget then return end
    local ctx = {
        screen = s,
        dpi = s.dpi,
        drawable = w._drawable,
    }
    local fw, fh = widget:fit(ctx, s.geometry.width, s.geometry.height)
    if fw and fh and fw > 0 and fh > 0 then
        w:geometry({ width = fw, height = fh })
    end
end

-- Asegura que una wibox quede siempre dentro de la pantalla (no se pueda
-- perder fuera del viewport tras restaurar su posición guardada).
function helpers.clamp_wibox_on_screen(w, s)
    if not w or not w.valid or not s then return end
    local g = w:geometry()
    local geo = s.geometry
    local margin = 10
    local min_x = geo.x + margin
    local max_x = geo.x + geo.width - g.width - margin
    local min_y = geo.y + margin
    local max_y = geo.y + geo.height - g.height - margin
    local x = math.max(min_x, math.min(max_x, g.x))
    local y = math.max(min_y, math.min(max_y, g.y))
    if x ~= g.x or y ~= g.y then
        w:geometry({ x = x, y = y })
    end
end

function helpers.client_menu_toggle()
    local instance = nil

    return function()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({theme = {width = dpi(250)}})
        end
    end
end

-- Escapes a string so that it can be displayed inside pango markup
-- tags. Modified from:
-- https://github.com/kernelsauce/turbo/blob/master/turbo/escape.lua
function helpers.pango_escape(s)
    return (string.gsub(s, "[&<>]",
                        {["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;"}))
end

function helpers.brand_watermark(opacity)
    if not beautiful.brand_logo then return nil end
    return wibox.widget{
        image = beautiful.brand_logo,
        resize = true,
        upscale = false,
        opacity = opacity or 0.7,
        halign = "center",
        valign = "center",
        forced_width = dpi(200),
        forced_height = dpi(200),
        widget = wibox.widget.imagebox
    }
end

function helpers.vertical_pad(height)
    return wibox.widget {
        forced_height = height,
        layout = wibox.layout.fixed.vertical
    }
end

function helpers.horizontal_pad(width)
    return wibox.widget {
        forced_width = width,
        layout = wibox.layout.fixed.horizontal
    }
end

-- Maximizes client and also respects gaps
function helpers.maximize(c)
    c.maximized = not c.maximized
    if c.maximized then
        awful.placement.maximize(c, {
            honor_padding = true,
            honor_workarea = true,
            margins = beautiful.useless_gap * 2
        })

    end
    c:raise()
end

local double_tap_timer = nil
function helpers.single_double_tap(single_tap_function, double_tap_function)
    if double_tap_timer then
        double_tap_timer:stop()
        double_tap_timer = nil
        double_tap_function()
        -- naughty.notify({text = "We got a double tap"})
        return
    end

    double_tap_timer = gears.timer.start_new(0.20, function()
        double_tap_timer = nil
        -- naughty.notify({text = "We got a single tap"})
        if single_tap_function then single_tap_function() end
        return false
    end)
end

-- Used as a custom command in rofi to move a window into the current tag
-- instead of following it.
-- Rofi has access to the X window id of the client.
function helpers.rofi_move_client_here(window)
    local win = function(c) return awful.rules.match(c, {window = window}) end

    for c in awful.client.iterate(win) do
        c.minimized = false
        c:move_to_tag(mouse.screen.selected_tag)
        client.focus = c
        c:raise()
    end
end

-- Add a hover cursor to a widget by changing the cursor on
-- mouse::enter and mouse::leave
-- You can find the names of the available cursors by opening any
-- cursor theme and looking in the "cursors folder"
-- For example: "hand1" is the cursor that appears when hovering over
-- links
function helpers.add_hover_cursor(w, hover_cursor)
    local original_cursor = "left_ptr"

    w:connect_signal("mouse::enter", function()
        local w = _G.mouse.current_wibox
        if w then w.cursor = hover_cursor end
    end)

    w:connect_signal("mouse::leave", function()
        local w = _G.mouse.current_wibox
        if w then w.cursor = original_cursor end
    end)
end

-- Tag back and forth:
-- If you try to focus the tag you are already at, go back to the previous tag.
-- Useful for quick switching after for example checking an incoming chat
-- message at tag 2 and coming back to your work at tag 1 with the same
-- keypress.
-- Also focuses urgent clients if they exist in the tag. This fixes the issue
-- (visual mismatch) where after switching to a tag which includes an urgent
-- client, the urgent client is unfocused but still covers all other windows
-- (even the currently focused window).
function helpers.tag_back_and_forth(tag_index)
    local s = mouse.screen
    local tag = s.tags[tag_index]
    if tag then
        if tag == s.selected_tag then
            awful.tag.history.restore()
        else
            tag:view_only()
        end

        local urgent_clients = function(c)
            return awful.rules.match(c, {urgent = true, first_tag = tag})
        end

        for c in awful.client.iterate(urgent_clients) do
            client.focus = c
            c:raise()
        end
    end
end

-- Resize DWIM (Do What I Mean)
-- Resize client or factor
-- Constants --
local floating_resize_amount = dpi(20)
local tiling_resize_factor = 0.05
---------------
function helpers.resize_dwim(c, direction)
    if awful.layout.get(mouse.screen) == awful.layout.suit.floating or
        (c and c.floating) then
        if direction == "up" then
            c:relative_move(0, 0, 0, -floating_resize_amount)
        elseif direction == "down" then
            c:relative_move(0, 0, 0, floating_resize_amount)
        elseif direction == "left" then
            c:relative_move(0, 0, -floating_resize_amount, 0)
        elseif direction == "right" then
            c:relative_move(0, 0, floating_resize_amount, 0)
        end
    else
        if direction == "up" then
            awful.client.incwfact(-tiling_resize_factor)
        elseif direction == "down" then
            awful.client.incwfact(tiling_resize_factor)
        elseif direction == "left" then
            awful.tag.incmwfact(-tiling_resize_factor)
        elseif direction == "right" then
            awful.tag.incmwfact(tiling_resize_factor)
        end
    end
end

-- Move client to screen edge, respecting the screen workarea
function helpers.move_to_edge(c, direction)
    local workarea = awful.screen.focused().workarea
    if direction == "up" then
        c:geometry({nil, y = workarea.y + beautiful.useless_gap * 2, nil, nil})
    elseif direction == "down" then
        c:geometry({
            nil,
            y = workarea.height + workarea.y - c:geometry().height -
                beautiful.useless_gap * 2 - beautiful.border_width * 2,
            nil,
            nil
        })
    elseif direction == "left" then
        c:geometry({x = workarea.x + beautiful.useless_gap * 2, nil, nil, nil})
    elseif direction == "right" then
        c:geometry({
            x = workarea.width + workarea.x - c:geometry().width -
                beautiful.useless_gap * 2 - beautiful.border_width * 2,
            nil,
            nil,
            nil
        })
    end
end

-- Move client DWIM (Do What I Mean)
-- Move to edge if the client / layout is floating
-- Swap by index if maximized
-- Else swap client by direction
function helpers.move_client_dwim(c, direction)
    if c.floating or
        (awful.layout.get(mouse.screen) == awful.layout.suit.floating) then
        helpers.move_to_edge(c, direction)
    elseif awful.layout.get(mouse.screen) == awful.layout.suit.max then
        if direction == "up" or direction == "left" then
            awful.client.swap.byidx(-1, c)
        elseif direction == "down" or direction == "right" then
            awful.client.swap.byidx(1, c)
        end
    else
        awful.client.swap.bydirection(direction, c, nil)
    end
end

-- Make client floating and snap to the desired edge
function helpers.float_and_edge_snap(c, direction)
    -- if not c.floating then
    --     c.floating = true
    -- end
    naughty.notify({text = "double tap"})
    c.floating = true
    local workarea = awful.screen.focused().workarea
    if direction == "up" then
        local axis = 'horizontally'
        local f = awful.placement.scale + awful.placement.top +
                      (axis and awful.placement['maximize_' .. axis] or nil)
        local geo = f(client.focus, {
            honor_padding = true,
            honor_workarea = true,
            to_percent = 0.5
        })
    elseif direction == "down" then
        local axis = 'horizontally'
        local f = awful.placement.scale + awful.placement.bottom +
                      (axis and awful.placement['maximize_' .. axis] or nil)
        local geo = f(client.focus, {
            honor_padding = true,
            honor_workarea = true,
            to_percent = 0.5
        })
    elseif direction == "left" then
        local axis = 'vertically'
        local f = awful.placement.scale + awful.placement.left +
                      (axis and awful.placement['maximize_' .. axis] or nil)
        local geo = f(client.focus, {
            honor_padding = true,
            honor_workarea = true,
            to_percent = 0.5
        })
    elseif direction == "right" then
        local axis = 'vertically'
        local f = awful.placement.scale + awful.placement.right +
                      (axis and awful.placement['maximize_' .. axis] or nil)
        local geo = f(client.focus, {
            honor_padding = true,
            honor_workarea = true,
            to_percent = 0.5
        })
    end
end

-- Rounds a number to any number of decimals
function helpers.round(number, decimals)
    local power = 10 ^ decimals
    return math.floor(number * power) / power
end

function helpers.fake_escape()
    root.fake_input('key_press', "Escape")
    root.fake_input('key_release', "Escape")
end

function helpers.run_or_raise(match, move, spawn_cmd, spawn_args)
    local matcher = function(c) return awful.rules.match(c, match) end

    -- Find and raise
    local found = false
    for c in awful.client.iterate(matcher) do
        found = true
        c.minimized = false
        if move then
            c:move_to_tag(mouse.screen.selected_tag)
            client.focus = c
            c:raise()
        else
            c:jump_to()
        end
        break
    end

    -- Spawn if not found
    if not found then awful.spawn(spawn_cmd, spawn_args) end
end

function helpers.pad(size)
    local str = ""
    for i = 1, size do str = str .. " " end
    local pad = wibox.widget.textbox(str)
    return pad
end

function helpers.float_and_resize(c, width, height)
    c.width = width
    c.height = height
    awful.placement.centered(c, {honor_workarea = true, honor_padding = true})
    awful.client.property.set(c, 'floating_geometry', c:geometry())
    c.floating = true
    c:raise()
end

function helpers.centered_client_placement(c)
    return gears.timer.delayed_call(function ()
        awful.placement.centered(c, {honor_padding = true, honor_workarea=true})
    end)
end

-- Useful for periodically checking the output of a command that
-- requires internet access.
-- Ensures that `command` will be run EXACTLY once during the desired
-- `interval`, even if awesome restarts multiple times during this time.
-- Saves output in `output_file` and checks its last modification
-- time to determine whether to run the command again or not.
-- Passes the output of `command` to `callback` function.
function helpers.remote_watch(command, interval, output_file, callback)
    local run_the_thing = function()
        -- Pass output to callback AND write it to file
        awful.spawn.easy_async_with_shell(command.." | tee "..output_file, function(out) callback(out) end)
    end

    local function get_file_mtime()
        local f = io.popen("stat -c %Y " .. output_file .. " 2>/dev/null")
        if f then
            local result = tonumber(f:read("*a"))
            f:close()
            return result
        end
        return nil
    end

    local function read_file()
        local f = io.open(output_file, "r")
        if f then
            local content = f:read("*a")
            f:close()
            return content
        end
        return nil
    end

    local timer
    local function tick()
        local mtime = get_file_mtime()
        if not mtime then
            run_the_thing()
            return
        end

        local diff = os.time() - mtime
        if diff >= interval then
            run_the_thing()
        else
            local cached = read_file()
            if cached then callback(cached) end
            timer:stop()
            gears.timer.start_new(interval - diff, function()
                run_the_thing()
                timer:again()
            end)
        end
    end

    timer = gears.timer {
        timeout = interval,
        call_now = false,
        autostart = true,
        single_shot = false,
        callback = tick
    }
    tick()
end

-- Volume Control: sink explícito por nombre vía pactl.
-- Evita que @DEFAULT_AUDIO_SINK@ (WirePlumber) derive al sink de hardware,
-- que es compartido por programas y notificaciones (causaba volúmenes cruzados).
-- El volumen queda acotado entre 0 y 100 (nunca por encima).
local function sink_volume(sink, step)
    if step == 0 then
        awful.spawn.with_shell("pactl set-sink-mute " .. sink .. " toggle 2>/dev/null || true")
        return
    end
    local cmd = "s=\"" .. sink .. "\"; step=" .. step .. "\n" ..
        "cur=$(pactl get-sink-volume \"$s\" 2>/dev/null | grep -o '[0-9]*%' | head -1 | tr -d '%')\n" ..
        "cur=${cur:-0}\n" ..
        "tgt=$((cur + step))\n" ..
        "[ \"$tgt\" -gt 100 ] && tgt=100\n" ..
        "[ \"$tgt\" -lt 0 ] && tgt=0\n" ..
        "pactl set-sink-volume \"$s\" \"${tgt}%\" 2>/dev/null || true"
    awful.spawn.with_shell(cmd)
end

function helpers.volume_control(step)
    sink_volume("system_sink", step)
end

function helpers.notifications_volume(step)
    sink_volume("notifications", step)
end

function helpers.music_control(state)
    local cmd
    if state == "toggle" then
        cmd = "playerctl -p spotify,mpd play-pause"
    elseif state == "prev" then
        cmd = "playerctl -p spotify,mpd previous"
    elseif state == "next" then
        cmd = "playerctl -p spotify,mpd next"
    end
    awful.spawn.with_shell(cmd)
end

function helpers.send_key(c, key)
    awful.spawn.with_shell("xdotool key --window "..tostring(c.window).." "..key)
end

function helpers.send_key_sequence(c, seq)
    awful.spawn.with_shell("xdotool type --delay 5 --window "..tostring(c.window).." "..seq)
end

function helpers.upper_no_accents(str)
    local map = {
        [0xC1] = "A", [0xC9] = "E", [0xCD] = "I", [0xD3] = "O", [0xDA] = "U",
        [0xC0] = "A", [0xC8] = "E", [0xCC] = "I", [0xD2] = "O", [0xD9] = "U",
        [0xC2] = "A", [0xCA] = "E", [0xCE] = "I", [0xD4] = "O", [0xDB] = "U",
        [0xC3] = "A", [0xD5] = "O", [0xC7] = "C", [0xD1] = "N",
        [0xE1] = "A", [0xE9] = "E", [0xED] = "I", [0xF3] = "O", [0xFA] = "U",
        [0xE0] = "A", [0xE8] = "E", [0xEC] = "I", [0xF2] = "O", [0xF9] = "U",
        [0xE2] = "A", [0xEA] = "E", [0xEE] = "I", [0xF4] = "O", [0xFB] = "U",
        [0xE3] = "A", [0xF5] = "O", [0xE7] = "C", [0xF1] = "N",
    }
    local chars = {}
    for codepoint in str:gmatch(utf8.charpattern) do
        local cp = utf8.codepoint(codepoint)
        chars[#chars+1] = map[cp] or codepoint
    end
    return string.upper(table.concat(chars))
end

return helpers
