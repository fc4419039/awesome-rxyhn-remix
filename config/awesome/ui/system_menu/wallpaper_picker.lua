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

-- Mismo esquema de nombres que scripts/pregen_fondos_thumbs.sh
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

-- Genera en segundo plano las miniaturas que falten. Nunca cargamos las
-- imagenes a resolucion completa dentro de awesome (eso colgaba y mataba el WM).
local function ensure_thumbs(wallpapers)
    local missing = {}
    for _, path in ipairs(wallpapers) do
        local tp = thumb_for(path)
        if not file_exists(tp) then
            missing[#missing + 1] = "[ " .. q(tp) .. " -nt " .. q(path) .. " ] || convert "
                .. q(path) .. " -auto-orient -thumbnail 320x180 -strip -quality 82 " .. q(tp)
        end
    end
    if #missing > 0 then
        awful.spawn.with_shell("mkdir -p " .. q(thumb_dir) .. "; " .. table.concat(missing, "; "))
    end
end

local M = {}
M.active = false
M.overlay = nil

local bg_color = "#0d0d1a"
local surface_color = "#1a1a2e"
local accent_color = "#06b6d4"
local fg_color = "#e2e8f0"
local muted_color = "#3d3d5c"

local card_w = dpi(220)
local card_h = dpi(124)
local card_spacing = dpi(10)

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
    awful.spawn.with_shell(
        "echo " .. q(path) .. " > " .. q(cache_file) .. " && feh --bg-fill " .. q(path)
    )
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

    local cols = math.min(#wallpapers, 6)
    local rows = math.ceil(#wallpapers / cols)

    local row_h = card_h + dpi(12)
    local viewport_h = math.max(dpi(300), sgeo.height - dpi(260))
    local scroll_offset = 0

    local grid = wibox.layout.fixed.vertical()
    grid.spacing = card_spacing
    grid.expand = "none"

    local cards = {}
    local selected = 1
    local idx = 1
    local pending = {}

    for _ = 1, rows do
        local row = wibox.layout.fixed.horizontal()
        row.spacing = card_spacing
        row.expand = "center"
        for _ = 1, cols do
            if idx > #wallpapers then
                break
            end
            local path = wallpapers[idx]
            local i = idx

            local inner_w = card_w - dpi(16)
            local thumb_h = card_h - dpi(38)

            local tp = thumb_for(path)
            local has_thumb = file_exists(tp)

            local thumb = wibox.widget {
                image = has_thumb and tp or nil,
                forced_width = inner_w,
                forced_height = thumb_h,
                horizontal_fit_policy = "scale",
                vertical_fit_policy = "scale",
                upscale = true,
                widget = wibox.widget.imagebox,
            }
            if not has_thumb then
                pending[#pending + 1] = { box = thumb, path = tp }
            end

            local fname = path:match("([^/]+)$") or ""
            if #fname > 24 then fname = fname:sub(1, 22) .. ".." end

            local title = wibox.widget {
                markup = "<span font='" .. (beautiful.font_name or "") .. "8' color='" .. fg_color .. "'>" .. gears.string.xml_escape(fname) .. "</span>",
                align = "center",
                forced_width = inner_w,
                widget = wibox.widget.textbox,
            }

            local card_bg = wibox.widget {
                {
                    thumb,
                    title,
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(4),
                },
                margins = dpi(8),
                bg = surface_color,
                border_width = dpi(2),
                border_color = surface_color,
                shape = function(cr_s, w, h)
                    gears.shape.rounded_rect(cr_s, w, h, dpi(8))
                end,
                widget = wibox.container.background,
            }

            local card = wibox.widget {
                card_bg,
                margins = dpi(3),
                widget = wibox.container.margin,
            }

            cards[i] = card_bg

            card:buttons(gears.table.join(
                awful.button({}, 1, function()
                    apply_wallpaper(wallpapers[i])
                    hide()
                end)
            ))

            row:add(card)
            idx = idx + 1
        end
        grid:add(row)
    end

    local scroller = wibox.container.scroll.vertical(grid, 20, 100, 0, false, viewport_h,
        function(_, size, visible_size)
            if not size or not visible_size or size <= visible_size then
                scroll_offset = 0
                return 0
            end
            local max_off = math.max(0, size - visible_size)
            scroll_offset = math.max(0, math.min(scroll_offset or 0, max_off))
            return scroll_offset
        end,
        rows * row_h + viewport_h)
    scroller:pause()

    local function scroll_by(delta)
        scroll_offset = (scroll_offset or 0) + delta
        scroller:emit_signal("widget::redraw_needed")
    end

    local function ensure_selected_visible()
        local row = math.floor((selected - 1) / cols)
        local y_top = row * row_h
        local y_bot = y_top + card_h
        if y_top < scroll_offset then
            scroll_offset = y_top
        elseif y_bot > scroll_offset + viewport_h then
            scroll_offset = y_bot - viewport_h
        end
        scroller:emit_signal("widget::redraw_needed")
    end

    local function update_selection(prev)
        if prev and cards[prev] then
            cards[prev].border_color = surface_color
        end
        if cards[selected] then
            cards[selected].border_color = accent_color
        end
        ensure_selected_visible()
    end

    local header = wibox.widget {
        markup = "<span font='" .. (beautiful.font_name or "") .. "Bold 14' color='" .. fg_color .. "'>Wallpaper</span>",
        align = "center",
        widget = wibox.widget.textbox,
    }

    local counter = wibox.widget {
        align = "center",
        widget = wibox.widget.textbox,
    }

    local function update_counter()
        counter:set_markup(
            "<span font='" .. (beautiful.font_name or "") .. "10' color='" .. muted_color .. "'>" ..
            selected .. " / " .. #wallpapers .. "</span>"
        )
    end

    local function nav(dir)
        local prev = selected
        selected = selected + dir
        if selected > #wallpapers then selected = 1 end
        if selected < 1 then selected = #wallpapers end
        update_selection(prev)
        update_counter()
    end

    local random_btn = wibox.widget {
        markup = helpers.colorize_text("  Random", fg_color),
        font = beautiful.font_name .. "10",
        align = "center",
        valign = "center",
        forced_width = dpi(100),
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

    local apply_btn = wibox.widget {
        markup = helpers.colorize_text("  Aplicar", accent_color),
        font = beautiful.font_name .. "10",
        align = "center",
        valign = "center",
        forced_width = dpi(100),
        forced_height = dpi(32),
        widget = wibox.widget.textbox,
    }
    local apply_bg = wibox.container.background()
    apply_bg:set_widget(apply_btn)
    apply_bg.bg = surface_color
    apply_bg.shape = helpers.rrect(dpi(6))
    apply_bg:connect_signal("mouse::enter", function() apply_bg.bg = "#252840" end)
    apply_bg:connect_signal("mouse::leave", function() apply_bg.bg = surface_color end)
    apply_bg:buttons(gears.table.join(
        awful.button({}, 1, function()
            apply_wallpaper(wallpapers[selected])
            hide()
        end)
    ))

    local close_btn = wibox.widget {
        markup = helpers.colorize_text(" ✕ ", "#f87171"),
        font = beautiful.font_name .. "10",
        align = "center",
        valign = "center",
        forced_width = dpi(40),
        forced_height = dpi(32),
        widget = wibox.widget.textbox,
    }
    local close_bg = wibox.container.background()
    close_bg:set_widget(close_btn)
    close_bg.bg = surface_color
    close_bg.shape = helpers.rrect(dpi(6))
    close_bg:connect_signal("mouse::enter", function() close_bg.bg = "#4c1d25" end)
    close_bg:connect_signal("mouse::leave", function() close_bg.bg = surface_color end)
    close_bg:buttons(gears.table.join(
        awful.button({}, 1, function() hide() end)
    ))

    local nav_bar = wibox.widget {
        {
            nil,
            {
                random_bg,
                apply_bg,
                close_bg,
                spacing = dpi(6),
                layout = wibox.layout.fixed.horizontal,
            },
            nil,
            expand = "none",
            layout = wibox.layout.align.horizontal,
        },
        margins = { left = dpi(12), right = dpi(12), bottom = dpi(10), top = dpi(4) },
        widget = wibox.container.margin,
    }

    local content = wibox.widget {
        {
            header,
            counter,
            scroller,
            nav_bar,
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(12),
        },
        valign = "center",
        halign = "center",
        widget = wibox.container.place,
    }

    M.overlay = wibox {
        visible = true,
        ontop = true,
        type = "dock",
        screen = screen,
        width = sgeo.width,
        height = sgeo.height,
        x = sgeo.x,
        y = sgeo.y,
        bg = bg_color .. "b3",
        fg = fg_color,
    }
    M.overlay:set_widget(content)

    M.cards = cards
    M.selected = selected

    update_selection(nil)
    update_counter()

    M.overlay:buttons(gears.table.join(
        awful.button({}, 4, function() scroll_by(-row_h) end),
        awful.button({}, 5, function() scroll_by(row_h) end),
        awful.button({}, 2, function() nav(-cols) end),
        awful.button({}, 3, function() nav(cols) end)
    ))

    awful.keygrabber.run(function(mod, key, event)
        if event ~= "press" then return end
        if key == "Right" or key == "l" then
            nav(1)
        elseif key == "Left" or key == "h" then
            nav(-1)
        elseif key == "Down" or key == "j" then
            nav(cols)
        elseif key == "Up" or key == "k" then
            nav(-cols)
        elseif key == "Page_Down" then
            scroll_by(viewport_h)
        elseif key == "Page_Up" then
            scroll_by(-viewport_h)
        elseif key == "Return" then
            apply_wallpaper(wallpapers[selected])
            hide()
        elseif key == "Escape" then
            hide()
        end
    end)

    if #pending > 0 then
        M.pending_thumbs = pending
        M.thumb_timer = gears.timer({
            timeout = 0.15,
            autostart = false,
            callback = function()
                local remaining = 0
                for _, t in ipairs(M.pending_thumbs or {}) do
                    if not t.done and file_exists(t.path) then
                        t.box.image = t.path
                        t.done = true
                    end
                    if not t.done then remaining = remaining + 1 end
                end
                if remaining == 0 then stop_thumb_timer() end
            end,
        })
        M.thumb_timer:start()
    end
end

function M.toggle()
    if M.active then
        hide()
        return
    end
    local ok, err = pcall(show_menu)
    if not ok then
        hide()
        naughty.notify({ text = "Error al abrir el selector: " .. tostring(err), timeout = 5 })
    end
end

return { toggle = M.toggle, hide = hide }
