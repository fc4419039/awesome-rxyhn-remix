local mock = {}

mock.gears = {
    shape = {
        rounded_rect = function() end,
        pie = function() end,
        parallelogram = function() end,
        partially_rounded_rect = function() end,
        rounded_bar = function() end,
    },
    table = { hasitem = function() return 1 end },
    math = { cycle = function(n, i) return (i - 1) % n + 1 end },
    timer = { start_new = function(_, fn) return { stop = function() end, again = function() end } end },
    delayed_call = function(fn) fn() end,
}

mock.awful = {
    rules = { match = function() return false end },
    client = {
        iterate = function() return function() return nil end end,
        focus = nil,
        get = function() return {} end,
        swap = { byidx = function() end, bydirection = function() end },
        restore = function() end,
        urgent = { jumpto = function() end },
    },
    placement = { maximize = function() end, centered = function() end },
    layout = { get = function() return "floating" end, suit = { floating = "floating", max = "max" } },
    screen = { focused = function() return { selected_tag = { gap = 5 }, geometry = { x = 0, y = 0, width = 1920, height = 1080 }, workarea = { x = 0, y = 0, width = 1920, height = 1080 }, padding = { left = 0, right = 0, top = 0, bottom = 0 } } end },
    tag = { history = { restore = function() end } },
    menu = { clients = function() return { hide = function() end, wibox = { visible = false } } end },
    spawn = { easy_async_with_shell = function(cmd, fn) fn("") end, with_shell = function() end },
}

local wibox_widget = {
    textbox = function() return {} end,
    imagebox = function() return { image = nil } end,
    background = function() return {} end,
    margin = function() return {} end,
    place = function() return {} end,
    arcchart = function() return {} end,
    textclock = function() return {} end,
}

local wibox_ctor = function(t) return t end
local wibox_widget_with_ctor = {}
for k, v in pairs(wibox_widget) do wibox_widget_with_ctor[k] = v end
setmetatable(wibox_widget_with_ctor, { __call = function(_, t) return t end })

mock.wibox = {
    widget = wibox_widget_with_ctor,
    layout = {
        fixed = {
            vertical = function(t) t.forced_height = t.forced_height or 10; return t end,
            horizontal = function(t) t.forced_width = t.forced_width or 10; return t end,
        },
    },
}

mock.beautiful = {
    xresources = { apply_dpi = function(v) return v end },
    font_name = "Iosevka Nerd Font Mono ",
    icon_font_name = "Material Icons ",
    border_radius = 10,
    bar_radius = 14,
    useless_gap = 5,
    xcolor0 = "#000000",
    xcolor1 = "#ff0000",
    xcolor2 = "#00ff00",
    xcolor3 = "#ffff00",
    xcolor4 = "#0000ff",
    xcolor5 = "#ff00ff",
    xcolor6 = "#00ffff",
    xcolor7 = "#ffffff",
    xcolor8 = "#888888",
    xforeground = "#ffffff",
    xbackground = "#000000",
    darker_bg = "#000000",
    lighter_bg = "#222222",
    transparent = "#00000000",
    fg_normal = "#ffffff",
    bg_normal = "#000000",
    bg_focus = "#000000",
    border_width = 2,
    border_normal = "#000000",
    border_focus = "#000000",
    wibar_bg = "#000000",
    dashboard_width = 300,
    dashboard_radius = 14,
    notification_bell_icon = nil,
    brand_logo = nil,
}

mock.naughty = {
    notify = function() end,
    action = function() return { connect_signal = function() end } end,
    destroy_all_notifications = function() end,
}

for k, v in pairs(mock) do
    package.preload[k] = function() return v end
end

package.preload["beautiful.xresources"] = function() return mock.beautiful.xresources end
package.preload.xresources = function() return mock.beautiful.xresources end

return mock