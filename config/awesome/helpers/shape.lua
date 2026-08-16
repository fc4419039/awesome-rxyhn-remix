local gears = require("gears")
local beautiful = require("beautiful")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

local shape = {}

function shape.custom(cr, width, height)
    cr:move_to(0, height / 25)
    cr:line_to(height / 25, 0)
    cr:line_to(width, 0)
    cr:line_to(width, height - height / 25)
    cr:line_to(width - height / 25, height)
    cr:line_to(0, height)
    cr:close_path()
end

function shape.rrect(radius)
    return function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, radius)
    end
end

function shape.pie(width, height, start_angle, end_angle, radius)
    return function(cr)
        gears.shape.pie(cr, width, height, start_angle, end_angle, radius)
    end
end

function shape.prgram(height, base)
    return function(cr, width)
        gears.shape.parallelogram(cr, width, height, base)
    end
end

function shape.prrect(radius, tl, tr, br, bl)
    return function(cr, width, height)
        gears.shape.partially_rounded_rect(cr, width, height, tl, tr, br, bl, radius)
    end
end

function shape.rbar(width, height)
    return function(cr)
        gears.shape.rounded_bar(cr, width, height)
    end
end

return shape