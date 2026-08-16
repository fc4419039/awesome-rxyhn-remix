local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local naughty = require("naughty")

local client_helpers = {}

local double_tap_timer = nil

function client_helpers.single_double_tap(single_tap_function, double_tap_function)
    if double_tap_timer then
        double_tap_timer:stop()
        double_tap_timer = nil
        double_tap_function()
        return
    end

    double_tap_timer = gears.timer.start_new(0.20, function()
        double_tap_timer = nil
        if single_tap_function then single_tap_function() end
        return false
    end)
end

function client_helpers.maximize(c)
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

local floating_resize_amount = dpi(20)
local tiling_resize_factor = 0.05

function client_helpers.resize_dwim(c, direction)
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

function client_helpers.move_to_edge(c, direction)
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

function client_helpers.move_client_dwim(c, direction)
    if c.floating or
        (awful.layout.get(mouse.screen) == awful.layout.suit.floating) then
        client_helpers.move_to_edge(c, direction)
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

function client_helpers.float_and_edge_snap(c, direction)
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

function client_helpers.float_and_resize(c, width, height)
    c.width = width
    c.height = height
    awful.placement.centered(c, {honor_workarea = true, honor_padding = true})
    awful.client.property.set(c, 'floating_geometry', c:geometry())
    c.floating = true
    c:raise()
end

function client_helpers.centered_client_placement(c)
    return gears.timer.delayed_call(function ()
        awful.placement.centered(c, {honor_padding = true, honor_workarea=true})
    end)
end

function client_helpers.run_or_raise(match, move, spawn_cmd, spawn_args)
    local matcher = function(c) return awful.rules.match(c, match) end

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

    if not found then awful.spawn(spawn_cmd, spawn_args) end
end

function client_helpers.send_key(c, key)
    awful.spawn.with_shell("xdotool key --window "..tostring(c.window).." "..key)
end

function client_helpers.send_key_sequence(c, seq)
    awful.spawn.with_shell("xdotool type --delay 5 --window "..tostring(c.window).." "..seq)
end

function client_helpers.tag_back_and_forth(tag_index)
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

function client_helpers.client_menu_toggle()
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

function client_helpers.rofi_move_client_here(window)
    local win = function(c) return awful.rules.match(c, {window = window}) end

    for c in awful.client.iterate(win) do
        c.minimized = false
        c:move_to_tag(mouse.screen.selected_tag)
        client.focus = c
        c:raise()
    end
end

function client_helpers.add_hover_cursor(w, hover_cursor)
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

return client_helpers