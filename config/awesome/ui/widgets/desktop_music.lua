local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local gears = require("gears")
local helpers = require("helpers")
local i18n = require("i18n")

local desktop_music = {}

local ok_pc, playerctl = pcall(require, "signal.playerctl")
playerctl = ok_pc and playerctl or nil

local function create_widget(s)
    if s.desktop_music then return end
    if not playerctl then return end
    local screen_geo = s.geometry

    local base_w = 188
    local base_h = 97
    local current_scale = 1

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

    local content_margin = wibox.widget{
        content,
        margins = dpi(2),
        widget = wibox.container.margin
    }

    local container = wibox.widget{
        content_margin,
        bg = "#00000000",
        widget = wibox.container.background
    }

    local function apply_scale(scale)
        local function d(n) return math.max(1, math.floor(dpi(n * scale))) end
        local function fs(n) return math.max(6, math.floor(n * scale + 0.5)) end
        art_bg.forced_width = d(56)
        art_bg.forced_height = d(56)
        art.forced_width = d(56)
        art.forced_height = d(56)
        title.forced_width = d(120)
        title.forced_height = d(14)
        title.font = beautiful.font_name .. "bold " .. fs(9)
        artist.forced_width = d(120)
        artist.forced_height = d(12)
        artist.font = beautiful.font_name .. fs(8)
        progress.forced_width = d(130)
        progress.forced_height = d(3)
        progress.bar_height = math.max(1, math.floor(dpi(3) * scale))
        progress.color = {
            type = "linear",
            from = {0, 0},
            to = {d(130), 0},
            stops = {
                {0, beautiful.deco_cyan},
                {1, beautiful.deco_blue or beautiful.xcolor4},
            }
        }
        prev_btn.forced_width = d(22)
        prev_btn.forced_height = d(22)
        prev_btn.font = beautiful.icon_font_name .. fs(14)
        play_btn.forced_width = d(22)
        play_btn.forced_height = d(22)
        play_btn.font = beautiful.icon_font_name .. fs(16)
        next_btn.forced_width = d(22)
        next_btn.forced_height = d(22)
        next_btn.font = beautiful.icon_font_name .. fs(14)
        controls.spacing = d(4)
        top_row.spacing = d(8)
        content.spacing = d(6)
        content_margin.margins = d(2)
    end

    local pos_file = os.getenv("HOME") .. "/.config/awesome/.desktop-music-pos-" .. s.index

    local w = wibox{
        type = "desktop",
        screen = s,
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
            local dx = m.x - mx
            local nw = ow
            local nx = ox
            if rfx == "left" then nw = math.max(dpi(120), ow - dx); nx = ox + (ow - nw)
            elseif rfx == "right" then nw = math.max(dpi(120), ow + dx) end
            local scale = nw / dpi(base_w)
            current_scale = scale
            apply_scale(scale)
            local nh = math.max(dpi(30), math.floor(dpi(base_h) * scale))
            w:geometry({x = nx, y = oy, width = nw, height = nh})
            return true
        end, "bottom_right_corner")
    end

    local active_menu = nil

    local function open_settings()
        if active_menu then active_menu:hide(); active_menu = nil; return end
        active_menu = awful.menu({
            items = {
                { i18n.tr("dw.increase"), function()
                    current_scale = current_scale + 0.1
                    apply_scale(current_scale)
                    w:geometry({width = dpi(base_w * current_scale), height = dpi(base_h * current_scale)})
                    save_pos()
                end},
                { i18n.tr("dw.decrease"), function()
                    current_scale = math.max(0.5, current_scale - 0.1)
                    apply_scale(current_scale)
                    w:geometry({width = dpi(base_w * current_scale), height = dpi(base_h * current_scale)})
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

    helpers.fit_wibox(w, s)

    local f = io.open(pos_file, "r")
    if f then
        local saved = f:read("*a")
        f:close()
        local sx, sy, sw = saved:match("(-?%d+),(-?%d+),(%d+)")
        if sx then
            w.x = tonumber(sx)
            w.y = tonumber(sy)
        end
        if sw and tonumber(sw) > 0 then
            local base_w_px = dpi(base_w)
            local max_w = s.geometry.width - dpi(20)
            local scale = math.max(0.5, math.min(tonumber(sw) / base_w_px, max_w / base_w_px))
            current_scale = scale
            apply_scale(scale)
            w:geometry({ width = math.floor(base_w_px * scale), height = math.floor(dpi(base_h) * scale) })
        end
    end

    helpers.clamp_wibox_on_screen(w, s)

    s.desktop_music = w
end

screen.connect_signal("request::desktop_decoration", create_widget)

return desktop_music
