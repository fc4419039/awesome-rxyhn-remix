local wibox = require("wibox")
local beautiful = require("beautiful")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

local wibox_helpers = {}

function wibox_helpers.fit(w, s)
    if not w or not w.valid then return end
    local widget = w:get_widget()
    if not widget then return end
    local ctx = {
        screen = s,
        dpi = s.dpi,
        drawable = w._drawable,
    }
    local fw, fh = widget:fit(ctx, s.geometry.width, s.geometry.height)
    if fw and fh and fw > 0 and fh > 0 then
        w:geometry({ width = fw, height = fh })
    end
end

function wibox_helpers.clamp_on_screen(w, s)
    if not w or not w.valid or not s then return end
    local g = w:geometry()
    local geo = s.geometry
    local margin = 10
    local min_x = geo.x + margin
    local max_x = geo.x + geo.width - g.width - margin
    local min_y = geo.y + margin
    local max_y = geo.y + geo.height - g.height - margin
    local x = math.max(min_x, math.min(max_x, g.x))
    local y = math.max(min_y, math.min(max_y, g.y))
    if x ~= g.x or y ~= g.y then
        w:geometry({ x = x, y = y })
    end
end

function wibox_helpers.vertical_pad(height)
    return wibox.widget {
        forced_height = height,
        layout = wibox.layout.fixed.vertical
    }
end

function wibox_helpers.horizontal_pad(width)
    return wibox.widget {
        forced_width = width,
        layout = wibox.layout.fixed.horizontal
    }
end

function wibox_helpers.brand_watermark(opacity)
    if not beautiful.brand_logo then return nil end
    return wibox.widget{
        image = beautiful.brand_logo,
        resize = true,
        upscale = false,
        opacity = opacity or 0.7,
        halign = "center",
        valign = "center",
        forced_width = dpi(200),
        forced_height = dpi(200),
        widget = wibox.widget.imagebox
    }
end

function wibox_helpers.pad(size)
    local str = ""
    for i = 1, size do str = str .. " " end
    return wibox.widget.textbox(str)
end

function wibox_helpers.screen_mask(s, bg)
    local mask = wibox({
        visible = false,
        ontop = true,
        type = "splash",
        screen = s
    })
    awful = require("awful")
    awful.placement.maximize(mask)
    mask.bg = bg
    return mask
end

return wibox_helpers