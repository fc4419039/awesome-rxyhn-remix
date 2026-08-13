local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local naughty = require("naughty")
local helpers = require("helpers")

local wallpaper_dir = os.getenv("HOME") .. "/fondos"
local cache_file = os.getenv("HOME") .. "/.cache/wallpaper_fijo.txt"
local thumb_dir = os.getenv("HOME") .. "/.cache/fondos_thumb"

local supported_exts = { png = true, jpg = true, jpeg = true, bmp = true, webp = true }

local function file_exists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

local function q(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function thumb_for(path)
    local name = path:match("([^/]+)$") or path
    name = name:gsub("%.[^%.]+$", "")
    name = name:gsub("[^%w._%-]", "_")
    return thumb_dir .. "/" .. name .. ".jpg"
end

local function get_wallpapers()
    local files = {}
    local p = io.popen('ls -1 ' .. q(wallpaper_dir) .. ' 2>/dev/null')
    if p then
        for name in p:lines() do
            local ext = name:match("%.([^%.]+)$")
            if ext and supported_exts[ext:lower()] then
                files[#files + 1] = wallpaper_dir .. "/" .. name
            end
        end
        p:close()
    end
    table.sort(files)
    return files
end

local function ensure_thumbs(wallpapers)
    local missing = {}
    for _, path in ipairs(wallpapers) do
        local tp = thumb_for(path)
        if not file_exists(tp) then
            missing[#missing + 1] = "convert " .. q(path) .. " -auto-orient -thumbnail 320x180 -strip -quality 82 " .. q(tp)
        end
    end
    if #missing > 0 then
        awful.spawn.with_shell("mkdir -p " .. q(thumb_dir) .. "; ( " .. table.concat(missing, " & ") .. " ) &")
    end
end

local M = {}
M.active = false
M.overlay = nil

local bg_color = "#0a1419"
local surface_color = "#162026"
local accent_color = "#06b6d4"
local fg_color = "#e2e8f0"
local muted_color = "#666c79"

local card_w = dpi(220)
local card_h = dpi(124)
local card_spacing = dpi(10)
-- Pitch real entre filas: la tarjeta (imagen + margen del container.margin 2*3)
-- mas el spacing del grid. OJO: wibox.container.background NO soporta 'margins',
-- asi que el padding del card_bg se ignora y no suma altura.
local row_h = card_h + dpi(6) + card_spacing

local function stop_thumb_timer()
    if M.thumb_timer then
        M.thumb_timer:stop()
        M.thumb_timer = nil
    end
    M.pending_thumbs = nil
end

local function hide()
    M.active = false
    pcall(awful.keygrabber.stop)
    stop_thumb_timer()
    if M.overlay then
        M.overlay.visible = false
        M.overlay = nil
    end
    M.cards = nil
    M.selected = nil
end

local function apply_wallpaper(path)
    awful.spawn.with_shell("echo " .. q(path) .. " > " .. q(cache_file) .. " && feh --bg-fill " .. q(path))
    naughty.notify({ text = "Fondo aplicado", timeout = 2 })
end

local function show_menu()
    local wallpapers = get_wallpapers()
    if #wallpapers == 0 then
        naughty.notify({ text = "No hay imagenes en ~/fondos", timeout = 3 })
        return
    end

    local screen = awful.screen.focused()
    if not screen then return end
    local sgeo = screen.geometry

    M.active = true
    ensure_thumbs(wallpapers)

    local rows = #wallpapers
    local viewport_h = sgeo.height - dpi(150)

    local grid = wibox.layout.fixed.vertical()
    grid.spacing = card_spacing

    local cards = {}
    local selected = 1

    for i, path in ipairs(wallpapers) do
        local tp = thumb_for(path)
        local thumb = wibox.widget {
            forced_width = card_w,
            forced_height = card_h,
            horizontal_fit_policy = "cover",
            vertical_fit_policy = "cover",
            widget = wibox.widget.imagebox,
        }

        local card_bg = wibox.widget {
            thumb,
            margins = dpi(8),
            bg = surface_color,
            border_width = dpi(2),
            border_color = surface_color,
            shape = helpers.rrect(dpi(8)),
            widget = wibox.container.background,
        }

        card_bg.thumb_widget = thumb
        card_bg.thumb_path = tp
        card_bg.loaded = false
        cards[i] = card_bg

        local card = wibox.widget {
            card_bg,
            margins = dpi(3),
            widget = wibox.container.margin,
        }

        card:buttons(gears.table.join(
            awful.button({}, 1, function()
                apply_wallpaper(path)
                hide()
            end)
        ))

        grid:add(card)
    end

    -- Precarga inmediata de miniaturas para que no tarden al hacer scroll
    for i, card in ipairs(cards) do
        if file_exists(card.thumb_path) then
            card.thumb_widget.image = card.thumb_path
            card.loaded = true
        end
    end

    local scroll_offset = 0

    local function update_visibility()
        for i, card in ipairs(cards) do
            local y_top = (i - 1) * row_h
            local y_bot = y_top + card_h
            if y_bot >= scroll_offset and y_top <= scroll_offset + viewport_h then
                if not card.loaded and file_exists(card.thumb_path) then
                    card.thumb_widget.image = card.thumb_path
                    card.loaded = true
                end
            end
        end
    end

    local scroller = wibox.container.scroll.vertical(grid, 20, 100, 0, false, viewport_h,
        function()
            update_visibility()
            return scroll_offset
        end,
        rows * row_h + viewport_h)

    local function update_selection()
        for i, card in ipairs(cards) do
            card.border_color = (i == selected) and accent_color or surface_color
        end
        local max_off = math.max(0, (rows * row_h) - viewport_h)
        local y_top = (selected - 1) * row_h
        local y_bot = y_top + card_h
        if y_top < scroll_offset then scroll_offset = y_top end
        if y_bot > scroll_offset + viewport_h then scroll_offset = y_bot - viewport_h end
        scroll_offset = math.max(0, math.min(scroll_offset, max_off))
        scroller:emit_signal("widget::redraw_needed")
    end

    local function nav(dir)
        selected = math.max(1, math.min(#wallpapers, selected + dir))
        update_selection()
    end

    local function scroll_by(dir)
        local page = math.max(1, math.floor(viewport_h / row_h))
        nav(dir * page)
    end

    M.overlay = wibox {
        visible = true,
        ontop = true,
        type = "dialog",
        screen = screen,
        width = dpi(300),
        height = sgeo.height - dpi(30),
        x = sgeo.x + dpi(64),
        y = dpi(15),
        bg = "#0a1419b3",
        shape = helpers.rrect(dpi(14)),
    }
    local random_btn = wibox.widget {
        markup = helpers.colorize_text("  Random", fg_color),
        font = beautiful.font_name .. "10",
        align = "center",
        valign = "center",
        forced_width = dpi(120),
        forced_height = dpi(32),
        widget = wibox.widget.textbox,
    }
    local random_bg = wibox.container.background()
    random_bg:set_widget(random_btn)
    random_bg.bg = surface_color
    random_bg.shape = helpers.rrect(dpi(6))
    random_bg:connect_signal("mouse::enter", function() random_bg.bg = "#252840" end)
    random_bg:connect_signal("mouse::leave", function() random_bg.bg = surface_color end)
    random_bg:buttons(gears.table.join(
        awful.button({}, 1, function()
            os.remove(cache_file)
            awful.spawn.with_shell(os.getenv("HOME") .. "/.config/cambiar_fondo.sh")
            hide()
            naughty.notify({ text = "Fondo aleatorio activado", timeout = 2 })
        end)
    ))

    M.overlay:set_widget(wibox.widget{
        {
            { markup = "<span font='Bold 14' color='"..fg_color.."'>Wallpaper</span>", widget = wibox.widget.textbox, align="center" },
            scroller,
            {
                random_bg,
                widget = wibox.container.place,
            },
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(10)
        },
        margins = dpi(15),
        widget = wibox.container.margin
    })

    update_selection()
    update_visibility()

    awful.keygrabber.run(function(_, key, event)
        if event ~= "press" then return end
        if key == "Down" or key == "j" then nav(1)
        elseif key == "Up" or key == "k" then nav(-1)
        elseif key == "Page_Down" then scroll_by(1)
        elseif key == "Page_Up" then scroll_by(-1)
        elseif key == "Return" then apply_wallpaper(wallpapers[selected]); hide()
        elseif key == "Escape" then hide()
        end
    end)
end

function M.toggle()
    if M.active then hide() else show_menu() end
end

return { toggle = M.toggle, hide = hide }
