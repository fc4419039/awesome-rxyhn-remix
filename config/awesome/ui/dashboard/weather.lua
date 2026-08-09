local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local helpers = require("helpers")
local i18n = require("i18n")

-- ── Icon ────────────────────────────────────────────────────────────
local weather_icon = wibox.widget{
  font = "icomoon 28",
  markup = helpers.colorize_text("", beautiful.xcolor3),
  align = "center",
  valign = "center",
  widget = wibox.widget.textbox
}

-- ── Temperature ─────────────────────────────────────────────────────
local weather_temp = wibox.widget{
  font = beautiful.font_name .. "Bold 14",
  markup = "999°",
  align = "center",
  valign = "center",
  widget = wibox.widget.textbox
}

-- ── Condition ───────────────────────────────────────────────────────
local weather_desc = wibox.widget{
  font = beautiful.font_name .. "Medium 8",
  markup = helpers.colorize_text(i18n.tr("dash.loading"), beautiful.dashboard_box_fg),
  align = "center",
  valign = "center",
  widget = wibox.widget.textbox
}

-- ── Detail chips ────────────────────────────────────────────────────
local weather_humidity = wibox.widget{
  font = "icomoon 10",
  markup = helpers.colorize_text("", beautiful.xcolor4),
  widget = wibox.widget.textbox
}

local weather_humidity_val = wibox.widget{
  font = beautiful.font_name .. "7",
  markup = helpers.colorize_text("--%", beautiful.dashboard_box_fg),
  widget = wibox.widget.textbox
}

local weather_wind = wibox.widget{
  font = "icomoon 10",
  markup = helpers.colorize_text("", beautiful.xcolor6),
  widget = wibox.widget.textbox
}

local weather_wind_val = wibox.widget{
  font = beautiful.font_name .. "7",
  markup = helpers.colorize_text("--", beautiful.dashboard_box_fg),
  widget = wibox.widget.textbox
}

local details_row = wibox.widget{
  {
    weather_humidity,
    weather_humidity_val,
    spacing = dpi(3),
    layout = wibox.layout.fixed.horizontal
  },
  {
    weather_wind,
    weather_wind_val,
    spacing = dpi(3),
    layout = wibox.layout.fixed.horizontal
  },
  spacing = dpi(10),
  layout = wibox.layout.fixed.horizontal
}

-- ── Accent line ─────────────────────────────────────────────────────
local accent_line = wibox.widget{
  forced_height = dpi(2),
  shape = helpers.rrect(dpi(1)),
  color = beautiful.xcolor2,
  widget = wibox.widget.separator
}

-- ── Layout ──────────────────────────────────────────────────────────
local weather = wibox.widget{
  {
    weather_icon,
    forced_height = dpi(34),
    widget = wibox.container.place
  },
  {
    weather_temp,
    top = dpi(4),
    widget = wibox.container.margin
  },
  weather_desc,
  {
    {
      accent_line,
      margins = { left = dpi(12), right = dpi(12) },
      widget = wibox.container.margin
    },
    top = dpi(4),
    bottom = dpi(2),
    widget = wibox.container.margin
  },
  {
    details_row,
    halign = "center",
    widget = wibox.container.place
  },
  spacing = dpi(2),
  layout = wibox.layout.fixed.vertical
}

-- ── Signal ──────────────────────────────────────────────────────────
awesome.connect_signal("signal::weather", function(temperature, description, icon_widget, condition, humidity, wind_speed, pressure, city)
  local units = _G.weather_units or "metric"
  local symbol = units == "imperial" and "°F" or "°C"

  weather_icon.markup = icon_widget
  weather_desc.markup = helpers.colorize_text(description, beautiful.dashboard_box_fg)
  weather_temp.markup = temperature .. symbol
  weather_humidity_val.markup = helpers.colorize_text(humidity .. "%", beautiful.dashboard_box_fg)
  weather_wind_val.markup = helpers.colorize_text(wind_speed .. " m/s", beautiful.dashboard_box_fg)

  local accent = {
    [0]  = beautiful.xcolor3,
    [1]  = beautiful.xforeground,
    [2]  = beautiful.xforeground,
    [3]  = beautiful.xforeground,
    [45] = beautiful.xcolor5,
    [48] = beautiful.xcolor5,
    [51] = beautiful.xcolor4,
    [53] = beautiful.xcolor4,
    [55] = beautiful.xcolor4,
    [56] = beautiful.xcolor4,
    [57] = beautiful.xcolor4,
    [61] = beautiful.xcolor4,
    [63] = beautiful.xcolor4,
    [65] = beautiful.xcolor4,
    [66] = beautiful.xcolor4,
    [67] = beautiful.xcolor4,
    [71] = beautiful.xcolor6,
    [73] = beautiful.xcolor6,
    [75] = beautiful.xcolor6,
    [77] = beautiful.xcolor6,
    [80] = beautiful.xcolor4,
    [81] = beautiful.xcolor4,
    [82] = beautiful.xcolor4,
    [85] = beautiful.xcolor6,
    [86] = beautiful.xcolor6,
    [95] = beautiful.xcolor1,
    [96] = beautiful.xcolor1,
    [99] = beautiful.xcolor1,
  }
  accent_line.color = accent[tonumber(condition)] or beautiful.xcolor2
end)

return weather
