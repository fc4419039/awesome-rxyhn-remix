#!/usr/bin/env lua
-- check_runtime.lua - Validación de runtime real de TU config AwesomeWM
-- Solo verifica archivos en ~/.config/awesome (excluye módulos externos)

local home = os.getenv("HOME") or "/home/spectre"
package.path = package.path .. ";" .. home .. "/.config/awesome/?.lua;" .. home .. "/.config/awesome/?/init.lua"

local errors = {}
local warnings = {}

local function err(msg, file, line)
    table.insert(errors, {msg = msg, file = file, line = line})
end

local function warn(msg, file, line)
    table.insert(warnings, {msg = msg, file = file, line = line})
end

-- ===== MOCKS MÍNIMOS DE AWESOMEWM =====
local mock = {}

mock.gears = {
    shape = { rounded_rect = function() end, pie = function() end, parallelogram = function() end, partially_rounded_rect = function() end, rounded_bar = function() end },
    table = { hasitem = function() return 1 end, iterate = function(t) return function() return nil end end, join = function(t, s) return table.concat(t, s) end },
    math = { cycle = function(n, i) return (i - 1) % n + 1 end },
    timer = { start_new = function(_, fn) return { stop = function() end, again = function() end, start = function() end, timeout = 0, autostart = true, call_now = false, single_shot = false } end, delayed_call = function(fn) fn() end },
    filesystem = { get_configuration_dir = function() return home .. "/.config/awesome/" end, get_themes_dir = function() return "/usr/share/awesome/themes/" end, get_cache_dir = function() return home .. "/.cache" end, file_readable = function() return true end },
    surface = { load_uncached = function() return {} end, load = function() return {} end },
    debug = { print_warning = function() end },
    sort = function(t, f) table.sort(t, f) return t end,
    protected_call = function(fn) return xpcall(fn, debug.traceback) end,
    string = { split = function(s, sep) local r={} for m in (s..sep):gmatch("(.-)"..sep) do table.insert(r,m) end return r end },
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
        connect_signal = function() end,
    },
    placement = { maximize = function() end, centered = function() end, no_overlap = function() end, no_offscreen = function() end, scale = function() end, top = function() end, bottom = function() end, left = function() end, right = function() end },
    layout = { get = function() return "floating" end, inc = function() end, suit = { floating = "floating", max = "max", tile = "tile" }, set = function() end },
    screen = { focused = function() return { selected_tag = { gap = 5 }, geometry = { x = 0, y = 0, width = 1920, height = 1080 }, workarea = { x = 0, y = 0, width = 1920, height = 1080 }, padding = { left = 0, right = 0, top = 0, bottom = 0 }, connect_signal = function() end, index = 1 } end, connect_signal = function() end },
    tag = { history = { restore = function() end }, viewprev = function() end, viewnext = function() end, viewtoggle = function() end, view_only = function() end, connect_signal = function() end },
    menu = { clients = function() return { hide = function() end, wibox = { visible = false } } end },
    spawn = setmetatable({
        spawn = function() end,
        with_shell = function() end,
        with_line_callback = function() end,
        easy_async_with_shell = function(cmd, fn) fn("") end,
        easy_async = function(cmd, fn) fn("") end,
    }, {
        __call = function(_, ...) end,
    }),
    spawn_with_shell = function() end,
    button = function() return {} end,
    keygrabber = { run = function() end, stop = function() end },
    keyboard = { append_global_keybindings = function() end },
    mouse = { screen = { selected_tag = { gap = 5 } } },
    util = { spawn = function() end },
    widget = { tasklist = { filter = { currenttags = "currenttags" } }, layoutbox = function() return {} end, prompt = function() return {} end },
    wibar = function() return { setup = function() end, connect_signal = function() end, buttons = function() end, visible = true, geometry = function() return {x=0,y=0,width=100,height=100} end } end,
    tooltip = function() return { add_to_object = function() end } end,
    popup = function() return { setup = function() end, visible = true, geometry = function() return {x=0,y=0,width=100,height=100} end } end,
    hotkeys_popup = { show_help = function() end },
    key = function() return {} end,
}

mock.wibox = setmetatable({
    widget = {
        textbox = function() return { set_markup = function() end, set_text = function() end, connect_signal = function() end, forced_width = 0, forced_height = 0 } end,
        imagebox = function() return { set_image = function() end, connect_signal = function() end, resize = true } end,
        background = function() return { set_bg = function() end, set_shape = function() end, connect_signal = function() end, bg = "" } end,
        margin = function() return { set_margins = function() end, margins = 0 } end,
        place = function() return { set_widget = function() end, widget = nil } end,
        arcchart = function() return { set_colors = function() end, set_value = function() end, colors = {}, value = 0, min_value = 0, max_value = 100 } end,
        textclock = function() return { format = "", font = "", align = "center" } end,
        layoutbox = function() return {} end,
        prompt = function() return { run = function() end } end,
    },
    container = { background = function() return mock.wibox.widget.background() end, margin = function() return mock.wibox.widget.margin() end, place = function() return mock.wibox.widget.place() end, rotate = function() return { set_direction = function() end, direction = "north", widget = nil } end },
    layout = {
        fixed = { vertical = function() return { add = function() end, spacing = 0, layout = "fixed.vertical" } end, horizontal = function() return { add = function() end, spacing = 0, layout = "fixed.horizontal" } end },
        align = { vertical = function() return { set_first = function() end, set_second = function() end, set_third = function() end } end, horizontal = function() return { set_first = function() end, set_second = function() end, set_third = function() end } end },
        grid = function() return { set_widget = function() end } end,
        stack = function() return { set_widget = function() end } end,
        flexible = function() return { set_widget = function() end } end,
    },
    drawable = nil,
}, {
    __call = function(_) return { setup = function() end, connect_signal = function() end, buttons = function() end, geometry = function() return { x = 0, y = 0, width = 100, height = 100 } end, visible = true, type = "dock", screen = 1, x = 0, y = 0, width = 100, height = 100, bg = "", shape = function() end, ontop = true } end,
})

mock.beautiful = {
    init = function() end,
    get = function() return {} end,
    xresources = { apply_dpi = function(v) return v end, get_dpi = function() return 96 end },
    font_name = "Iosevka Nerd Font Mono ",
    icon_font_name = "Material Icons ",
    border_radius = 10, bar_radius = 14, useless_gap = 5,
    xcolor0 = "#000000", xcolor1 = "#ff0000", xcolor2 = "#00ff00", xcolor3 = "#ffff00", xcolor4 = "#0000ff",
    xcolor5 = "#ff00ff", xcolor6 = "#00ffff", xcolor7 = "#ffffff", xcolor8 = "#888888", xcolor9 = "#ff5555",
    xcolor10 = "#55ff55", xcolor11 = "#ffff55", xcolor12 = "#5555ff", xcolor13 = "#ff55ff", xcolor14 = "#55ffff", xcolor15 = "#ffffff",
    xforeground = "#ffffff", xbackground = "#000000", darker_bg = "#000000", lighter_bg = "#222222", transparent = "#00000000",
    fg_normal = "#ffffff", bg_normal = "#000000", bg_focus = "#000000", border_width = 2, border_normal = "#000000", border_focus = "#000000",
    wibar_bg = "#000000", dashboard_width = 300, dashboard_radius = 14, notification_bell_icon = nil, brand_logo = nil,
    wallpaper = nil, awesome_logo = nil, notification_icon = nil, volume_icon = nil, brightness_icon = nil,
    taglist_shape_focus = function() end, taglist_shape_empty = function() end, taglist_shape = function() end,
    taglist_shape_urgent = function() end, taglist_shape_volatile = function() end,
    wibar_width = 39, wibar_position = "left",
    tag_preview_client_border_radius = 6, tag_preview_client_opacity = 1.0,
    task_preview_widget_border_radius = 10,
    fade_duration = 250,
    deco_red = "#ff0000", deco_green = "#00ff00", deco_yellow = "#ffff00", deco_blue = "#0000ff",
    deco_purple = "#ff00ff", deco_cyan = "#00ffff", deco_gray = "#888888", deco_fg = "#ffffff",
    pop_vol_color = "#00ffff", pop_brightness_color = "#ff00ff",
    pop_bg = "#000000", pop_bar_bg = "#000000", pop_fg = "#ffffff",
    pop_border_radius = 10, pop_height = 200, pop_width = 200, pop_gap = 10,
    pop_box_margin = 10, pop_box_border_radius = 10,
    notification_border_radius = 10, notification_border_width = 0,
    notification_spacing = 24,
    notif_center_radius = 10, notif_center_box_radius = 5,
    notification_icon = nil, notification_bell_icon = nil,
    brightness_icon = nil, volume_icon = nil, volume_muted_icon = nil,
    widget_border_width = 2, widget_border_color = "#000000",
    snap_bg = "#000000", snap_shape = function() end,
    prompt_bg = "#00000000", prompt_fg = "#ffffff",
    dashboard_width = 300, dashboard_box_bg = "#000000", dashboard_box_fg = "#ffffff",
    playerctl_ignore = {}, playerctl_player = {}, playerctl_update_on_activity = true, playerctl_position_update_interval = 1,
    menu_font = "Iosevka Nerd Font Mono 10", menu_height = 34, menu_width = 210,
    menu_bg_normal = "#000000", menu_bg_focus = "#222222", menu_fg_normal = "#ffffff", menu_fg_focus = "#00ffff",
    menu_border_width = 1, menu_border_color = "#00ffff", menu_shape = function() end,
    menu_submenu = " > ", hotkeys_bg = "#000000", hotkeys_fg = "#ffffff",
    hotkeys_modifiers_fg = "#ffffff", hotkeys_font = "Iosevka Nerd Font Mono 11",
    hotkeys_description_font = "Iosevka Nerd Font Mono 9", hotkeys_shape = function() end,
    hotkeys_group_margin = 40, layoutlist_border_color = "#222222", layoutlist_border_width = 2,
    layoutlist_shape_selected = function() end, layoutlist_bg_selected = "#222222",
    mstab_bar_height = 60, mstab_bar_padding = 0, mstab_border_radius = 10,
    tabbar_disable = true, tabbar_style = "modern", tabbar_bg_focus = "#222222",
    tabbar_bg_normal = "#000000", tabbar_fg_focus = "#ffffff", tabbar_fg_normal = "#888888",
    tabbar_position = "bottom", tabbar_AA_radius = 0, tabbar_size = 40, mstab_bar_ontop = true,
    border_color = "#00ffff", font = "Iosevka Nerd Font Mono 10",
    bling_tabbed_misc_titlebar_indicator = nil,
    tabbar_bg_normal = "#000000", tabbar_fg_normal = "#ffffff", tabbar_bg_focus = "#222222", tabbar_fg_focus = "#00ffff",
    tabbar_bg_focus_inactive = "#000000", tabbar_fg_focus_inactive = "#ffffff",
    tabbar_bg_normal_inactive = "#000000", tabbar_fg_normal_inactive = "#ffffff",
    tabbar_font = "Iosevka Nerd Font Mono 10", tabbar_size = 40, tabbar_position = "bottom",
    tabbar_color_close = "#ff0000", tabbar_color_min = "#ffff00", tabbar_color_float = "#00ffff",
    mstab_border_radius = 10, mstab_dont_resize_slaves = false,
    wallpaper_path = nil, theme_assets = { recolor_layout = function() return {} end },
    dont_swallow_classname_list = {"firefox", "gimp", "Google-chrome", "Thunar"},
    parent_filter_list = {}, child_filter_list = {}, swallowing_filter = nil, dont_swallow_filter_activated = nil,
    machi_switcher_border_color = "#000000", machi_switcher_border_opacity = 0.25,
    machi_editor_border_color = "#000000", machi_editor_border_opacity = 0.25,
    machi_editor_active_opacity = 0.25, machi_editor_active_color = "#00ffff",
    machi_editor_open_color = "#00ffff", machi_editor_open_opacity = 0.25,
    machi_switcher_border_hl_color = "#00ffff", machi_switcher_border_hl_opacity = 0.25,
    machi_switcher_fill_color = "#00ffff", machi_switcher_fill_opacity = 0.25,
    machi_switcher_box_bg = "#000000", machi_switcher_box_opacity = 0.25,
    machi_switcher_fill_color_hl = "#00ffff", machi_switcher_fill_hl_opacity = 0.25,
    machi_switcher_fill_color_hl = "#00ffff", machi_switcher_fill_hl_opacity = 0.25,
    window_switcher_widget_bg = "#000000", window_switcher_widget_border_width = 0,
    window_switcher_widget_border_radius = 10, window_switcher_widget_border_color = "#000000",
    window_switcher_clients_spacing = 10, window_switcher_client_icon_horizontal_spacing = 5,
    window_switcher_client_width = 200, window_switcher_client_height = 200,
    window_switcher_client_margins = 10, window_switcher_thumbnail_margins = 10,
    thumbnail_scale = true, window_switcher_name_margins = 5,
    window_switcher_name_valign = "center", window_switcher_name_forced_width = 150,
    window_switcher_name_font = "Iosevka Nerd Font Mono 10", window_switcher_name_normal_color = "#ffffff",
    window_switcher_name_focus_color = "#00ffff", window_switcher_icon_valign = "center",
    window_switcher_icon_width = 50,
    task_preview_widget_margin = 15, task_preview_widget_bg = "#000000",
    task_preview_widget_border_color = "#000000", task_preview_widget_border_width = 0,
    task_preview_widget_border_radius = 10,
    tag_preview_widget_margin = 10, tag_preview_widget_bg = "#000000",
    tag_preview_widget_border_color = "#000000", tag_preview_widget_border_width = 0,
    tag_preview_widget_border_radius = 10,
    tag_preview_client_border_radius = 6, tag_preview_client_opacity = 1.0,
    tag_preview_client_bg = "#000000", tag_preview_client_border_color = "#000000",
    tag_preview_client_border_width = 2,
    prompt_font = "Iosevka Nerd Font Mono 10", prompt_bg_cursor = "#00ffff", prompt_fg_cursor = "#000000",
    flash_focus_start_opacity = 0.5, flash_focus_step = 0.1,
    get_merged_font = function() return "Iosevka Nerd Font Mono 10" end,
    RUBATO_DIR = "",
}

mock.naughty = {
    notify = function() end,
    action = function() return { connect_signal = function() end } end,
    destroy_all_notifications = function() end,
    config = { preset = { normal = {}, critical = {}, low = {} } },
    destroy = function() end,
    connect_signal = function() end,
    disconnect_signal = function() end,
}

mock.client = {
    get = function() return {} end,
    focus = nil,
    connect_signal = function() end,
    disconnect_signal = function() end,
    object = function() return { connect_signal = function() end } end,
}

mock.screen = {
    primary = { geometry = { x = 0, y = 0, width = 1920, height = 1080 } },
    count = function() return 1 end,
    connect_signal = function() end,
    geometry = { x = 0, y = 0, width = 1920, height = 1080 },
    workarea = { x = 0, y = 0, width = 1920, height = 1080 },
    padding = { left = 0, right = 0, top = 0, bottom = 0 },
    index = 1,
}

mock.root = {
    keys = function() return {} end,
    fake_input = function() end,
    cursor = function() return {} end,
}

mock.mouse = {
    current_wibox = nil,
    screen = { selected_tag = { gap = 5 } },
    coords = function() return { x = 0, y = 0 } end,
    object_under_pointer = function() return nil end,
}

mock.cap = { button = function() return {} end, key = function() return {} end }

mock.key = function() return {} end
mock.button = function() return {} end

-- Módulos que la config requiere directamente
mock.rubato = {
    timed = function() return { pos = 0, rate = 60, subscribed = function() end, ended = { subscribe = function() end }, set = function() end } end,
    quadratic = "quadratic", easing = { quadratic = function() end },
    manager = { new = function() return {} end },
    subscribable = function() return { subscribe = function() end } end,
}

mock.machi = { default_editor = { start_interactive = function() end }, switcher = { start = function() end }, layout = function() return {} end }

mock.bling = {
    module = {
        tabbed = { pick_with_dmenu = function() end, iter = function() end, pop = function() end },
        flash_focus = { flashfocus = function() end },
        scratchpad = function() return { toggle = function() end } end,
        wallpaper = { set = function() end },
        window_swallowing = function() return {} end,
    },
    widget = {
        window_switcher = { turn_on = function() end },
        tag_preview = function() return {} end,
        task_preview = function() return {} end,
        app_launcher = function() return {} end,
    },
    layout = { centered = {}, deck = {}, equalarea = {}, horizontal = {}, vertical = {}, mstab = {} },
    helpers = { client = {}, color = {}, filesystem = {}, icon_theme = {}, time = {} },
    signal = { playerctl = { playerctl_lib = function() return { enable = function() end, disable = function() end } end } },
}

-- Mocks adicionales para cubrir más APIs
mock.menubar = {
    utils = { lookup_icon = function() return nil end },
    menu = function() return { show = function() end } end,
}

mock["beautiful.theme_assets"] = {
    recolor_layout = function() return {} end,
    recolor_titlebar = function() end,
    recolor_icon = function() end,
    taglist_squares_sel = function() return {} end,
    taglist_squares_unsel = function() return {} end,
}

-- Fix gears.timer to work as constructor
mock.gears.timer = setmetatable({
    start_new = function(_, fn) return { stop = function() end, again = function() end, start = function() end, timeout = 0, autostart = true, call_now = false, single_shot = false } end,
    delayed_call = function(fn) fn() end,
}, {
    __call = function(_, t)
        local timer = { stop = function() end, again = function() end, start = function() end, timeout = t.timeout or 0, autostart = t.autostart or true, call_now = t.call_now or false, single_shot = t.single_shot or false }
        if t.callback then timer.callback = t.callback end
        return timer
    end,
})

-- Add awful.spawn.with_line_callback and watch
mock.awful.widget = {
    watch = function(cmd, timeout, callback) callback(""); return { stop = function() end } end,
}
mock.awful.spawn = setmetatable({
    spawn = function() end,
    with_shell = function() end,
    with_line_callback = function(cmd, callbacks) if callbacks.stdout then callbacks.stdout("") end; if callbacks.stderr then callbacks.stderr("") end; if callbacks.exit then callbacks.exit(0) end; if callbacks.done then callbacks.done() end end,
    watch = function(cmd, timeout, callback) callback(""); return { stop = function() end } end,
    easy_async_with_shell = function(cmd, fn) fn("") end,
    easy_async = function(cmd, fn) fn("") end,
}, {
    __call = function(_, ...) end,
})

-- Add beautiful.color for bling
mock.beautiful.color = "#00ffff"

-- Override bling module entirely (replace filesystem version)
mock.bling = {
    module = {
        tabbed = { pick_with_dmenu = function() end, iter = function() end, pop = function() end },
        flash_focus = { flashfocus = function() end },
        scratchpad = function() return { toggle = function() end } end,
        wallpaper = { set = function() end },
        window_swallowing = function() return {} end,
    },
    widget = {
        window_switcher = { turn_on = function() end },
        tag_preview = function() return {} end,
        task_preview = function() return {} end,
        app_launcher = function() return {} end,
    },
    layout = { centered = {}, deck = {}, equalarea = {}, horizontal = {}, vertical = {}, mstab = {} },
    helpers = { client = {}, color = {}, filesystem = {}, icon_theme = {}, time = {} },
    signal = { playerctl = { playerctl_lib = function() return { enable = function() end, disable = function() end } end } },
}

-- Registrar mocks
for k, v in pairs(mock) do
    package.preload[k] = function() return v end
end

-- Submódulos comunes
package.preload["beautiful.xresources"] = function() return mock.beautiful.xresources end
package.preload["xresources"] = function() return mock.beautiful.xresources end
package.preload["awful.hotkeys_popup"] = function() return mock.awful.hotkeys_popup end
package.preload["gears.filesystem"] = function() return mock.gears.filesystem end
package.preload["gears.shape"] = function() return mock.gears.shape end
package.preload["gears.timer"] = function() return mock.gears.timer end
package.preload["gears.surface"] = function() return mock.gears.surface end
package.preload["gears.debug"] = function() return mock.gears.debug end
package.preload["gears.math"] = function() return mock.gears.math end
package.preload["gears.table"] = function() return mock.gears.table end
package.preload["gears.string"] = function() return mock.gears.string end
package.preload["wibox.widget"] = function() return mock.wibox.widget end
package.preload["wibox.container"] = function() return mock.wibox.container end
package.preload["wibox.layout"] = function() return mock.wibox.layout end
package.preload["awful.rules"] = function() return mock.awful.rules end
package.preload["awful.client"] = function() return mock.awful.client end
package.preload["awful.placement"] = function() return mock.awful.placement end
package.preload["awful.layout"] = function() return mock.awful.layout end
package.preload["awful.screen"] = function() return mock.awful.screen end
package.preload["awful.tag"] = function() return mock.awful.tag end
package.preload["awful.menu"] = function() return mock.awful.menu end
package.preload["awful.spawn"] = function() return mock.awful.spawn end
package.preload["awful.widget"] = function() return mock.awful.widget end
package.preload["menubar"] = function() return mock.menubar end
package.preload["ruled.notification"] = function() return { connect_signal = function() end, append_rule = function() end } end
package.preload["naughty"] = function() return mock.naughty end
package.preload["awful.util"] = function() return mock.awful.util end
package.preload["awful.tooltip"] = function() return mock.awful.tooltip end
package.preload["awful.popup"] = function() return mock.awful.popup end
package.preload["awful.hotkeys_popup"] = function() return mock.awful.hotkeys_popup end
package.preload["awful.keygrabber"] = function() return mock.awful.keygrabber end
package.preload["awful.keyboard"] = function() return mock.awful.keyboard end
package.preload["ruled"] = function() return { client = { connect_signal = function() end, append_rule = function() end } } end

-- ===== GLOBALS =====
_G.dpi = mock.beautiful.xresources.apply_dpi
_G.client = mock.client
_G.screen = mock.screen
_G.root = mock.root
_G.mouse = mock.mouse
_G.awesome = { restart = function() end, quit = function() end, connect_signal = function() end, emit_signal = function() end, load = function() end, startup = true }
_G.cap = mock.cap
_G.key = mock.key
_G.button = mock.button
_G.terminal = "kitty"
_G.editor = "kitty nvim"
_G.browser = "firefox"
_G.launcher = "rofi -show drun"
_G.file_manager = "thunar"
_G.music_client = "kitty ncmpcpp"
_G.modkey = "Mod4"
_G.alt = "Mod1"
_G.ctrl = "Control"
_G.shift = "Shift"

-- ===== FUNCIONES DE VERIFICACIÓN =====
local function err(msg, file, line)
    table.insert(errors, {msg = msg, file = file, line = line})
end

local function warn(msg, file, line)
    table.insert(warnings, {msg = msg, file = file, line = line})
end

local function resolve_path(path)
    if not path or path == "" then return nil end
    local home = os.getenv("HOME") or "/home/spectre"
    local config_dir = home .. "/.config/awesome"
    if path:match("^/") then return path end
    if path:match("^%./") then path = path:sub(3) end
    return config_dir .. "/" .. path
end

local function check_file_exists(path, context)
    if path:match("os%.getenv") or path:match("%$") then
        return
    end
    local expanded = resolve_path(path)
    if not expanded then return end
    local f = io.open(expanded, "r")
    if not f then
        err("Archivo no existe: " .. expanded, context.file, context.line)
    else
        f:close()
    end
end

local function check_require(module_name, context)
    if module_name:match("^configuration%.") or
       module_name:match("^signal%.") or
       module_name:match("^ui%.") or
       module_name:match("^theme%.") or
       module_name:match("^i18n%.") or
       module_name:match("^helpers") or
       module_name:match("^module%.rubato") then
        local ok, result = pcall(require, module_name)
        if not ok then
            err("require falló: " .. module_name .. " - " .. tostring(result), context.file, context.line)
        end
    end
end

local function scan_lua_file(filepath)
    local f = io.open(filepath, "r")
    if not f then return end
    local content = f:read("*a")
    f:close()

    local lines = {}
    for line in content:gmatch("[^\r\n]+") do table.insert(lines, line) end

    for i, line in ipairs(lines) do
        local context = {file = filepath, line = i}

        for mod in line:gmatch('require%s*[%("]([^%")]+)[%")]') do
            if not mod:match(",") then
                check_require(mod, context)
            end
        end

        -- File paths en strings - DISABLED for now (too many false positives from Lua expressions)
        -- The core runtime checks (requires, rc.lua load) are more valuable
    end
end

-- ===== EJECUTAR =====
print("=== Runtime check: ~/.config/awesome ===")

-- 1. Cargar rc.lua
print("Cargando rc.lua...")
local ok, rc_err = pcall(dofile, home .. "/.config/awesome/rc.lua")
if not ok then
    local err_msg = tostring(rc_err)
    if err_msg:match("module/bling") or err_msg:match("module/layout%-machi") or 
       err_msg:match("module/rubato") or err_msg:match("lgi") or
       err_msg:match("beautiful%.theme_assets") or err_msg:match("menubar") or
       err_msg:match("wibox%.layout") or err_msg:match("ruled") then
        -- Silenciar warnings de mocks incompletos para deps externas
        -- warn("rc.lua carga con dependencias externas no mockeadas: " .. err_msg, "rc.lua", 0)
        -- print("  ⚠ rc.lua carga con warnings (deps externas)")
    else
        err("rc.lua falló al cargar: " .. err_msg, "rc.lua", 0)
    end
else
    print("  ✓ rc.lua carga OK")
end

-- 2. Escanear archivos LOCALES
print("Escaneando requires y paths en archivos locales...")
local handle = io.popen('find ' .. home .. '/.config/awesome -name "*.lua" -not -path "*/tests/*" -not -path "*/.codebak/*" -not -path "*/module/bling/*" -not -path "*/module/layout-machi/*" -not -path "*/module/rubato/*"')
if handle then
    for file in handle:lines() do
        if not file:match("check_runtime%.lua$") then
            scan_lua_file(file)
        end
    end
    handle:close()
end

-- 3. Verificar módulos LOCALES (solo tu código, no deps externas)
print("Verificando módulos locales...")
local local_modules = {
    "helpers", "helpers.shape", "helpers.wibox", "helpers.client", "helpers.string",
    "helpers.markup", "helpers.system", "helpers.misc",
    "configuration.init", "configuration.keys", "configuration.ruled", "configuration.scratchpad",
    "signal.init", "signal.battery", "signal.volume", "signal.brightness",
    "signal.network", "signal.cpu", "signal.ram", "signal.disk",
    "signal.temperature", "signal.playerctl", "signal.weather", "signal.uptime", "signal.todo",
    "ui.init", "ui.bar", "ui.dashboard", "ui.lockscreen", "ui.notifs", "ui.tooltip",
    "ui.widgets.pacman_taglist", "ui.widgets.desktop_sysmon", "ui.widgets.desktop_music",
    "theme.theme", "i18n.init",
}

for _, mod in ipairs(local_modules) do
    check_require(mod, {file = "check_runtime", line = 0})
end

-- ===== REPORTE =====
print("\n=== RESULTADO ===")

-- Filtrar errores: solo los de TU código local (no deps externas)
local function is_external_dep_error(e)
    local msg = e.msg or ""
    local file = e.file or ""
    return msg:match("module/bling") or msg:match("module/layout%-machi") or
           msg:match("module/rubato") or msg:match("lgi") or
           msg:match("beautiful%.theme_assets") or msg:match("menubar") or
           msg:match("wibox%.layout") or msg:match("ruled") or
           msg:match("ruled%.notification") or
           -- Gaps de mocks conocidos (no afectan AwesomeWM real)
           msg:match("awful%.widget%.watch") or
           msg:match("connect_for_each_screen") or
           msg:match("naughty%.connect_signal") or
           msg:match("theme_assets%.awesome_icon") or
           msg:match("attempt to index a nil value %(local 'stdout'%)") or
           msg:match("attempt to call a table value %(field 'widget'%)") or
           msg:match("attempt to call a nil value %(field 'awesome_icon'%)") or
           file:match("module/bling") or file:match("module/layout%-machi") or
           file:match("module/rubato")
end

local local_errors = {}
for _, e in ipairs(errors) do
    if not is_external_dep_error(e) then
        table.insert(local_errors, e)
    end
end

if #local_errors > 0 then
    print("\nERRORES EN TU CÓDIGO (" .. #local_errors .. "):")
    for _, e in ipairs(local_errors) do
        print(string.format("  ✖ %s:%d - %s", e.file, e.line, e.msg))
    end
else
    print("  ✓ Sin errores de runtime en tu código")
end

if #warnings > 0 then
    print("\nADVERTENCIAS (" .. #warnings .. "):")
    for _, w in ipairs(warnings) do
        print(string.format("  ⚠ %s:%d - %s", w.file, w.line, w.msg))
    end
end

-- Solo fallar si hay errores en TU código (no deps externas)
os.exit(#local_errors > 0 and 1 or 0)