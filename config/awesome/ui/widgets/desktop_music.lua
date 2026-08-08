local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local gears = require("gears")
local helpers = require("helpers")

local desktop_music = {}

local ok_pc, playerctl = pcall(require, "signal.playerctl")
playerctl = ok_pc and playerctl or nil

local function create_widget(s)
    if s.desktop_music then return end
    if not playerctl then return end
    local screen_geo = s.geometry

    local art_bg = wibox.widget{
        forced_width = dpi(56),
        forced_height = dpi(56),
        shape = gears.shape.circle,
        bg = beautiful.xcolor8 .. "22",
        widget = wibox.container.background
    }

    local art = wibox.widget{
        image = nil,
        resize = true,
        forced_width = dpi(56),
        forced_height = dpi(56),
        clip_shape = gears.shape.circle,
        widget = wibox.widget.imagebox
    }

    local art_container = wibox.widget{
        art,
        widget = wibox.container.place
    }

    local art_stack = wibox.widget{
        art_bg,
        art_container,
        layout = wibox.layout.stack
    }

    local title = wibox.widget{
        font = beautiful.font_name .. "bold 9",
        markup = helpers.colorize_text(i18n.tr("dash.nothing_playing"), beautiful.dashboard_fg),
        align = "left",
        valign = "bottom",
        forced_width = dpi(120),
        forced_height = dpi(14),
        widget = wibox.widget.textbox
    }

    local artist = wibox.widget{
        font = beautiful.font_name .. "8",
        markup = helpers.colorize_text("", beautiful.dashboard_fg),
        align = "left",
        valign = "top",
        forced_width = dpi(120),
        forced_height = dpi(12),
        widget = wibox.widget.textbox
    }

    local progress = wibox.widget{
        value = 0,
        max_value = 100,
        color = {
            type = "linear",
            from = {0, 0},
            to = {dpi(130), 0},
            stops = {
                {0, beautiful.deco_cyan},
                {1, beautiful.deco_blue or beautiful.xcolor4},
            }
        },
        background_color = beautiful.xcolor8 .. "33",
        shape = gears.shape.rounded_bar,
        bar_height = dpi(3),
        forced_width = dpi(130),
        forced_height = dpi(3),
        widget = wibox.widget.progressbar
    }

    local prev_btn = wibox.widget{
        font = beautiful.icon_font_name .. "14",
        markup = helpers.colorize_text("⏮", beautiful.xcolor8 .. "aa"),
        align = "center",
        valign = "center",
        forced_width = dpi(22),
        forced_height = dpi(22),
        widget = wibox.widget.textbox
    }

    local play_btn = wibox.widget{
        font = beautiful.icon_font_name .. "16",
        markup = helpers.colorize_text("▶", beautiful.deco_cyan),
        align = "center",
        valign = "center",
        forced_width = dpi(22),
        forced_height = dpi(22),
        widget = wibox.widget.textbox
    }

    local next_btn = wibox.widget{
        font = beautiful.icon_font_name .. "14",
        markup = helpers.colorize_text("⏭", beautiful.xcolor8 .. "aa"),
        align = "center",
        valign = "center",
        forced_width = dpi(22),
        forced_height = dpi(22),
        widget = wibox.widget.textbox
    }

    for _, btn in ipairs({prev_btn, play_btn, next_btn}) do
        helpers.add_hover_cursor(btn, "hand2")
        btn:connect_signal("mouse::enter", function()
            btn.markup = btn.markup:gsub('foreground=\'[^\']+', "foreground='" .. beautiful.xforeground)
        end)
        btn:connect_signal("mouse::leave", function()
            if btn == play_btn then
                btn.markup = helpers.colorize_text("▶", beautiful.deco_cyan)
            else
                btn.markup = helpers.colorize_text(btn == prev_btn and "⏮" or "⏭", beautiful.xcolor8 .. "aa")
            end
        end)
    end

    prev_btn:buttons(gears.table.join(awful.button({}, 1, function() awful.spawn("playerctl previous") end)))
    play_btn:buttons(gears.table.join(awful.button({}, 1, function() awful.spawn("playerctl play-pause") end)))
    next_btn:buttons(gears.table.join(awful.button({}, 1, function() awful.spawn("playerctl next") end)))

    local controls = wibox.widget{
        prev_btn, play_btn, next_btn,
        spacing = dpi(4),
        layout = wibox.layout.fixed.horizontal
    }

    local info = wibox.widget{
        title, artist,
        spacing = dpi(1),
        layout = wibox.layout.fixed.vertical
    }

    local top_row = wibox.widget{
        art_stack, info,
        spacing = dpi(8),
        layout = wibox.layout.fixed.horizontal
    }

    local function truncate(str, max)
        if not str then return "" end
        if #str > max then return str:sub(1, max) .. "..." end
        return str
    end

    playerctl:connect_signal("metadata", function(_, t, a, album_path)
        if t and t ~= "" then
            title.markup = helpers.colorize_text(truncate(t, 20), beautiful.xforeground)
        else
            title.markup = helpers.colorize_text(i18n.tr("dash.nothing_playing"), beautiful.dashboard_fg)
            artist.markup = ""
        end
        if a and a ~= "" then
            artist.markup = helpers.colorize_text(truncate(a, 22), beautiful.dashboard_fg)
        end
        if album_path and album_path ~= "" then
            art:set_image(gears.surface.load_uncached(album_path))
        else
            art:set_image(nil)
        end
    end)

    playerctl:connect_signal("playback_status", function(_, status)
        if status == "playing" then
            play_btn.markup = helpers.colorize_text("⏸", beautiful.deco_cyan)
        else
            play_btn.markup = helpers.colorize_text("▶", beautiful.deco_cyan)
        end
    end)

    playerctl:connect_signal("position", function(_, interval_sec, length_sec)
        if length_sec and length_sec > 0 then
            progress.value = (interval_sec / length_sec) * 100
        end
    end)

    local content = wibox.widget{
        top_row, progress, controls,
        spacing = dpi(6),
        layout = wibox.layout.fixed.vertical
    }

    local container = wibox.widget{
        {
            content,
            margins = dpi(8),
            widget = wibox.container.margin
        },
        bg = "#00000000",
        widget = wibox.container.background
    }

    local pos_file = os.getenv("HOME") .. "/.config/awesome/.desktop-music-pos-" .. s.index

    local w = wibox{
        type = "desktop",
        screen = s,
        width = dpi(210),
        height = dpi(110),
        x = screen_geo.x + dpi(80),
        y = screen_geo.y + screen_geo.height - dpi(340),
        bg = "#00000000",
        visible = true,
        border_width = 0,
        border_color = "#00000000",
        ontop = false,
        below = true,
        skip_taskbar = true,
        focusable = false
    }

    local function save_pos()
        local g = w:geometry()
        local f = io.open(pos_file, "w")
        if f then
            f:write(g.x .. "," .. g.y .. "," .. g.width .. "," .. g.height)
            f:close()
        end
    end

    local function start_move()
        local g = w:geometry()
        local mx, my = mouse.coords().x, mouse.coords().y
        local ox, oy = g.x - mx, g.y - my
        mousegrabber.run(function(m)
            if not m.buttons[1] then save_pos(); return false end
            w.x = ox + m.x
            w.y = oy + m.y
            return true
        end, "fleur")
    end

    local function start_resize()
        local g = w:geometry()
        local mx, my = mouse.coords().x, mouse.coords().y
        local ow, oh = g.width, g.height
        local ox, oy = g.x, g.y
        local edge = dpi(10)
        local rfx, rfy = "right", "bottom"
        if mx <= ox + edge then rfx = "left" elseif mx < ox + ow - edge then rfx = nil end
        if my <= oy + edge then rfy = "top" elseif my < oy + oh - edge then rfy = nil end
        if not rfx and not rfy then rfx = "right"; rfy = "bottom"
        elseif not rfx then rfx = "right" elseif not rfy then rfy = "bottom" end

        mousegrabber.run(function(m)
            if not m.buttons[3] then save_pos(); return false end
            local dx, dy = m.x - mx, m.y - my
            local nw, nh = ow, oh
            local nx, ny = ox, oy
            if rfx == "left" then nw = math.max(dpi(160), ow - dx); nx = ox + (ow - nw)
            elseif rfx == "right" then nw = math.max(dpi(160), ow + dx) end
            if rfy == "top" then nh = math.max(dpi(80), oh - dy); ny = oy + (oh - nh)
            elseif rfy == "bottom" then nh = math.max(dpi(80), oh + dy) end
            w:geometry({x = nx, y = ny, width = nw, height = nh})
            return true
        end, "bottom_right_corner")
    end

    local active_menu = nil

    local function open_settings()
        if active_menu then active_menu:hide(); active_menu = nil; return end
        active_menu = awful.menu({
            items = {
                { i18n.tr("dw.increase"), function()
                    local g = w:geometry()
                    w:geometry({width = g.width + dpi(20), height = g.height + dpi(15)})
                    save_pos()
                end},
                { i18n.tr("dw.decrease"), function()
                    local g = w:geometry()
                    w:geometry({width = math.max(dpi(140), g.width - dpi(20)), height = math.max(dpi(80), g.height - dpi(15))})
                    save_pos()
                end},
                { i18n.tr("dw.hide"), function()
                    w.visible = false
                end},
            },
            theme = { width = dpi(160), font = beautiful.font_name .. "10" }
        })
        active_menu:show({ coords = { x = mouse.coords().x, y = mouse.coords().y } })
    end

    container:buttons(gears.table.join(
        awful.button({}, 3, open_settings),
        awful.button({"Mod4"}, 1, start_move),
        awful.button({"Mod4"}, 3, start_resize)
    ))

    w:setup{
        container,
        widget = wibox.container.background
    }

    local f = io.open(pos_file, "r")
    if f then
        local saved = f:read("*a")
        f:close()
        local sx, sy, sw, sh = saved:match("(-?%d+),(-?%d+),(-?%d+),(-?%d+)")
        if sx then
            w:geometry({x = tonumber(sx), y = tonumber(sy), width = tonumber(sw), height = tonumber(sh)})
        end
    end

    s.desktop_music = w
end

screen.connect_signal("request::desktop_decoration", create_widget)

return desktop_music
