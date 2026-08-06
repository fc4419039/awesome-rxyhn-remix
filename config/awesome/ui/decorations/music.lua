-- Standard awesome library
local gears = require("gears")
local awful = require("awful")

-- Theme library
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

-- Ruled
local ruled = require("ruled")

-- Widget library
local wibox = require("wibox")

-- Helpers
local helpers = require("helpers")


-- Music icon
----------------

local big_music_icon = wibox.widget{
    align = "center",
    font = beautiful.icon_font_name .. "Bold 16",
    markup = helpers.colorize_text("", beautiful.deco_blue),
    widget = wibox.widget.textbox()
}

local small_music_icon = wibox.widget{
    align = "center",
    font = beautiful.icon_font_name .. "Bold 12",
    markup = helpers.colorize_text("", beautiful.xforeground),
    widget = wibox.widget.textbox()
}

local container_music_icon = wibox.widget {
    big_music_icon,
    {
        small_music_icon,
        top = dpi(12),
        widget = wibox.container.margin
    },
    spacing = dpi(-8),
    layout = wibox.layout.fixed.horizontal
}

local music_icon = wibox.widget{
        nil,
        {
            container_music_icon,
            spacing = dpi(14),
            layout  = wibox.layout.fixed.horizontal
        },
        expand = "none",
        layout = wibox.layout.align.horizontal,
    }

-- Helpers
-------------

local control_button_bg = "#00000000"
local control_button_bg_hover = beautiful.deco_gray .. "66"
local control_button = function(c, symbol, color, font, size, on_click, on_right_click)
    local icon = wibox.widget{
        markup = helpers.colorize_text(symbol, color),
        font = font,
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox()
    }

    local button = wibox.widget {
        icon,
        bg = control_button_bg,
        shape = helpers.rrect(dpi(5)),
        widget = wibox.container.background
    }

    local container = wibox.widget {
        button,
        strategy = "min",
        width = dpi(30),
        widget = wibox.container.constraint,
    }

    container:buttons(gears.table.join(
        awful.button({ }, 1, on_click),
        awful.button({ }, 3, on_right_click)
    ))

    container:connect_signal("mouse::enter", function ()
        button.bg = control_button_bg_hover
    end)
    container:connect_signal("mouse::leave", function ()
        button.bg = control_button_bg
    end)

    return container
end

local music_play_pause = control_button(c, "", beautiful.xforeground, beautiful.icon_font_name .. "Round 22", dpi(30), function()
    awful.spawn.with_shell("mpc -q toggle")
end)

-- Loop button
local loop = control_button(c, "", beautiful.xforeground, beautiful.icon_font_name .. "Round 12", dpi(30), function()
    awful.spawn.with_shell("mpc repeat")
end)

-- Repeat-one (single) button
local single = control_button(c, "", beautiful.xforeground, beautiful.icon_font_name .. "12", dpi(30), function()
    awful.spawn.with_shell("sh -c 'if [ \"$(mpc status 2>/dev/null | grep -o \'single: [a-z]*\' | cut -d\' \' -f2)\" = \"on\" ]; then mpc -q single off; else mpc -q single on; mpc -q repeat on; fi'")
end)

-- Shuffle playlist
local shuffle = control_button(c, "", beautiful.xforeground, beautiful.icon_font_name .. "Round 12", dpi(30), function()
    awful.spawn.with_shell("mpc random")
end)

local function create_slider_widget(slider_color)
    local slider_widget = wibox.widget {
        {
            id = "slider",
            max_value = 100,
            value = 20,
            margins = {
                top = dpi(2),
                bottom = dpi(2),
                left = dpi(6),
                right = dpi(6),
            },
            forced_width  = dpi(60),
            forced_height = dpi(10),
            shape         = gears.shape.rounded_bar,
            bar_shape     = gears.shape.rounded_bar,
            color = slider_color,
    background_color = beautiful.deco_gray .. "44",
            widget = wibox.widget.progressbar
        },
        expand = "none",
        forced_width = 60,
        layout = wibox.layout.align.horizontal
    }

    return slider_widget
end

local stats_tooltip = wibox.widget {
    visible = false,
    top_only = true,
    layout = wibox.layout.stack
}

local tooltip_counter = 0
local function create_tooltip(w)
    local tooltip = wibox.widget {
        font = beautiful.font_name .. "bold 10",
        align = "right",
        valign = "center",
        widget = wibox.widget.textbox
    }

    tooltip_counter = tooltip_counter + 1
    local index = tooltip_counter

    stats_tooltip:insert(index, tooltip)

    w:connect_signal("mouse::enter", function()
        -- Raise tooltip to the top of the stack
        stats_tooltip:set(1, tooltip)
        stats_tooltip.visible = true
    end)
    w:connect_signal("mouse::leave", function ()
        stats_tooltip.visible = false
    end)

    return tooltip
end


-- Decorations
----------------

local music_art = wibox.widget {
    image = gears.filesystem.get_configuration_dir() .. "theme/assets/no_music.png",
    resize = true,
    widget = wibox.widget.imagebox
}

local music_art_container = wibox.widget{
    music_art,
    shape = helpers.rrect(dpi(5)),
    widget = wibox.container.background
}

local music_art_square = wibox.widget {
    music_art_container,
    width = dpi(250),
    height = dpi(250),
    widget = wibox.container.constraint
}

local music_now = wibox.widget{
    font = beautiful.font_name .. "bold 10",
    valign = "center",
    widget = wibox.widget.textbox
}

local music_pos = wibox.widget{
    font = beautiful.font_name .. "bold 10",
    valign = "center",
    widget = wibox.widget.textbox
}

local music_bar = wibox.widget {
    max_value = 100,
    value = 0,
    background_color = beautiful.xcolor0,
    color = beautiful.deco_blue,
    forced_height = dpi(3),
    widget = wibox.widget.progressbar
}

music_bar:connect_signal("button::press", function(_, lx, __, button, ___, w)
    if button == 1 then
        awful.spawn.with_shell("mpc seek " .. math.ceil(lx * 100 / w.width) .. "%")
    end
end)


local music_play_pause_textbox = music_play_pause:get_all_children()[1]:get_all_children()[1]
local loop_textbox = loop:get_all_children()[1]:get_all_children()[1]
local single_textbox = single:get_all_children()[1]:get_all_children()[1]
local shuffle_textbox = shuffle:get_all_children()[1]:get_all_children()[1]

-- Volume
--------

local vol_color = beautiful.deco_blue
local vol_slider = create_slider_widget(vol_color)
local vol_tooltip = create_tooltip(vol_slider)

local vol_icon = wibox.widget{
    align = "center",
    font = "Symbols Nerd Font 14",
    markup = "",
    widget = wibox.widget.textbox
}

local vol_button = wibox.widget{
    vol_icon,
    bg = control_button_bg,
    shape = helpers.rrect(dpi(5)),
    widget = wibox.container.background
}

local vol = wibox.widget {
    vol_button,
    strategy = "min",
    width = dpi(30),
    widget = wibox.container.constraint,
}

vol:connect_signal("mouse::enter", function ()
    vol_button.bg = control_button_bg_hover
end)
vol:connect_signal("mouse::leave", function ()
    vol_button.bg = control_button_bg
end)
vol:buttons(gears.table.join(
    awful.button({}, 1, function() helpers.volume_control(0) end)
))

awesome.connect_signal("signal::volume", function(value, muted)
    local fill_color
    local vol_value = value or 0

    if muted then
        vol_icon.markup = helpers.colorize_text("", beautiful.xcolor8)
        fill_color = beautiful.xcolor8
    else
        vol_icon.markup = helpers.colorize_text("", beautiful.xforeground)
        fill_color = vol_color
    end

    vol_slider.slider.value = vol_value
    vol_slider.slider.color = fill_color
    vol_tooltip.markup = helpers.colorize_text(vol_value .. "%", vol_color)
end)

vol_slider:buttons(gears.table.join(
    awful.button({}, 1, function() helpers.volume_control(0) end),
    -- Scrolling
    awful.button({}, 4, function() helpers.volume_control(5) end),
    awful.button({}, 5, function() helpers.volume_control(-5) end)
))

-- Playerctl (instancia propia solo para MPD)
local playerctl = require("module.bling").signal.playerctl.lib({
    player = {"mpd"}
})
local music_length = 0

local function load_album_art(album_path)
    if album_path and album_path ~= "" then
        local ok, img = pcall(gears.surface.load_uncached, album_path)
        if ok and img then
            music_art:set_image(img)
            return true
        end
    end
    return false
end

local function fetch_album_art_from_mpd()
    awful.spawn.easy_async_with_shell(
        'file=$(mpc --format "%file%" | head -1); [ -n "$file" ] && ffmpeg -y -i "$HOME/Music/$file" -an -vcodec copy /tmp/ncmpcpp-cover.jpg -loglevel quiet 2>/dev/null && echo "/tmp/ncmpcpp-cover.jpg" || echo "FAIL"',
        function(stdout)
            local path = stdout:match("(/tmp/ncmpcpp%-cover%.jpg)")
            if path then
                load_album_art(path)
            end
        end
    )
end

local current_album_path = nil

playerctl:connect_signal("metadata", function(_, title, artist, album_path, album, ___, player_name)
    if player_name and player_name:match("^mpd") then
        current_album_path = album_path
        local m_now = artist .. " - " .. title .. "/" .. album

        if not load_album_art(album_path) then
            fetch_album_art_from_mpd()
        end
        music_now:set_markup_silently(m_now)
    end
end)

playerctl:connect_signal("position", function(_, interval_sec, length_sec, player_name)
    if player_name and player_name:match("^mpd") then
        local pos_now = tostring(os.date("!%M:%S", math.floor(interval_sec)))
        local pos_length = tostring(os.date("!%M:%S", math.floor(length_sec)))
        local pos_markup = pos_now .. helpers.colorize_text(" / " .. pos_length, beautiful.xcolor8)

        load_album_art(current_album_path)
        music_pos:set_markup_silently(pos_markup)
        music_bar.value = (interval_sec / length_sec) * 100
        music_length = length_sec
    end
end)

playerctl:connect_signal("playback_status", function(_, playing, player_name)
    if player_name and player_name:match("^mpd") then
        if playing then
            music_play_pause_textbox:set_markup_silently(helpers.colorize_text("", beautiful.deco_blue))
        else
            music_play_pause_textbox:set_markup_silently(helpers.colorize_text("", beautiful.deco_blue))
        end
    end
end)

playerctl:connect_signal("loop_status", function(_, loop_status, player_name)
    if player_name and player_name:match("^mpd") then
        if loop_status == "none" then
            loop_textbox:set_markup_silently("")
        else
            loop_textbox:set_markup_silently("")
        end
    end
end)

playerctl:connect_signal("shuffle", function(_, shuffle, player_name)
    if player_name and player_name:match("^mpd") then
        if shuffle then
            shuffle_textbox:set_markup_silently("")
        else
            shuffle_textbox:set_markup_silently("")
        end
    end
end)

-- Single status poll (mpc status)
local function update_single_status()
    awful.spawn.easy_async_with_shell("mpc status 2>/dev/null | grep -o 'single: [a-z]*' | cut -d' ' -f2", function(stdout)
        local state = stdout:match("^%s*(.-)%s*$") or ""
        if state == "on" then
            single_textbox:set_markup_silently(helpers.colorize_text("", beautiful.deco_blue))
        else
            single_textbox:set_markup_silently("")
        end
    end)
end

local single_timer = gears.timer { timeout = 4, call_now = true, autostart = true, single_shot = false, callback = update_single_status }

local music_create_decoration = function (c)

    -- Hide default titlebar
    awful.titlebar.hide(c, beautiful.titlebar_pos)

    -- Titlebar
    awful.titlebar(c, { position = "top", size = dpi(40), bg = beautiful.xbackground }):setup {
        {
            {
                {
                    {
                        vol,
                        nil,
                        vol_slider,
                        spacing = dpi(2),
                        layout = wibox.layout.fixed.horizontal
                    },
                    stats_tooltip,
                    layout = wibox.layout.align.horizontal
                },
                top = dpi(10),
                bottom = dpi(10),
                right = dpi(10),
                left = dpi(15),
                widget = wibox.container.margin
            },
            forced_width = dpi(240),
            widget = wibox.container.background
        },
        {
            widget = music_icon
        },
		layout = wibox.layout.align.horizontal
    }

    -- Sidebar
    awful.titlebar(c, { position = "left", size = dpi(280), bg = beautiful.xbackground }):setup {
        {
            nil,
            {
                music_art_square,
                bottom = dpi(20),
                left = dpi(15),
                right = dpi(15),
                widget = wibox.container.margin
            },
            nil,
            expand = "none",
            layout = wibox.layout.align.vertical
        },
        bg = beautiful.bg_accent,
        shape = helpers.prrect(dpi(10), false, true, false, false),
        widget = wibox.container.background,
    }

    -- Toolbar
    awful.titlebar(c, { position = "bottom", size = dpi(63), bg = beautiful.bg_secondary }):setup {
        music_bar,
        {
            {
                {
                    -- Go to playlist and focus currently playing song
                    control_button(c, "", beautiful.xforeground, beautiful.icon_font_name .. "Round 14", dpi(30), function()
                        awful.spawn.with_shell("mpc -q prev")
                    end),
                    -- Toggle play pause
                    music_play_pause,
                    -- Go to list of playlists
                    control_button(c, "", beautiful.xforeground, beautiful.icon_font_name .. "Round 14", dpi(30), function()
                        awful.spawn.with_shell("mpc -q next")
                    end),
                    layout = wibox.layout.flex.horizontal
                },
                {
                    {
                        step_function = wibox.container.scroll
                            .step_functions
                            .waiting_nonlinear_back_and_forth,
                        speed = 50,
                        {
                            widget = music_now,
                        },
                        -- forced_width = dpi(110),
                        widget = wibox.container.scroll.horizontal
                    },
                    left = dpi(15),
                    right = dpi(20),
                    widget = wibox.container.margin
                },
                {
                    music_pos,
                    {
                        loop,
                        single,
                        shuffle,
                        -- Go to list of playlists
                        control_button(c, "", beautiful.xforeground, beautiful.icon_font_name .. "Round 12", dpi(30), function()
                            helpers.send_key(c, "1")
                        end),
                        -- Go to visualizer
                        control_button(c, "", beautiful.xforeground, "icomoon 12", dpi(30), function()
                            helpers.send_key(c, "8")
                        end),
                        layout = wibox.layout.flex.horizontal
                    },
                    spacing = dpi(10),
                    layout = wibox.layout.fixed.horizontal
                },
                layout = wibox.layout.align.horizontal
            },
            margins = dpi(15),
            widget = wibox.container.margin
        },
        layout = wibox.layout.align.vertical
    }

    -- Set custom decoration flags
    c.custom_decoration = { top = true, left = true, bottom = true }
end

-- Add the titlebar whenever a new music client is spawned
ruled.client.connect_signal("request::rules", function()
    ruled.client.append_rule {
        id = "music",
        rule = {instance = "music"},
        callback = music_create_decoration
    }
end)

