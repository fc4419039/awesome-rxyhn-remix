-- Standalone script: apply saved color temperature preferences via xrandr.
-- Called by color_temp.sh during Awesome startup and on monitor hotplug.

local prefs_file = os.getenv("HOME") .. "/.config/awesome/.color_temp_prefs"

local function temp_to_gamma(temp)
    local t = temp / 100
    local r, g, b

    if t <= 66 then
        r = 255
    else
        r = t - 60
        r = 329.698727446 * (r ^ -0.1332047592)
        r = math.min(255, math.max(0, r))
    end

    if t <= 66 then
        g = t
        g = 99.4708025861 * math.log(g) - 161.1195681661
        g = math.min(255, math.max(0, g))
    else
        g = t - 60
        g = 288.1221695283 * (g ^ -0.0755148492)
        g = math.min(255, math.max(0, g))
    end

    if t >= 66 then
        b = 255
    elseif t <= 19 then
        b = 0
    else
        b = t - 10
        b = 138.5177312231 * math.log(b) - 305.0447927307
        b = math.min(255, math.max(0, b))
    end

    return r / 255, g / 255, b / 255
end

local function apply(monitor, temp)
    local r, g, b = temp_to_gamma(temp)
    os.execute(string.format(
        "xrandr --output %s --gamma %.4f:%.4f:%.4f 2>/dev/null",
        monitor, r, g, b))
end

local f = io.open(prefs_file, "r")
if f then
    for line in f:lines() do
        local monitor, temp = line:match("([^=]+)=(.+)")
        if monitor and temp then
            local t = tonumber(temp)
            if t then
                apply(monitor, t)
            end
        end
    end
    f:close()
else
    -- No prefs yet — apply sensible defaults
    apply("eDP-1", 6500)
    os.execute("xrandr --output HDMI-1 --gamma 0.872:0.933:1.128 2>/dev/null")
end
