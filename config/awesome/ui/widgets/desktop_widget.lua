local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local gears = require("gears")
local helpers = require("helpers")

local desktop_widget = {}

local function unaccent(str)
    local map = {
        [0xC1] = "A", [0xC9] = "E", [0xCD] = "I", [0xD3] = "O", [0xDA] = "U",
        [0xC0] = "A", [0xC8] = "E", [0xCC] = "I", [0xD2] = "O", [0xD9] = "U",
        [0xC2] = "A", [0xCA] = "E", [0xCE] = "I", [0xD4] = "O", [0xDB] = "U",
        [0xC3] = "A", [0xD5] = "O", [0xC7] = "C", [0xD1] = "N",
        [0xE1] = "a", [0xE9] = "e", [0xED] = "i", [0xF3] = "o", [0xFA] = "u",
        [0xE0] = "a", [0xE8] = "e", [0xEC] = "i", [0xF2] = "o", [0xF9] = "u",
        [0xE2] = "a", [0xEA] = "e", [0xEE] = "i", [0xF4] = "o", [0xFB] = "u",
        [0xE3] = "a", [0xF5] = "o", [0xE7] = "c", [0xF1] = "n",
    }
    local chars = {}
    for codepoint in str:gmatch(utf8.charpattern) do
        local cp = utf8.codepoint(codepoint)
        chars[#chars+1] = map[cp] or codepoint
    end
    return table.concat(chars)
end

local function create_widget(s)
    if s.datetime_widget then return end
    local screen_geo = s.geometry

    local base_w = 180
    local base_h = 110
    local base_w_px = dpi(base_w)
    local base_h_px = dpi(base_h)

    local day_w = wibox.widget {
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }

    local date_w = wibox.widget {
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }

    local time_w = wibox.widget {
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }

    local current_scale = 1
    local color_file = os.getenv("HOME") .. "/.config/awesome/.datetime-widget-color-" .. s.index
    local text_color = "#ffffff"
    local show_date_file = os.getenv("HOME") .. "/.config/awesome/.datetime-widget-showdate-" .. s.index
    local show_time_file = os.getenv("HOME") .. "/.config/awesome/.datetime-widget-showtime-" .. s.index
    local show_date = true
    local show_time = true

    local f_c = io.open(color_file, "r")
    if f_c then
        text_color = f_c:read("*a"):match("^%s*(.-)%s*$")
        f_c:close()
        if text_color == "" or not text_color:match("^#") then
            text_color = "#ffffff"
        end
    end

    local f_sd = io.open(show_date_file, "r")
    if f_sd then
        local val = f_sd:read("*a"):match("^%s*(.-)%s*$")
        f_sd:close()
        if val == "false" then show_date = false end
    end

    local f_st = io.open(show_time_file, "r")
    if f_st then
        local val = f_st:read("*a"):match("^%s*(.-)%s*$")
        f_st:close()
        if val == "false" then show_time = false end
    end

    local function render_all()
        local ds = math.max(6, math.floor(12 * current_scale + 0.5))
        local das = math.max(4, math.floor(5 * current_scale + 0.5))
        local ts = math.max(4, math.floor(5 * current_scale + 0.5))

        local day = string.upper(unaccent(os.date("%A")))
        day = day:gsub(".", "%1 "):gsub(" $", "")
        day_w:set_markup_silently("<span font='Anurati " .. ds .. "' foreground='" .. text_color .. "' letter_spacing='400'>" .. day .. "</span>")
        date_w:set_markup_silently("<span font='Quicksand Light " .. das .. "' foreground='" .. text_color .. "'>" .. os.date("%d %B %Y") .. "</span>")
        date_w.visible = show_date
        time_w:set_markup_silently("<span font='Quicksand Light " .. ts .. "' foreground='" .. text_color .. "'>- " .. os.date("%I:%M %p") .. " -</span>")
        time_w.visible = show_time
    end

    render_all()

    gears.timer.start_new(1, function()
        render_all()
        local old_day = os.date("%A", os.time() - 86400)
        local new_day = os.date("%A")
        if old_day ~= new_day then
            local dw = day_w:get_preferred_size()
            local min_w = math.max(dpi(120), dw + dpi(16))
            if w and w.geometry then
                local g = w:geometry()
                if min_w > g.width then
                    local nh = math.floor(min_w * base_h / base_w + 0.5)
                    w:geometry({width = min_w, height = nh})
                    update_scale(min_w / base_w_px)
                end
            end
        end
        return true
    end)

    local info = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        expand = "none",
        day_w,
        date_w,
        { time_w, top = dpi(4), widget = wibox.container.margin },
    }

--[[ local resize_grip = wibox.widget {
    bg = "#ffffff22",
    forced_width = dpi(14),
    forced_height = dpi(14),
    shape = function(cr, width, height)
        gears.shape.partially_rounded_rect(cr, width, height, false, false, false, true, dpi(6))
    end,
    widget = wibox.container.background
}
]]

    local widget_bg = wibox.widget {
        nil,
        info,
        nil,
        expand = "none",
        layout = wibox.layout.align.vertical
    }

    local container_bg = wibox.widget {
        {
            widget_bg,
            margins = dpi(8),
            widget = wibox.container.margin
        },
        bg = "#00000000",
        shape = gears.shape.rounded_rect,
        widget = wibox.container.background
    }

    local function update_scale(scale)
        current_scale = scale
        render_all()
    end

    local w = wibox {
        type = "desktop",
        screen = s,
        width = base_w_px,
        height = base_h_px,
        x = screen_geo.x + screen_geo.width - dpi(220),
        y = screen_geo.y + dpi(100),
        bg = "#00000000",
        visible = true,
        border_width = 0,
        border_color = "#00000000",
        ontop = false,
        below = true,
        skip_taskbar = true,
        focusable = false
    }

    local pos_file = os.getenv("HOME") .. "/.config/awesome/.datetime-widget-pos-" .. s.index

    local function save_pos()
        local g = w:geometry()
        local f2 = io.open(pos_file, "w")
        if f2 then
            f2:write(g.x .. "," .. g.y .. "," .. g.width .. "," .. g.height)
            f2:close()
        end
    end

    local function start_move()
        local g = w:geometry()
        local mx, my = mouse.coords().x, mouse.coords().y
        local ox, oy = g.x - mx, g.y - my
        mousegrabber.run(function(m)
            if not m.buttons[1] then
                save_pos()
                return false
            end
            w.x = ox + m.x
            w.y = oy + m.y
            return true
        end, "fleur")
    end

    local function do_resize(w, g, mx, my, ow, oh, ox, oy, btn, resize_from_x, resize_from_y)
        local cursor = "fleur"
        -- Determinar el cursor basado en resize_from_x y resize_from_y
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
            if not m.buttons[btn] then
                save_pos()
                return false
            end
            local dx = m.x - mx
            local nw = ow
            local new_x = ox
            local new_y = oy

            if resize_from_x == "left" then
                nw = math.max(dpi(120), ow - dx)
                new_x = ox + (ow - nw)
            elseif resize_from_x == "right" then
                nw = math.max(dpi(120), ow + dx)
            end

            local nh = math.max(dpi(60), math.floor(nw * base_h / base_w + 0.5))

            if resize_from_y == "top" then
                new_y = oy + (oh - nh)
            end

            w:geometry({x = new_x, y = new_y, width = nw, height = nh})
            update_scale(nw / base_w_px)
            return true
        end, cursor)
    end

    local function start_resize()
        local g = w:geometry()
        local mx, my = mouse.coords().x, mouse.coords().y
        local ow, oh = g.width, g.height
        local ox, oy = g.x, g.y
        local edge = dpi(12) -- Un área de "detección" para las esquinas/bordes

        local resize_from_x = "right" -- Por defecto, redimensionar desde la derecha
        local resize_from_y = "bottom" -- Por defecto, redimensionar desde abajo

        if mx <= ox + edge then
            resize_from_x = "left"
        elseif mx >= ox + ow - edge then
            resize_from_x = "right"
        else
            resize_from_x = nil -- No redimensionar en X si está en el centro horizontal
        end

        if my <= oy + edge then
            resize_from_y = "top"
        elseif my >= oy + oh - edge then
            resize_from_y = "bottom"
        else
            resize_from_y = nil -- No redimensionar en Y si está en el centro vertical
        end

        -- Si el clic fue en el centro, forzar redimensionamiento desde la esquina inferior derecha por defecto
        if not resize_from_x and not resize_from_y then
            resize_from_x = "right"
            resize_from_y = "bottom"
        elseif not resize_from_x then -- Si solo se detectó borde vertical, redimensionar en Y
            resize_from_x = "right" -- Elegir un lado X por defecto si solo se mueve en Y
        elseif not resize_from_y then -- Si solo se detectó borde horizontal, redimensionar en X
            resize_from_y = "bottom" -- Elegir un lado Y por defecto si solo se mueve en X
        end
        
        do_resize(w, g, mx, my, ow, oh, ox, oy, 3, resize_from_x, resize_from_y)
    end

    local active_menu = nil

    local function close_settings()
        if active_menu then active_menu:hide(); active_menu = nil end
    end

    local function open_settings_menu()
        if active_menu then
            close_settings()
            return
        end

        local colors = {
            { "Blanco", "#ffffff" },
            { "Negro", "#000000" },
            { "Cyan", beautiful.deco_cyan },
            { "Azul", beautiful.deco_blue },
            { "Púrpura", beautiful.deco_purple },
            { "Verde", beautiful.deco_green },
            { "Amarillo", beautiful.deco_yellow },
            { "Rojo", beautiful.deco_red },
            { "Gris", beautiful.deco_gray },
        }

        local color_menu = {}
        for _, c in ipairs(colors) do
            table.insert(color_menu, { c[1], function()
                text_color = c[2]
                local fc = io.open(color_file, "w")
                if fc then fc:write(text_color); fc:close() end
                render_all()
            end})
        end

        active_menu = awful.menu({
            items = {
                { "Colores", color_menu },
                { "Fecha: " .. (show_date and "ON" or "OFF"), function()
                    show_date = not show_date
                    local fc = io.open(show_date_file, "w")
                    if fc then fc:write(tostring(show_date)); fc:close() end
                    render_all()
                end},
                { "Hora: " .. (show_time and "ON" or "OFF"), function()
                    show_time = not show_time
                    local fc = io.open(show_time_file, "w")
                    if fc then fc:write(tostring(show_time)); fc:close() end
                    render_all()
                end},
                { "Aumentar", function()
                    local max_w = s.geometry.width - dpi(40)
                    current_scale = math.min(max_w / base_w_px, current_scale + 0.1)
                    local nw = math.floor(base_w_px * current_scale)
                    local nh = math.floor(nw * base_h / base_w + 0.5)
                    w:geometry({width = nw, height = nh})
                    update_scale(current_scale)
                end},
                { "Disminuir", function()
                    current_scale = math.max(0.4, current_scale - 0.1)
                    local nw = math.max(dpi(120), math.floor(base_w_px * current_scale))
                    local nh = math.floor(nw * base_h / base_w + 0.5)
                    w:geometry({width = nw, height = nh})
                    update_scale(current_scale)
                end},
                { "Ocultar", function()
                    w.visible = false
                end},
            },
            theme = { width = dpi(200), font = beautiful.font_name .. "10" }
        })
        active_menu:show({ coords = { x = mouse.coords().x, y = mouse.coords().y } })
    end

    widget_bg:buttons(gears.table.join(
        awful.button({}, 3, open_settings_menu),
        awful.button({"Mod4"}, 1, start_move),
        awful.button({"Mod4"}, 3, start_resize)
    ))


    w:setup {
        container_bg,
        widget = wibox.container.background
    }

    local f = io.open(pos_file, "r")
    if f then
        local saved_data = f:read("*a")
        f:close()
        local sx, sy, sw, sh = saved_data:match("(-?%d+),(-?%d+),(-?%d+),(-?%d+)")
        if sx then
            w:geometry({x = tonumber(sx), y = tonumber(sy), width = tonumber(sw), height = tonumber(sh)})
            update_scale(tonumber(sw) / base_w_px)
        end
    end

    s.datetime_widget = w
end

screen.connect_signal("request::desktop_decoration", create_widget)

return desktop_widget