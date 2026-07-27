local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local naughty = require("naughty")
local helpers = require("helpers")

local wallpaper_dir = os.getenv("HOME") .. "/fondos"
local cache_file = os.getenv("HOME") .. "/.cache/wallpaper_fijo.txt"

local supported_exts = { png = true, jpg = true, jpeg = true, bmp = true, webp = true }

local function get_wallpapers()
    local files = {}
    local p = io.popen('ls -1 "' .. wallpaper_dir .. '" 2>/dev/null')
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

local function esc(s)
    return s:gsub("'", "'\\''")
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

local function hide()
    M.active = false
    pcall(awful.keygrabber.stop)
    if M.overlay then
        M.overlay.visible = false
        M.overlay = nil
    end
    M.cards = nil
    M.selected = nil
end

local function apply_wallpaper(path)
    awful.spawn.with_shell(
        "echo '" .. esc(path) .. "' > '" .. cache_file .. "' && feh --bg-fill '" .. esc(path) .. "'"
    )
    naughty.notify({ text = "Fondo aplicado", timeout = 2 })
end

function M.toggle()
    if M.active then
        hide()
        return
    end

    local wallpapers = get_wallpapers()
    if #wallpapers == 0 then
        naughty.notify({ text = "No hay imagenes en ~/fondos", timeout = 3 })
        return
    end

    M.active = true

    local screen = awful.screen.focused()
    local sgeo = screen.geometry

    local cols = math.min(#wallpapers, 6)
    local rows = math.ceil(#wallpapers / cols)

    local grid = wibox.layout.fixed.vertical()
    grid.spacing = card_spacing
    grid.expand = "none"

    local cards = {}
    local selected = 1
    local idx = 1

    for _ = 1, rows do
        local row = wibox.layout.fixed.horizontal()
        row.spacing = card_spacing
        row.expand = "center"
        for _ = 1, cols do
            if idx <= #wallpapers then
                local path = wallpapers[idx]
                local i = idx

                local inner_w = card_w - dpi(16)
                local thumb_h = card_h - dpi(38)

                local thumb = wibox.widget {
                    image = path,
                    forced_width = inner_w,
                    forced_height = thumb_h,
                    horizontal_fit_policy = "scale",
                    vertical_fit_policy = "scale",
                    upscale = true,
                    widget = wibox.widget.imagebox,
                }

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
            else
                break
            end
        end
        grid:add(row)
    end

    local function update_selection(prev)
        if prev and cards[prev] then
            cards[prev].border_color = surface_color
        end
        if cards[selected] then
            cards[selected].border_color = accent_color
        end
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
            grid,
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
        bg = bg_color,
        fg = fg_color,
        opacity = 0.95,
    }
    M.overlay:set_widget(content)

    M.cards = cards
    M.selected = selected

    update_selection(nil)
    update_counter()

    M.overlay:buttons(gears.table.join(
        awful.button({}, 4, function() nav(-1) end),
        awful.button({}, 5, function() nav(1) end),
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
        elseif key == "Return" then
            apply_wallpaper(wallpapers[selected])
            hide()
        elseif key == "Escape" then
            hide()
        end
    end)
end

return { toggle = M.toggle, hide = hide }
