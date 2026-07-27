-- Standard awesome library
local awful = require("awful")
local gears = require("gears")

-- Theme handling library
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

-- Widget library
local wibox = require("wibox")

-- Helpers
local helpers = require("helpers")


-- Date
---------

local date_day = wibox.widget{
    font = "Anurati 8",
    align = "center",
    valign = "center",
    widget = wibox.widget.textbox
}

gears.timer.start_new(1, function()
    date_day:set_markup_silently('<span letter_spacing="2500">' .. helpers.colorize_text(helpers.upper_no_accents(os.date("%A")), beautiful.xcolor4) .. '</span>')
    return true
end)

local date_month = wibox.widget{
    font = "Anurati 10",
    align = "center",
    valign = "center",
    widget = wibox.widget.textbox
}

gears.timer.start_new(1, function()
    date_month:set_markup_silently('<span letter_spacing="1500">' .. helpers.upper_no_accents(os.date("%d de %B")) .. '</span>')
    return true
end)

local date = wibox.widget{
    date_day,
    nil,
    date_month,
    expand = "none",
    widget = wibox.layout.align.vertical
}

return date
