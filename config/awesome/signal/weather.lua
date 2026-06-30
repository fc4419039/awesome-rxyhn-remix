-- Provides:
-- signal::weather
--      temperature (integer)
--      description (string)
--      icon_widget (string with markup)
--      condition (string: Clear, Clouds, Rain, etc.)
--      humidity (integer)
--      wind_speed (number)
--      pressure (integer)
local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local helpers = require("helpers")

local key = openweathermap_key
local city_id = openweathermap_city_id
local units = weather_units
local update_interval = 1200
local temp_file = "/tmp/awesomewm-signal-weather-"..city_id.."-"..units

local sun_icon = ""
local moon_icon = ""
local dcloud_icon = ""
local ncloud_icon = ""
local cloud_icon = ""
local rain_icon = ""
local storm_icon = ""
local snow_icon = ""
local mist_icon = ""
local whatever_icon = ""

local weather_icons = {
    ["01d"] = { icon = sun_icon, color = beautiful.xcolor3 },
    ["01n"] = { icon = moon_icon, color = beautiful.xcolor4 },
    ["02d"] = { icon = dcloud_icon, color = beautiful.xcolor3 },
    ["02n"] = { icon = ncloud_icon, color = beautiful.xcolor6 },
    ["03d"] = { icon = cloud_icon, color = beautiful.xforeground },
    ["03n"] = { icon = cloud_icon, color = beautiful.xforeground },
    ["04d"] = { icon = cloud_icon, color = beautiful.xforeground },
    ["04n"] = { icon = cloud_icon, color = beautiful.xforeground },
    ["09d"] = { icon = rain_icon, color = beautiful.xcolor4 },
    ["09n"] = { icon = rain_icon, color = beautiful.xcolor4 },
    ["10d"] = { icon = rain_icon, color = beautiful.xcolor4 },
    ["10n"] = { icon = rain_icon, color = beautiful.xcolor4 },
    ["11d"] = { icon = storm_icon, color = beautiful.xforeground },
    ["11n"] = { icon = storm_icon, color = beautiful.xforeground },
    ["13d"] = { icon = snow_icon, color = beautiful.xcolor6 },
    ["13n"] = { icon = snow_icon, color = beautiful.xcolor6 },
    ["40d"] = { icon = mist_icon, color = beautiful.xcolor5 },
    ["40n"] = { icon = mist_icon, color = beautiful.xcolor5 },
    ["50d"] = { icon = mist_icon, color = beautiful.xcolor5 },
    ["50n"] = { icon = mist_icon, color = beautiful.xcolor5 },
    ["_"] = { icon = whatever_icon, color = beautiful.xcolor2 },
}

local weather_details_script = [[
    bash -c '
    KEY="]]..key..[["
    CITY="]]..city_id..[["
    UNITS="]]..units..[["

    weather=$(curl -sf "http://api.openweathermap.org/data/2.5/weather?APPID=$KEY&id=$CITY&units=$UNITS")

    if [ -n "$weather" ]; then
        weather_temp=$(echo "$weather" | jq ".main.temp" | cut -d "." -f 1)
        weather_icon=$(echo "$weather" | jq -r ".weather[].icon" | head -1)
        weather_desc=$(echo "$weather" | jq -r ".weather[].description" | head -1)
        weather_main=$(echo "$weather" | jq -r ".weather[].main" | head -1)
        weather_humidity=$(echo "$weather" | jq ".main.humidity")
        weather_wind=$(echo "$weather" | jq ".wind.speed")
        weather_pressure=$(echo "$weather" | jq ".main.pressure")

        echo "$weather_main|$weather_icon|$weather_desc|$weather_temp|$weather_humidity|$weather_wind|$weather_pressure"
    else
        echo "..."
    fi
  ']]

local function parse_weather(stdout)
    if stdout == "...\n" then
        awful.spawn.with_shell("rm "..temp_file)
        local icon = weather_icons['_'].icon
        local color = weather_icons['_'].color
        local weather_icon = helpers.colorize_text(icon, color)
        awesome.emit_signal("signal::weather", 999, "Weather unavailable", weather_icon, "None", 0, 0, 0)
        return
    end

    local parts = {}
    for part in stdout:gmatch("[^|]+") do
        table.insert(parts, part)
    end

    local condition = parts[1] or ""
    local icon_code = parts[2] or ""
    local description = parts[3] or ""
    local temperature = tonumber(parts[4]) or 0
    local humidity = tonumber(parts[5]) or 0
    local wind_speed = tonumber(parts[6]) or 0
    local pressure = tonumber(parts[7]) or 0

    description = description:gsub('^%s*(.-)%s*$', '%1')
    description = description:gsub('%-0', '0')
    description = description:sub(1,1):upper()..description:sub(2)

    local entry = weather_icons[icon_code] or weather_icons['_']
    local weather_icon = helpers.colorize_text(entry.icon, entry.color)

    awesome.emit_signal("signal::weather", temperature, description, weather_icon, condition, humidity, wind_speed, pressure)
end

-- Delay initial read so dashboard has time to connect its signal handler
gears.timer.start_new(2, function()
    local f = io.open(temp_file, "r")
    if f then
        local content = f:read("*a")
        f:close()
        if content then
            parse_weather(content)
        end
    end
    return false
end)

helpers.remote_watch(weather_details_script, update_interval, temp_file, function(stdout)
    parse_weather(stdout)
end)
