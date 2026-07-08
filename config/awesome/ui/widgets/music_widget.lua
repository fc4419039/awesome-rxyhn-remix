local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local gears = require("gears")
local helpers = require("helpers")

local bling_loaded, bling = pcall(require, "module.bling")
local playerctl = nil
if bling_loaded then
    playerctl = bling.signal.playerctl.cli({
        player = {"firefox", "spotify", "%any", "mpd"}
    })
else
    print("Warning: module.bling not found, music widget disabled")
end

local music_widget = {}

local function create_widget(s)
    if not playerctl then return end
    local screen_geo = s.geometry

    local music_art = wibox.widget{
        image = nil,
        resize = true,
        forced_height = dpi(80),
        forced_width = dpi(80),
        shape = gears.shape.circle,
        widget = wibox.widget.imagebox
    }

    local music_title = wibox.widget{
        font = beautiful.font_name .. "bold 12",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }

    local music_artist = wibox.widget{
        font = beautiful.font_name .. "medium 10",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }

    local progress = wibox.widget {
        value = 0,
        max_value = 100,
        color = "#06b6d4",
        background_color = "#ffffff22",
        shape = gears.shape.rounded_bar,
        bar_height = dpi(3),
        forced_width = dpi(140),
        forced_height = dpi(3),
        widget = wibox.widget.progressbar
    }

    local prev_btn = wibox.widget{
        markup = helpers.colorize_text("⏮", beautiful.xcolor4 or "#a0a0a0"),
        font = beautiful.font_name .. "16",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }

    local play_btn = wibox.widget{
        markup = helpers.colorize_text("▶", beautiful.xcolor2 or "#50C878"),
        font = beautiful.font_name .. "16",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }

    local next_btn = wibox.widget{
        markup = helpers.colorize_text("⏭", beautiful.xcolor4 or "#a0a0a0"),
        font = beautiful.font_name .. "16",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }

    for _, btn in ipairs({prev_btn, play_btn, next_btn}) do
        btn:connect_signal("mouse::enter", function()
            btn.markup = helpers.colorize_text(btn.text, beautiful.xforeground)
        end)
        btn:connect_signal("mouse::leave", function()
            btn.markup = helpers.colorize_text(btn.text, beautiful.xcolor4 or "#a0a0a0")
        end)
        helpers.add_hover_cursor(btn, "hand2")
    end

    prev_btn:buttons(gears.table.join(
        awful.button({}, 1, function() awful.spawn("playerctl previous") end)
    ))

    play_btn:buttons(gears.table.join(
        awful.button({}, 1, function()
            awful.spawn("playerctl play-pause")
        end)
    ))

    next_btn:buttons(gears.table.join(
        awful.button({}, 1, function() awful.spawn("playerctl next") end)
    ))

    playerctl:connect_signal("metadata", function(_, title, artist, album_path)
        if title and title ~= "" then
            music_title.markup = helpers.colorize_text(title, beautiful.xforeground)
        else
            music_title.markup = helpers.colorize_text("Nothing Playing", beautiful.xcolor5)
        end
        if artist and artist ~= "" then
            music_artist.markup = helpers.colorize_text(artist, beautiful.xcolor5)
        else
            music_artist.markup = ""
        end
        if album_path and album_path ~= "" then
            music_art:set_image(gears.surface.load_uncached(album_path))
        else
            music_art:set_image(nil)
        end
    end)

    playerctl:connect_signal("playback_status", function(_, status)
        if status == "playing" then
            play_btn.markup = helpers.colorize_text("⏸", beautiful.xcolor2)
        else
            play_btn.markup = helpers.colorize_text("▶", beautiful.xcolor2)
        end
    end)

    playerctl:connect_signal("position", function(_, interval_sec, length_sec)
        if length_sec and length_sec > 0 then
            progress.value = (interval_sec / length_sec) * 100
        end
    end)

    local controls = wibox.widget{
        prev_btn,
        play_btn,
        next_btn,
        spacing = dpi(24),
        layout = wibox.layout.fixed.horizontal
    }

    local info = wibox.widget{
        music_title,
        music_artist,
        controls,
        spacing = dpi(8),
        layout = wibox.layout.fixed.vertical
    }

    local main_content = wibox.widget{
        music_art,
        info,
        spacing = dpi(12),
        layout = wibox.layout.fixed.horizontal
    }

    local widget_container = wibox.widget{
        {
            main_content,
            margins = dpi(8),
            widget = wibox.container.margin
        },
        wibox.widget{},
        {
            {
                progress,
                left = dpi(10),
                right = dpi(10),
                bottom = dpi(10),
                widget = wibox.container.margin
            },
            forced_height = dpi(13),
            widget = wibox.container.background
        },
        layout = wibox.layout.align.vertical
    }

    local pos_file = "/tmp/awesome-music-widget-pos-" .. s.index

    local w = wibox {
        type = "normal",
        screen = s,
        width = dpi(180),
        height = dpi(85),
        x = screen_geo.x + screen_geo.width - dpi(220),
        y = screen_geo.y + dpi(230),
        bg = "#00000000",
        visible = true,
        border_width = 0,
        border_color = "#00000000",
        ontop = false,
        below = true,
        skip_taskbar = true,
        focusable = false
    }

    local function start_move()
        local g = w:geometry()
        local mx, my = mouse.coords().x, mouse.coords().y
        local ox, oy = g.x - mx, g.y - my
        mousegrabber.run(function(m)
            if not m.buttons[1] then return false end
            w.x = ox + m.x
            w.y = oy + m.y
            return true
        end, "fleur")
    end

    local function do_resize(w, g, mx, my, ow, oh, ox, oy, btn, resize_from_x, resize_from_y)
        local cursor = "fleur"
        if resize_from_x == "left" and resize_from_y == "top" then cursor = "top_left_corner"
        elseif resize_from_x == "right" and resize_from_y == "top" then cursor = "top_right_corner"
        elseif resize_from_x == "left" and resize_from_y == "bottom" then cursor = "bottom_left_corner"
        elseif resize_from_x == "right" and resize_from_y == "bottom" then cursor = "bottom_right_corner"
        elseif resize_from_x == "left" then cursor = "left_side"
        elseif resize_from_x == "right" then cursor = "right_side"
        elseif resize_from_y == "top" then cursor = "top_side"
        elseif resize_from_y == "bottom" then cursor = "bottom_side"
        end
        mousegrabber.run(function(m)
            if not m.buttons[btn] then return false end
            local dx = m.x - mx
            local dy = m.y - my
            local nw = ow
            local nh = oh
            local new_x = ox
            local new_y = oy

            if resize_from_x == "left" then
                nw = math.max(dpi(200), ow - dx)
                new_x = ox + (ow - nw)
            elseif resize_from_x == "right" then
                nw = math.max(dpi(200), ow + dx)
            end

            if resize_from_y == "top" then
                nh = math.max(dpi(80), oh - dy)
                new_y = oy + (oh - nh)
            elseif resize_from_y == "bottom" then
                nh = math.max(dpi(80), oh + dy)
            end

            w:geometry({x = new_x, y = new_y, width = nw, height = nh})
            return true
        end, cursor)
    end

    local function start_resize()
        local g = w:geometry()
        local mx, my = mouse.coords().x, mouse.coords().y
        local ow, oh = g.width, g.height
        local ox, oy = g.x, g.y
        local edge = dpi(12)

        local resize_from_x = "right"
        local resize_from_y = "bottom"

        if mx <= ox + edge then
            resize_from_x = "left"
        elseif mx >= ox + ow - edge then
            resize_from_x = "right"
        else
            resize_from_x = nil
        end

        if my <= oy + edge then
            resize_from_y = "top"
        elseif my >= oy + oh - edge then
            resize_from_y = "bottom"
        else
            resize_from_y = nil
        end

        if not resize_from_x and not resize_from_y then
            resize_from_x = "right"
            resize_from_y = "bottom"
        elseif not resize_from_x then
            resize_from_x = "right"
        elseif not resize_from_y then
            resize_from_y = "bottom"
        end
        
        do_resize(w, g, mx, my, ow, oh, ox, oy, 3, resize_from_x, resize_from_y)
    end

    local saved_data
    local f2 = io.open(pos_file, "r")
    if f2 then
        saved_data = f2:read("*a")
        f2:close()
    end
    if saved_data then
        local sx, sy, sw, sh = saved_data:match("(%d+),(%d+),(%d+),(%d+)")
        if sx then
            w:geometry({x = tonumber(sx), y = tonumber(sy), width = tonumber(sw), height = tonumber(sh)})
        end
    end

    local save_timer = gears.timer {
        timeout = 0.5,
        autostart = false,
        single_shot = true,
        callback = function()
            local g = w:geometry()
            local f3 = io.open(pos_file, "w")
            if f3 then
                f3:write(g.x .. "," .. g.y .. "," .. g.width .. "," .. g.height)
                f3:close()
            end
        end
    }

    w:connect_signal("property::geometry", function() save_timer:again() end)

    w:buttons(gears.table.join(
        awful.button({"Mod4"}, 1, start_move),
        awful.button({"Mod4"}, 3, start_resize)
    ))

    w:setup {
        widget_container,
        widget = wibox.container.background
    }

    s.music_widget = w

    return w
end

screen.connect_signal("request::desktop_decoration", create_widget)

return music_widget