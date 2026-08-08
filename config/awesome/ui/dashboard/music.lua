-- Standard awesome library
local gears = require("gears")
local awful = require("awful")

-- Theme handling library
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

-- Widget library
local wibox = require("wibox")

-- Helpers
local helpers = require("helpers")


-- Music
----------

local music_text = wibox.widget{
    font = beautiful.font_name .. "medium 8",
    valign = "center",
    widget = wibox.widget.textbox
}

local music_art = wibox.widget {
    image = gears.filesystem.get_configuration_dir() .. "theme/assets/no_music.png",
    resize = true,
    widget = wibox.widget.imagebox
}

local music_art_container = wibox.widget {
    music_art,
    forced_height = dpi(115),
    forced_width = dpi(195),
    widget = wibox.container.background
}

local filter_color = {
    type = 'linear',
    from = {0, 0},
    to = {0, 115},
    stops = {{0, beautiful.dashboard_box_bg:sub(1, 7) .. "00"}, {1, beautiful.dashboard_box_bg:sub(1, 7) .. "99"}}
}

local music_art_filter = wibox.widget {
    {
        bg = filter_color,
    forced_height = dpi(115),
    forced_width = dpi(195),
    widget = wibox.container.background
    },
    direction = "east",
    widget = wibox.container.rotate
}

local music_title = wibox.widget{
    font = beautiful.font_name .. "medium 9",
    valign = "center",
    widget = wibox.widget.textbox
}

local music_artist = wibox.widget{
    font = "Anurati 9",
    valign = "center",
    widget = wibox.widget.textbox
}

local music_pos = wibox.widget{
    font = beautiful.font_name .. "medium 8",
    valign = "center",
    widget = wibox.widget.textbox
}


-- helper para redimensionar imagen a 115x115 y asignarla al widget
local function set_art_image(path)
    local resized = os.tmpname() .. ".png"
    awful.spawn.easy_async_with_shell(
        "magick convert '" .. path .. "' -resize 195x115! '" .. resized .. "' 2>/dev/null",
        function()
            music_art:set_image(gears.surface.load_uncached(resized))
        end
    )
end

-- helper para obtener thumbnail de YouTube
local function get_youtube_thumb(player)
    awful.spawn.easy_async_with_shell(
        "playerctl --player='" .. player .. "' metadata xesam:url 2>/dev/null",
        function(stdout)
            local video_id = stdout:match("[?&]v=([%w_-]+)")
            if video_id then
                local thumb_url = "https://img.youtube.com/vi/" .. video_id .. "/hqdefault.jpg"
                local art_path = os.tmpname()
                awful.spawn.with_line_callback(
                    "curl -L -s '" .. thumb_url .. "' -o '" .. art_path .. "' 2>/dev/null",
                    {
                        exit = function()
                            local f = io.open(art_path, "r")
                            if f then
                                local size = f:seek("end")
                                f:close()
                                if size and size > 0 then
                                    set_art_image(art_path)
                                end
                            end
                        end
                    }
                )
            end
        end
    )
end

-- playerctl
---------------

local playerctl = require("module.bling").signal.playerctl.cli({
  player = {"firefox", "spotify", "%any"}
})

playerctl:connect_signal("metadata", function(_, title, artist, album_path, __, ___)
    if title == "" then title = i18n.tr("dash.nothing_playing") end
    if artist == "" then artist = i18n.tr("dash.nothing_playing") end

    if album_path and album_path ~= "" then
        set_art_image(album_path)
    else
        local no_music = gears.filesystem.get_configuration_dir() .. "theme/assets/no_music.png"
        set_art_image(no_music)
        get_youtube_thumb(___ or "firefox")
    end

    music_title:set_markup_silently(helpers.colorize_text(title, beautiful.xforeground .. "b3"))
    music_artist:set_markup_silently('<span letter_spacing="2000">' .. helpers.colorize_text(helpers.upper_no_accents(artist), beautiful.xforeground .. "e6") .. '</span>')
end)

playerctl:connect_signal("playback_status", function(_, playing, __)
    if playing then
        music_text:set_markup_silently(helpers.colorize_text(i18n.tr("dash.now_playing"), beautiful.xforeground .. "cc"))
    else
        music_text:set_markup_silently(helpers.colorize_text(i18n.tr("dash.music"), beautiful.xforeground .. "cc"))
    end
end)

playerctl:connect_signal("position", function(_, interval_sec, length_sec, player_name)
    local pos_now = tostring(os.date("!%M:%S", math.floor(interval_sec)))
    local pos_length = tostring(os.date("!%M:%S", math.floor(length_sec)))
    local pos_markup = helpers.colorize_text(pos_now .. " / " .. pos_length, beautiful.xforeground .. "66")

    music_pos:set_markup_silently(pos_markup)
end)


local music = wibox.widget{
    {
        {
            {
                music_art_container,
                music_art_filter,
                layout = wibox.layout.stack
            },
            {
                {
                    music_text,
                    {
                        {
                            {
                                step_function = wibox.container.scroll
                                    .step_functions
                                    .waiting_nonlinear_back_and_forth,
                                speed = 50,
                                {
                                    widget = music_artist,
                                },
                                forced_width = dpi(170),
                                widget = wibox.container.scroll.horizontal
                            },
                            {
                                step_function = wibox.container.scroll
                                    .step_functions
                                    .waiting_nonlinear_back_and_forth,
                                speed = 50,
                                {
                                    widget = music_title,
                                },
                                forced_width = dpi(170),
                                widget = wibox.container.scroll.horizontal
                            },
                            layout = wibox.layout.fixed.vertical
                        },
                        bottom = dpi(15),
                        widget = wibox.container.margin
                    },
                    music_pos,
                    expand = "none",
                    layout = wibox.layout.align.vertical
                },
                top = dpi(6),
                bottom = dpi(6),
                left = dpi(5),
                right = dpi(5),
                widget = wibox.container.margin
            },
            layout = wibox.layout.stack
        },
        bg = beautiful.dashboard_box_bg,
        shape = helpers.rrect(dpi(5)),
        forced_width = dpi(195),
        forced_height = dpi(115),
        widget = wibox.container.background
    },
    margins = dpi(5),
    widget = wibox.container.margin
}

return music
