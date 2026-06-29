-- Standard awesome library
local gears = require("gears")
local wibox = require("wibox")
local math = require("math")

-- Theme handling library
local beautiful = require("beautiful")

-- C libraries
local cairo = require("lgi").cairo

-- Analog clock
------------------
-- Stolen from No37

local CLOCK_SIZE = 200

local function create_minute_pointer(minute)
        local img = cairo.ImageSurface(cairo.Format.ARGB32, CLOCK_SIZE, CLOCK_SIZE)
        local cr = cairo.Context(img)
        local angle = (minute / 60) * 2 * math.pi
        local cx, cy = CLOCK_SIZE / 2, CLOCK_SIZE / 2
        cr:translate(cx, cy)
        cr:rotate(angle)
        cr:translate(-cx, -cy)
        cr:set_source(gears.color(beautiful.xforeground))
        cr:rectangle(cx - 6, CLOCK_SIZE * 0.15, 12, CLOCK_SIZE * 0.42)
        cr:fill()
        return img
end

local function create_hour_pointer(hour)
        local img = cairo.ImageSurface(cairo.Format.ARGB32, CLOCK_SIZE, CLOCK_SIZE)
        local cr = cairo.Context(img)
        local angle = ((hour % 12) / 12) * 2 * math.pi
        local cx, cy = CLOCK_SIZE / 2, CLOCK_SIZE / 2
        cr:translate(cx, cy)
        cr:rotate(angle)
        cr:translate(-cx, -cy)
        cr:set_source(gears.color(beautiful.xcolor4))
        cr:rectangle(cx - 8, CLOCK_SIZE * 0.25, 16, CLOCK_SIZE * 0.32)
        cr:fill()
        return img
end

local minute_pointer = create_minute_pointer(37)
local hour_pointer = create_hour_pointer(17)

local minute_pointer_img = wibox.widget.imagebox()
local hour_pointer_img = wibox.widget.imagebox()

local analog_clock = wibox.widget {
        { -- circle
                wibox.widget.textbox(""),
                shape = function(cr, width, height) gears.shape.circle(cr, width, height, height / 2) end,
                shape_border_width = 4,
                shape_border_color = beautiful.xcolor8,
                bg = "alpha",
                widget = wibox.container.background
        },
        minute_pointer_img,
        hour_pointer_img,
        layout = wibox.layout.stack
}

local minute = 0
local hour = 0

local clock_timer
local function update_clock()
        minute = os.date("%M")
        hour = os.date("%H")
        local new_minute = create_minute_pointer(minute)
        local new_hour = create_hour_pointer(hour + (minute / 60))
        minute_pointer_img.image = new_minute
        hour_pointer_img.image = new_hour
        if minute_pointer then minute_pointer:finish() end
        if hour_pointer then hour_pointer:finish() end
        minute_pointer = new_minute
        hour_pointer = new_hour
end

local clock_timer = gears.timer {
        timeout = 30,
        call_now = false,
        autostart = false,
        callback = update_clock
}

local clock = { widget = analog_clock }

function clock.start()
        update_clock()
        clock_timer:again()
end

function clock.stop()
        clock_timer:stop()
end

clock.start()

return clock
