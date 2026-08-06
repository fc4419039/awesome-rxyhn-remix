local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local helpers = require("helpers")

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
  markup = helpers.colorize_text("Cargando...", beautiful.dashboard_box_fg),
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
  local symbol = weather_units == "imperial" and "°F" or "°C"

  weather_icon.markup = icon_widget
  weather_desc.markup = helpers.colorize_text((city and city ~= "" and city) or description, beautiful.dashboard_box_fg)
  weather_temp.markup = temperature .. symbol
  weather_humidity_val.markup = helpers.colorize_text(humidity .. "%", beautiful.dashboard_box_fg)
  weather_wind_val.markup = helpers.colorize_text(wind_speed .. " m/s", beautiful.dashboard_box_fg)

  local accent = {
    Clear = beautiful.xcolor3,
    Clouds = beautiful.xforeground,
    Rain = beautiful.xcolor4,
    Drizzle = beautiful.xcolor4,
    Thunderstorm = beautiful.xcolor1,
    Snow = beautiful.xcolor6,
    Mist = beautiful.xcolor5,
    Fog = beautiful.xcolor5,
    Haze = beautiful.xcolor5,
  }
  accent_line.color = accent[condition] or beautiful.xcolor2
end)

return weather
