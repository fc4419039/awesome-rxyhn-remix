local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local gears = require("gears")
local rubato = require("module.rubato")
local helpers = require("helpers")
local cairo = require("lgi").cairo
local dpi = beautiful.xresources.apply_dpi

local M = {}
M.active = false
M.overlay = nil

pcall(awful.keygrabber.stop)

client.connect_signal("property::active", function(c)
    if not c.active and c.content then
        pcall(function()
            c.prev_content = gears.surface.duplicate_surface(c.content)
        end)
    end
end)

local bg_color = "#0d0d1a"
local surface_color = "#1a1a2e"
local accent_color = "#06b6d4"
local fg_color = "#e2e8f0"
local muted_color = "#3d3d5c"

local card_w = dpi(220)
local card_h = dpi(170)
local card_spacing = dpi(12)

local function get_all_clients()
    local seen = {}
    local clients = {}
    for _, t in ipairs(awful.screen.focused().tags) do
        for _, c in ipairs(t:clients()) do
            if not seen[c.window] then
                seen[c.window] = true
                clients[#clients + 1] = c
            end
        end
    end
    return clients
end

local function get_client_thumbnail(c, inner_w, thumb_h)
    local content = nil
    if c.active then
        pcall(function() content = gears.surface(c.content) end)
    end
    if not content and c.prev_content then
        pcall(function() content = gears.surface(c.prev_content) end)
    end
    if not content then return nil end

    local ok, cr = pcall(cairo.Context, content)
    if not ok or not cr then return nil end

    local x, y, w, h = cr:clip_extents()
    if not w or not h or w <= 0 or h <= 0 then return nil end

    local ok2, img_surface = pcall(cairo.ImageSurface.create, cairo.Format.ARGB32, w - x, h - y)
    if not ok2 or not img_surface then return nil end

    local ok3, cr2 = pcall(cairo.Context, img_surface)
    if not ok3 or not cr2 then return nil end

    pcall(function()
        cr2:set_source_surface(content, 0, 0)
        cr2.operator = cairo.Operator.SOURCE
        cr2:paint()
    end)

    return img_surface
end

local function create_client_card(c)
    local inner_w = card_w - dpi(16)
    local thumb_h = card_h - dpi(50)

    local img = get_client_thumbnail(c, inner_w, thumb_h)

    local thumb
    if img then
        thumb = wibox.widget {
            image = img,
            forced_width = inner_w,
            forced_height = thumb_h,
            horizontal_fit_policy = "fit",
            vertical_fit_policy = "fit",
            widget = wibox.widget.imagebox
        }
    else
        local icon_name = " "
        local class = c.class or ""
        if class:match("[Kk]itty") then icon_name = "  "
        elseif class:match("[Ff]irefox") then icon_name = "  "
        elseif class:match("[Ss]potify") then icon_name = " "
        elseif class:match("[Tt]hunar") or class:match("File Manager") then icon_name = "  "
        elseif class:match("[Gg]imp") then icon_name = " "
        elseif class:match("[Vv]scode") or class:match("Code") then icon_name = " "
        end

        thumb = wibox.widget {
            {
                markup = "<span font='" .. (beautiful.icon_font_name or "") .. "Round 24' color='" .. accent_color .. "'>" .. icon_name .. "</span>",
                align = "center",
                valign = "center",
                widget = wibox.widget.textbox
            },
            forced_width = inner_w,
            forced_height = thumb_h,
            bg = muted_color .. "33",
            shape = function(cr_s, w, h)
                gears.shape.rounded_rect(cr_s, w, h, dpi(6))
            end,
            widget = wibox.container.background
        }
    end

    local title_text = c.name or c.class or ""
    if #title_text > 24 then title_text = title_text:sub(1, 22) .. "..." end

    local title = wibox.widget {
        markup = "<span font='" .. (beautiful.font_name or "") .. "medium 9' color='" .. fg_color .. "'>" .. gears.string.xml_escape(title_text) .. "</span>",
        align = "center",
        forced_width = inner_w,
        widget = wibox.widget.textbox
    }

    local tag_names = {}
    for _, t in ipairs(c:tags()) do
        tag_names[#tag_names + 1] = t.name or ""
    end
    local tag_text = table.concat(tag_names, " · ")

    local subtitle = wibox.widget {
        markup = "<span font='" .. (beautiful.font_name or "") .. "8' color='" .. accent_color .. "'>" .. gears.string.xml_escape(tag_text) .. "</span>",
        align = "center",
        forced_width = inner_w,
        widget = wibox.widget.textbox
    }

    local card_bg = wibox.widget {
        {
            thumb,
            title,
            subtitle,
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(4),
        },
        margins = dpi(8),
        bg = surface_color,
        border_width = dpi(2),
        border_color = surface_color,
        shape = function(cr_s, w, h)
            gears.shape.rounded_rect(cr_s, w, h, dpi(10))
        end,
        widget = wibox.container.background
    }

    local card = wibox.widget {
        card_bg,
        margins = dpi(6),
        widget = wibox.container.margin
    }

    card:connect_signal("mouse::enter", function()
        card_bg.border_color = accent_color
    end)
    card:connect_signal("mouse::leave", function()
        card_bg.border_color = surface_color
    end)

    local client_ref = c

    card:buttons(gears.table.join(
        awful.button({}, 1, function()
            M.hide()
            pcall(function()
                if client_ref.valid then
                    local tags = client_ref:tags()
                    if tags and #tags > 0 then
                        tags[1]:view_only()
                    end
                    client.focus = client_ref
                    client_ref:raise()
                end
            end)
        end)
    ))

    return card
end

function M.show()
    if M.active then return end

    local clients = get_all_clients()
    if #clients == 0 then return end
    M.active = true

    local screen = awful.screen.focused()
    local sgeo = screen.geometry

    local cols = math.min(#clients, 4)
    local rows = math.ceil(#clients / cols)

    local grid = wibox.layout.fixed.vertical()
    grid.spacing = card_spacing
    grid.expand = "none"

    local idx = 1
    for _ = 1, rows do
        local row = wibox.layout.fixed.horizontal()
        row.spacing = card_spacing
        row.expand = "center"
        for _ = 1, cols do
            if idx <= #clients then
                local ok, card = pcall(create_client_card, clients[idx])
                if ok and card then
                    row:add(card)
                end
                idx = idx + 1
            else
                break
            end
        end
        grid:add(row)
    end

    local header = wibox.widget {
        markup = "<span font='" .. (beautiful.font_name or "") .. "Bold 14' color='" .. fg_color .. "'>Overview</span>",
        align = "center",
        widget = wibox.widget.textbox
    }

    local content = wibox.widget {
        {
            header,
            grid,
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(20),
        },
        valign = "center",
        halign = "center",
        widget = wibox.container.place
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

    awful.keygrabber.run(function(mod, key, event)
        if event ~= "press" then return end
        if key == "Escape" or key == "e" then
            M.hide()
            return true
        end
    end)
end

function M.hide()
    if not M.active then return end
    M.active = false

    pcall(awful.keygrabber.stop)

    if M.overlay then
        M.overlay.visible = false
        M.overlay = nil
    end
end

function M.toggle()
    if M.active then
        M.hide()
    else
        M.show()
    end
end

return M
