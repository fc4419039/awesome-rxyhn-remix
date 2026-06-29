local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local helpers = require("helpers")

local weather_icon = wibox.widget{
  font = "icomoon 36",
  markup = helpers.colorize_text("", beautiful.xcolor2),
  align = "right",
  valign = "bottom",
  widget = wibox.widget.textbox
}

local weather_temp = wibox.widget{
  font = beautiful.font_name .. "medium 11",
  markup = "999°C",
  valign = "center",
  widget = wibox.widget.textbox
}

local weather_desc = wibox.widget{
  font = beautiful.font_name .. "medium 8",
  markup = helpers.colorize_text("Cargando...", beautiful.dashboard_box_fg),
  valign = "center",
  widget = wibox.widget.textbox
}

local weather_extra = wibox.widget{
  font = beautiful.font_name .. "medium 7",
  markup = "",
  valign = "center",
  widget = wibox.widget.textbox
}

local weather = wibox.widget{
  {
    {
      weather_desc,
      weather_temp,
      spacing = dpi(3),
      layout = wibox.layout.fixed.vertical
    },
    nil,
    weather_icon,
    expand = "none",
    layout = wibox.layout.align.vertical
  },
  {
    nil,
    weather_extra,
    expand = "none",
    layout = wibox.layout.align.horizontal
  },
  spacing = dpi(4),
  layout = wibox.layout.fixed.vertical
}

awesome.connect_signal("signal::weather", function(temperature, description, icon_widget, condition, humidity, wind_speed, pressure)
  local symbol = weather_units == "imperial" and "°F" or "°C"
  local extra = ""

  if condition == "Rain" or condition == "Drizzle" then
    extra = "💧 " .. humidity .. "%  🌬 " .. wind_speed .. " m/s"
  elseif condition == "Clear" then
    extra = "☀  💧 " .. humidity .. "%"
  elseif condition == "Clouds" then
    extra = "☁  💧 " .. humidity .. "%  🌬 " .. wind_speed .. " m/s"
  elseif condition == "Thunderstorm" then
    extra = "⚡  💧 " .. humidity .. "%  🌬 " .. wind_speed .. " m/s"
  elseif condition == "Mist" or condition == "Fog" or condition == "Haze" then
    extra = "🌫  💧 " .. humidity .. "%  🌬 " .. wind_speed .. " m/s"
  elseif condition == "Snow" then
    extra = "❄  💧 " .. humidity .. "%"
  else
    extra = "💧 " .. humidity .. "%  🌬 " .. wind_speed .. " m/s"
  end

  weather_icon.markup = icon_widget
  weather_desc.markup = helpers.colorize_text(description, beautiful.dashboard_box_fg)
  weather_temp.markup = temperature .. symbol
  weather_extra.markup = helpers.colorize_text(extra, beautiful.xcolor8)
end)

return weather
