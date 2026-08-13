local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local naughty = require("naughty")
local helpers = require("helpers")

local wallpaper_dir = os.getenv("HOME") .. "/fondos"
local thumb_dir = os.getenv("HOME") .. "/.cache/fondos_thumb"
local sddm_bg_dir = "/usr/share/sddm/backgrounds"
local sddm_bg_file = sddm_bg_dir .. "/sddm_wallpaper.jpg"

local supported_exts = { png = true, jpg = true, jpeg = true, bmp = true, webp = true }

local function file_exists(path)
    local f = io.open(path, "r")
    if f then f:close(); return true end
    return false
end

local function q(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function thumb_for(path)
    local name = path:match("([^/]+)$") or path
    name = name:gsub("%.[^%.]+$", ""):gsub("[^%w._%-]", "_")
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

local surface_color = "#162026"
local accent_color = "#06b6d4"
local fg_color = "#e2e8f0"

local cols = 2
local card_w = dpi(220)
local card_h = dpi(124)
local card_spacing = dpi(10)
local row_h = card_h + dpi(32)

local function hide()
    M.active = false
    pcall(awful.keygrabber.stop)
    if M.overlay then
        M.overlay.visible = false
        M.overlay = nil
    end
end

local function dir_writable(dir)
    local test = dir .. "/.sddm_write_test"
    local f = io.open(test, "w")
    if not f then return false end
    f:close()
    os.remove(test)
    return true
end

local function apply_sddm(path)
    local convert_bin = "/usr/bin/convert"
    local converted = q(sddm_bg_file)
    local inner = convert_bin .. " " .. q(path) .. " -auto-orient -resize 1920x1080^ -gravity center -extent 1920x1080 " .. converted
    if not file_exists(convert_bin) then
        inner = "cp -f " .. q(path) .. " " .. converted
    end

    local cmd
    if dir_writable(sddm_bg_dir) then
        cmd = inner
    else
        cmd = "pkexec /bin/sh -c " .. q(inner)
    end

    awful.spawn.easy_async_with_shell(cmd, function(_, _, reason, exitcode)
        if exitcode == 0 then
            naughty.notify({ text = "Fondo SDDM cambiado (requiere reinicio)", timeout = 4 })
        else
            naughty.notify({ text = "ERROR: no se pudo cambiar el fondo SDDM (código " .. tostring(exitcode) .. ")", timeout = 6 })
        end
    end)
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

    local rows = math.ceil(#wallpapers / cols)
    local viewport_h = sgeo.height - dpi(150)
    local scroll_offset = 0

    local grid = wibox.layout.fixed.vertical()
    grid.spacing = card_spacing

    local cards = {}
    local selected = 1

    local row
    for i, path in ipairs(wallpapers) do
        if (i - 1) % cols == 0 then
            row = wibox.layout.fixed.horizontal()
            row.spacing = card_spacing
            grid:add(row)
        end

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
                apply_sddm(path)
                hide()
            end)
        ))

        row:add(card)
    end

    local function update_visibility()
        for i, card in ipairs(cards) do
            local r = math.floor((i - 1) / cols)
            local y_top = r * row_h
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
        function(_, size, visible_size)
            if size <= visible_size then scroll_offset = 0; return 0 end
            scroll_offset = math.max(0, math.min(scroll_offset, size - visible_size))
            update_visibility()
            return scroll_offset
        end,
        rows * row_h + viewport_h)

    local function scroll_by(delta)
        scroll_offset = math.max(0, math.min(scroll_offset + delta, (rows * row_h) - viewport_h))
        scroller:emit_signal("widget::redraw_needed")
        update_visibility()
    end

    local function update_selection()
        for i, card in ipairs(cards) do
            card.border_color = (i == selected) and accent_color or surface_color
        end
        local r = math.floor((selected - 1) / cols)
        local y_top = r * row_h
        local y_bot = y_top + card_h
        if y_top < scroll_offset then scroll_offset = y_top end
        if y_bot > scroll_offset + viewport_h then scroll_offset = y_bot - viewport_h end
        scroller:emit_signal("widget::redraw_needed")
    end

    local function nav(dir)
        selected = math.max(1, math.min(#wallpapers, selected + dir))
        update_selection()
    end

    M.overlay = wibox {
        visible = true,
        ontop = true,
        type = "dialog",
        screen = screen,
        width = dpi(525),
        height = sgeo.height - dpi(30),
        x = sgeo.x + dpi(64),
        y = dpi(15),
        bg = "#0a1419b3",
        shape = helpers.rrect(dpi(14)),
    }

    M.overlay:set_widget(wibox.widget{
        {
            { markup = "<span font='Bold 14' color='" .. fg_color .. "'>SDDM Wallpaper</span>", widget = wibox.widget.textbox, align = "center" },
            scroller,
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
        if key == "Down" or key == "j" then nav(cols)
        elseif key == "Up" or key == "k" then nav(-cols)
        elseif key == "Right" or key == "l" then nav(1)
        elseif key == "Left" or key == "h" then nav(-1)
        elseif key == "Page_Down" then scroll_by(viewport_h)
        elseif key == "Page_Up" then scroll_by(-viewport_h)
        elseif key == "Return" then apply_sddm(wallpapers[selected]); hide()
        elseif key == "Escape" then hide()
        end
    end)
end

function M.toggle()
    if M.active then hide() else show_menu() end
end

return { toggle = M.toggle, hide = hide }
