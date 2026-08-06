-- Provides:
-- signal::weather
--      temperature (integer)
--      description (string)
--      icon_widget (string with markup)
--      condition (string: WMO weather code)
--      humidity (integer)
--      wind_speed (number)
--      pressure (integer)
--      city (string)
--
-- Provider: Open-Meteo (sin API key) + ubicación automática por IP (ip-api.com)
local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local helpers = require("helpers")

local units = weather_units
local update_interval = 1200
local temp_file = "/tmp/awesomewm-signal-weather-"..units

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

local function di(day, night)
    return { day = day, night = night }
end

-- Iconos por código WMO (Open-Meteo): día/noche
local weather_icons = {
    [0]  = di({icon = sun_icon, color = beautiful.xcolor3}, {icon = moon_icon, color = beautiful.xcolor4}),
    [1]  = di({icon = dcloud_icon, color = beautiful.xcolor3}, {icon = ncloud_icon, color = beautiful.xcolor6}),
    [2]  = di({icon = cloud_icon, color = beautiful.xforeground}, {icon = cloud_icon, color = beautiful.xforeground}),
    [3]  = di({icon = cloud_icon, color = beautiful.xforeground}, {icon = cloud_icon, color = beautiful.xforeground}),
    [45] = di({icon = mist_icon, color = beautiful.xcolor5}, {icon = mist_icon, color = beautiful.xcolor5}),
    [48] = di({icon = mist_icon, color = beautiful.xcolor5}, {icon = mist_icon, color = beautiful.xcolor5}),
    [51] = di({icon = rain_icon, color = beautiful.xcolor4}, {icon = rain_icon, color = beautiful.xcolor4}),
    [53] = di({icon = rain_icon, color = beautiful.xcolor4}, {icon = rain_icon, color = beautiful.xcolor4}),
    [55] = di({icon = rain_icon, color = beautiful.xcolor4}, {icon = rain_icon, color = beautiful.xcolor4}),
    [56] = di({icon = rain_icon, color = beautiful.xcolor4}, {icon = rain_icon, color = beautiful.xcolor4}),
    [57] = di({icon = rain_icon, color = beautiful.xcolor4}, {icon = rain_icon, color = beautiful.xcolor4}),
    [61] = di({icon = rain_icon, color = beautiful.xcolor4}, {icon = rain_icon, color = beautiful.xcolor4}),
    [63] = di({icon = rain_icon, color = beautiful.xcolor4}, {icon = rain_icon, color = beautiful.xcolor4}),
    [65] = di({icon = rain_icon, color = beautiful.xcolor4}, {icon = rain_icon, color = beautiful.xcolor4}),
    [66] = di({icon = rain_icon, color = beautiful.xcolor4}, {icon = rain_icon, color = beautiful.xcolor4}),
    [67] = di({icon = rain_icon, color = beautiful.xcolor4}, {icon = rain_icon, color = beautiful.xcolor4}),
    [71] = di({icon = snow_icon, color = beautiful.xcolor6}, {icon = snow_icon, color = beautiful.xcolor6}),
    [73] = di({icon = snow_icon, color = beautiful.xcolor6}, {icon = snow_icon, color = beautiful.xcolor6}),
    [75] = di({icon = snow_icon, color = beautiful.xcolor6}, {icon = snow_icon, color = beautiful.xcolor6}),
    [77] = di({icon = snow_icon, color = beautiful.xcolor6}, {icon = snow_icon, color = beautiful.xcolor6}),
    [80] = di({icon = rain_icon, color = beautiful.xcolor4}, {icon = rain_icon, color = beautiful.xcolor4}),
    [81] = di({icon = rain_icon, color = beautiful.xcolor4}, {icon = rain_icon, color = beautiful.xcolor4}),
    [82] = di({icon = rain_icon, color = beautiful.xcolor4}, {icon = rain_icon, color = beautiful.xcolor4}),
    [85] = di({icon = snow_icon, color = beautiful.xcolor6}, {icon = snow_icon, color = beautiful.xcolor6}),
    [86] = di({icon = snow_icon, color = beautiful.xcolor6}, {icon = snow_icon, color = beautiful.xcolor6}),
    [95] = di({icon = storm_icon, color = beautiful.xforeground}, {icon = storm_icon, color = beautiful.xforeground}),
    [96] = di({icon = storm_icon, color = beautiful.xforeground}, {icon = storm_icon, color = beautiful.xforeground}),
    [99] = di({icon = storm_icon, color = beautiful.xforeground}, {icon = storm_icon, color = beautiful.xforeground}),
}

local weather_desc = {
    [0]  = "Despejado",
    [1]  = "Mayormente despejado",
    [2]  = "Parcialmente nublado",
    [3]  = "Cubierto",
    [45] = "Niebla",
    [48] = "Niebla escarchada",
    [51] = "Llovizna ligera",
    [53] = "Llovizna",
    [55] = "Llovizna intensa",
    [56] = "Llovizna helada ligera",
    [57] = "Llovizna helada",
    [61] = "Lluvia ligera",
    [63] = "Lluvia",
    [65] = "Lluvia intensa",
    [66] = "Lluvia helada ligera",
    [67] = "Lluvia helada",
    [71] = "Nieve ligera",
    [73] = "Nieve",
    [75] = "Nieve intensa",
    [77] = "Granos de nieve",
    [80] = "Chubascos ligeros",
    [81] = "Chubascos",
    [82] = "Chubascos intensos",
    [85] = "Chubascos de nieve",
    [86] = "Chubascos de nieve fuertes",
    [95] = "Tormenta",
    [96] = "Tormenta con granizo",
    [99] = "Tormenta con granizo fuerte",
}

local weather_details_script = [[
    bash -c '
    LOC_FILE="/tmp/awesomewm-location"
    LOC=""
    if [ -f "$LOC_FILE" ]; then
        if [ $(( $(date +%s) - $(stat -c %Y "$LOC_FILE") )) -lt 21600 ]; then
            LOC=$(cat "$LOC_FILE")
        fi
    fi
    if [ -z "$LOC" ]; then
        LOC=$(curl -sf --max-time 5 "http://ip-api.com/json/?fields=lat,lon,city")
        if [ -n "$LOC" ]; then
            echo "$LOC" > "$LOC_FILE"
        fi
    fi

    if [ -z "$LOC" ]; then
        echo "..."
        exit 0
    fi

    LAT=$(echo "$LOC" | jq -r ".lat")
    LON=$(echo "$LOC" | jq -r ".lon")
    CITY=$(echo "$LOC" | jq -r ".city")

    weather=$(curl -sf --max-time 8 "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,surface_pressure,is_day&wind_speed_unit=ms&timezone=auto")

    if [ -n "$weather" ]; then
        weather_code=$(echo "$weather" | jq -r ".current.weather_code")
        weather_temp=$(echo "$weather" | jq -r ".current.temperature_2m" | cut -d "." -f 1)
        weather_humidity=$(echo "$weather" | jq -r ".current.relative_humidity_2m")
        weather_wind=$(echo "$weather" | jq -r ".current.wind_speed_10m")
        weather_pressure=$(echo "$weather" | jq -r ".current.surface_pressure")
        weather_is_day=$(echo "$weather" | jq -r ".current.is_day")
        echo "$weather_code|$weather_temp|$weather_humidity|$weather_wind|$weather_pressure|$CITY|$weather_is_day"
    else
        echo "..."
    fi
  ']]

local function parse_weather(stdout)
    if not stdout or stdout == "...\n" then
        awful.spawn.with_shell("rm "..temp_file)
        local entry = weather_icons[0].day
        local weather_icon = helpers.colorize_text(entry.icon, entry.color)
        awesome.emit_signal("signal::weather", 999, "Weather unavailable", weather_icon, "None", 0, 0, 0)
        return
    end

    local parts = {}
    for p in stdout:gmatch("[^|]+") do
        local part = p:gsub("%s+$", "")
        table.insert(parts, part)
    end

    local code = tonumber(parts[1]) or 0
    local temperature = tonumber(parts[2]) or 0
    local humidity = tonumber(parts[3]) or 0
    local wind_speed = tonumber(parts[4]) or 0
    local pressure = tonumber(parts[5]) or 0
    local city = parts[6] or ""
    local is_day = parts[7] == "1"

    local description = weather_desc[code] or "Desconocido"
    description = description:sub(1,1):upper()..description:sub(2)

    local entry = weather_icons[code] or weather_icons[0]
    local icon = is_day and entry.day or entry.night
    local weather_icon = helpers.colorize_text(icon.icon, icon.color)

    awesome.emit_signal("signal::weather", temperature, description, weather_icon, tostring(code), humidity, wind_speed, pressure, city)
end

-- Delay initial fetch so dashboard has time to connect its signal handler
gears.timer.start_new(2, function()
    awful.spawn.easy_async_with_shell(weather_details_script .. " | tee " .. temp_file, function(out)
        parse_weather(out)
    end)
    return false
end)

helpers.remote_watch(weather_details_script, update_interval, temp_file, function(stdout)
    parse_weather(stdout)
end)
