local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local helpers = require("helpers")
local i18n = require("i18n")

local calc_wibox = nil
local calc_visible = false
local input = ""
local result = ""
local scientific_mode = false
local display_widget = nil
local result_widget = nil
local sci_rows = nil
local calc_container = nil
local calc_escape_key = nil

local accent = "#06b6d4"
local accent_dim = "#0e7490"
local bg_main = "#0d0d1a"
local bg_surface = "#1a1a2e"
local bg_display = "#141428"
local bg_input = "#1a1a2e"
local fg_main = "#e2e8f0"
local fg_dim = "#3d3d5c"
local fg_bright = "#f1f5f9"
local red = "#f87171"
local red_dim = "#4c1d25"
local green = "#34d399"
local green_dim = "#1a3a2a"
local blue = "#06b6d4"
local blue_dim = "#0c3a4a"
local purple = "#a78bfa"
local purple_dim = "#2d1f5e"
local muted = "#3d3d5c"
local border_glow = "#3d3d5c"
local border_accent = "#06b6d4"

local function update_display()
    if display_widget then
        local txt = input ~= "" and input or "0"
        display_widget.markup = helpers.colorize_text(txt, fg_bright)
    end
    if result_widget then
        local txt = result ~= "" and result or ""
        result_widget.markup = helpers.colorize_text(txt, accent)
    end
end

local function factorial(n)
    if n < 0 then return "Error" end
    if n == 0 or n == 1 then return 1 end
    if n > 170 then return "Inf" end
    local r = 1
    for i = 2, n do r = r * i end
    return r
end

local function calculate()
    local expr = input
    if expr == "" then return end

    local open_count = 0
    local close_count = 0
    for _ in expr:gmatch("%(") do open_count = open_count + 1 end
    for _ in expr:gmatch("%)") do close_count = close_count + 1 end
    for _ = 1, open_count - close_count do
        expr = expr .. ")"
    end

    if expr ~= input then
        input = expr
        update_display()
    end

    expr = expr:gsub("×", "*")
    expr = expr:gsub("÷", "/")

    expr = expr:gsub("π", tostring(math.pi))
    expr = expr:gsub("([^%a])e([^%a])", "%1math.e%2")
    expr = expr:gsub("^e([^%a])", "math.e%1")
    expr = expr:gsub("([^%a])e$", "%1math.e")
    expr = expr:gsub("^e$", "math.e")
    expr = expr:gsub("^(%d+)!", function(n)
        return tostring(factorial(tonumber(n)))
    end)

    local fn_map = {
        sin = "math.sin", cos = "math.cos", tan = "math.tan",
        ln = "math.log", log = "math.log10",
        ["√"] = "math.sqrt", abs = "math.abs",
    }
    for k, v in pairs(fn_map) do
        expr = expr:gsub(k .. "%(", v .. "(")
    end

    local ok, res = pcall(load, "return " .. expr)
    if ok and res then
        local ok2, val = pcall(res)
        if ok2 and val then
            if type(val) == "number" then
                if val == math.floor(val) and math.abs(val) < 1e15 then
                    result = tostring(math.floor(val))
                else
                    result = string.format("%.10g", val)
                end
            else
                result = tostring(val)
            end
        else
            result = "Error"
        end
    else
        result = "Error"
    end
    update_display()
end

local function append_to_input(text)
    input = input .. text
    update_display()
end

local function clear_all()
    input = ""
    result = ""
    update_display()
end

local function backspace()
    input = input:sub(1, -2)
    update_display()
end

local function toggle_scientific()
    scientific_mode = not scientific_mode
    if sci_rows then
        sci_rows.visible = scientific_mode
    end
    if calc_wibox then
        if scientific_mode then
            calc_wibox.height = dpi(500)
        else
            calc_wibox.height = dpi(390)
        end
        awful.placement.centered(calc_wibox, {honor_workarea = true})
    end
end

local function make_button(text, bg, fg, hover_bg, width, height, callback, font_size)
    local label = wibox.widget{
        markup = helpers.colorize_text(text, fg or fg_main),
        font = beautiful.font_name .. "bold " .. tostring(font_size or 12),
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }

    local btn = wibox.widget{
        {
            label,
            margins = dpi(2),
            widget = wibox.container.margin
        },
        forced_width = width,
        forced_height = height,
        shape = helpers.rrect(dpi(8)),
        bg = bg,
        border_width = dpi(1),
        border_color = border_glow,
        widget = wibox.container.background
    }

    btn:connect_signal("mouse::enter", function()
        btn.bg = hover_bg or bg
        btn.border_color = border_accent
        label.markup = helpers.colorize_text(text, "#ffffff")
    end)
    btn:connect_signal("mouse::leave", function()
        btn.bg = bg
        btn.border_color = border_glow
        label.markup = helpers.colorize_text(text, fg or fg_main)
    end)
    btn:connect_signal("button::press", function()
        btn.bg = hover_bg or bg
    end)
    btn:connect_signal("button::release", function()
        btn.bg = bg
    end)
    btn:buttons(gears.table.join(
        awful.button({}, 1, function() callback() end)
    ))

    return btn
end

local function start_move(w)
    if not w then return end
    local g = w:geometry()
    local mx, my = mouse.coords().x, mouse.coords().y
    local ox, oy = g.x - mx, g.y - my
    mousegrabber.run(function(m)
        if not m.buttons[1] then return false end
        w.x = ox + m.x
        w.y = oy + m.y
        return true
    end, "fleur")
end

local function start_resize(w)
    if not w then return end
    local g = w:geometry()
    local mx, my = mouse.coords().x, mouse.coords().y
    local ox = g.x + g.width - mx
    local oy = g.y + g.height - my
    mousegrabber.run(function(m)
        if not m.buttons[3] then return false end
        local new_w = math.max(dpi(280), m.x + ox - g.x)
        local new_h = math.max(dpi(300), m.y + oy - g.y)
        w.width = new_w
        w.height = new_h
        return true
    end, "sizing")
end

local function close_calc()
    if calc_wibox then
        calc_wibox.visible = false
        calc_visible = false
    end
    if calc_escape_key then
        local keys = root.keys()
        local new_keys = {}
        for _, k in ipairs(keys) do
            if k ~= calc_escape_key then
                table.insert(new_keys, k)
            end
        end
        root.keys(new_keys)
        calc_escape_key = nil
    end
end

local function create()
    if calc_wibox then return end

    local screen = awful.screen.focused()
    local btn_w = dpi(48)
    local btn_h = dpi(38)
    local spacing = dpi(5)

    -- Title bar buttons
    local close_btn = wibox.widget{
        forced_width = dpi(14),
        forced_height = dpi(14),
        shape = gears.shape.circle,
        bg = red,
        widget = wibox.container.background
    }
    close_btn:connect_signal("mouse::enter", function()
        close_btn.bg = "#ff8a98"
    end)
    close_btn:connect_signal("mouse::leave", function()
        close_btn.bg = red
    end)
    close_btn:buttons(gears.table.join(
        awful.button({}, 1, function() close_calc() end)
    ))

    local minimize_btn = wibox.widget{
        forced_width = dpi(14),
        forced_height = dpi(14),
        shape = gears.shape.circle,
        bg = "#e0af68",
        widget = wibox.container.background
    }
    minimize_btn:connect_signal("mouse::enter", function()
        minimize_btn.bg = "#f0c878"
    end)
    minimize_btn:connect_signal("mouse::leave", function()
        minimize_btn.bg = "#e0af68"
    end)

    local maximize_btn = wibox.widget{
        forced_width = dpi(14),
        forced_height = dpi(14),
        shape = gears.shape.circle,
        bg = green,
        widget = wibox.container.background
    }
    maximize_btn:connect_signal("mouse::enter", function()
        maximize_btn.bg = "#b0ee88"
    end)
    maximize_btn:connect_signal("mouse::leave", function()
        maximize_btn.bg = green
    end)

    local window_dots = wibox.widget{
        {
            close_btn,
            minimize_btn,
            maximize_btn,
            spacing = dpi(7),
            layout = wibox.layout.fixed.horizontal
        },
        margins = { left = dpi(12), top = dpi(10), bottom = dpi(10) },
        widget = wibox.container.margin
    }

    local title_text = wibox.widget{
        markup = helpers.colorize_text(i18n.tr("widget.calculator"), fg_dim),
        font = beautiful.font_name .. "9",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }

    local titlebar = wibox.widget{
        {
            window_dots,
            title_text,
            {
                forced_width = dpi(72),
                widget = wibox.container.background
            },
            expand = "none",
            layout = wibox.layout.align.horizontal
        },
        bg = bg_surface,
        shape = function(cr, w, h)
            gears.shape.partially_rounded_rect(cr, w, h, true, true, false, false, dpi(12))
        end,
        widget = wibox.container.background
    }

    titlebar:buttons(gears.table.join(
        awful.button({}, 1, function() start_move(calc_wibox) end),
        awful.button({"Mod4"}, 1, function() start_move(calc_wibox) end)
    ))

    -- Display
    display_widget = wibox.widget{
        markup = helpers.colorize_text("0", fg_bright),
        font = beautiful.font_name .. "bold 22",
        align = "right",
        valign = "center",
        forced_width = dpi(280),
        widget = wibox.widget.textbox
    }

    result_widget = wibox.widget{
        markup = helpers.colorize_text("", accent),
        font = beautiful.font_name .. "10",
        align = "right",
        valign = "center",
        forced_width = dpi(280),
        widget = wibox.widget.textbox
    }

    local display_area = wibox.widget{
        display_widget,
        result_widget,
        spacing = dpi(4),
        layout = wibox.layout.fixed.vertical
    }

    local display_container = wibox.widget{
        display_area,
        margins = { left = dpi(14), right = dpi(14), top = dpi(12), bottom = dpi(12) },
        bg = bg_display,
        shape = helpers.rrect(dpi(8)),
        border_width = dpi(1),
        border_color = border_glow,
        widget = wibox.container.margin
    }

    -- Scientific buttons
    local sci_fns = {
        { text = "sin", fn = function() append_to_input("sin(") end },
        { text = "cos", fn = function() append_to_input("cos(") end },
        { text = "tan", fn = function() append_to_input("tan(") end },
        { text = "ln",  fn = function() append_to_input("ln(") end },
        { text = "log", fn = function() append_to_input("log(") end },
        { text = "√",   fn = function() append_to_input("√(") end },
        { text = "x²",  fn = function() append_to_input("^2") end },
        { text = "xʸ",  fn = function() append_to_input("^") end },
        { text = "x!",  fn = function() append_to_input("!") end },
        { text = "π",   fn = function() append_to_input("π") end },
        { text = "e",   fn = function() append_to_input("e") end },
        { text = "(",   fn = function() append_to_input("(") end },
        { text = ")",   fn = function() append_to_input(")") end },
    }

    local sci_btn_w = dpi(48)
    local sci_btn_h = dpi(32)

    local sci_row1 = wibox.widget{
        make_button(sci_fns[1].text, purple_dim, purple, "#3d2a7a", sci_btn_w, sci_btn_h, sci_fns[1].fn, 10),
        make_button(sci_fns[2].text, purple_dim, purple, "#3d2a7a", sci_btn_w, sci_btn_h, sci_fns[2].fn, 10),
        make_button(sci_fns[3].text, purple_dim, purple, "#3d2a7a", sci_btn_w, sci_btn_h, sci_fns[3].fn, 10),
        make_button(sci_fns[4].text, purple_dim, purple, "#3d2a7a", sci_btn_w, sci_btn_h, sci_fns[4].fn, 10),
        make_button(sci_fns[5].text, purple_dim, purple, "#3d2a7a", sci_btn_w, sci_btn_h, sci_fns[5].fn, 10),
        spacing = spacing,
        layout = wibox.layout.fixed.horizontal
    }

    local sci_row2 = wibox.widget{
        make_button(sci_fns[6].text, purple_dim, purple, "#3d2a7a", sci_btn_w, sci_btn_h, sci_fns[6].fn, 10),
        make_button(sci_fns[7].text, purple_dim, purple, "#3d2a7a", sci_btn_w, sci_btn_h, sci_fns[7].fn, 10),
        make_button(sci_fns[8].text, purple_dim, purple, "#3d2a7a", sci_btn_w, sci_btn_h, sci_fns[8].fn, 10),
        make_button(sci_fns[9].text, purple_dim, purple, "#3d2a7a", sci_btn_w, sci_btn_h, sci_fns[9].fn, 10),
        make_button(sci_fns[10].text, purple_dim, purple, "#3d2a7a", sci_btn_w, sci_btn_h, sci_fns[10].fn, 10),
        spacing = spacing,
        layout = wibox.layout.fixed.horizontal
    }

    local sci_row3 = wibox.widget{
        make_button(sci_fns[11].text, purple_dim, purple, "#3d2a7a", sci_btn_w, sci_btn_h, sci_fns[11].fn, 10),
        make_button(sci_fns[12].text, purple_dim, purple, "#3d2a7a", sci_btn_w, sci_btn_h, sci_fns[12].fn, 10),
        make_button(sci_fns[13].text, purple_dim, purple, "#3d2a7a", sci_btn_w, sci_btn_h, sci_fns[13].fn, 10),
        spacing = spacing,
        layout = wibox.layout.fixed.horizontal
    }

    sci_rows = wibox.widget{
        sci_row1,
        sci_row2,
        sci_row3,
        spacing = spacing,
        layout = wibox.layout.fixed.vertical,
        visible = false
    }

    -- Basic buttons
    local row1 = wibox.widget{
        make_button("7", bg_input, nil, "#252840", btn_w, btn_h, function() append_to_input("7") end),
        make_button("8", bg_input, nil, "#252840", btn_w, btn_h, function() append_to_input("8") end),
        make_button("9", bg_input, nil, "#252840", btn_w, btn_h, function() append_to_input("9") end),
        make_button("÷", blue_dim, blue, "#0e4a5a", btn_w, btn_h, function() append_to_input("÷") end),
        make_button("C", red_dim, red, "#6b1d2d", btn_w, btn_h, clear_all),
        spacing = spacing,
        layout = wibox.layout.fixed.horizontal
    }

    local row2 = wibox.widget{
        make_button("4", bg_input, nil, "#252840", btn_w, btn_h, function() append_to_input("4") end),
        make_button("5", bg_input, nil, "#252840", btn_w, btn_h, function() append_to_input("5") end),
        make_button("6", bg_input, nil, "#252840", btn_w, btn_h, function() append_to_input("6") end),
        make_button("×", blue_dim, blue, "#0e4a5a", btn_w, btn_h, function() append_to_input("×") end),
        make_button("⌫", red_dim, red, "#6b1d2d", btn_w, btn_h, backspace),
        spacing = spacing,
        layout = wibox.layout.fixed.horizontal
    }

    local row3 = wibox.widget{
        make_button("1", bg_input, nil, "#252840", btn_w, btn_h, function() append_to_input("1") end),
        make_button("2", bg_input, nil, "#252840", btn_w, btn_h, function() append_to_input("2") end),
        make_button("3", bg_input, nil, "#252840", btn_w, btn_h, function() append_to_input("3") end),
        make_button("-", blue_dim, blue, "#0e4a5a", btn_w, btn_h, function() append_to_input("-") end),
        make_button("(", blue_dim, blue, "#0e4a5a", btn_w, btn_h, function() append_to_input("(") end),
        spacing = spacing,
        layout = wibox.layout.fixed.horizontal
    }

    local row4 = wibox.widget{
        make_button("0", bg_input, nil, "#252840", btn_w, btn_h, function() append_to_input("0") end),
        make_button(".", bg_input, nil, "#252840", btn_w, btn_h, function() append_to_input(".") end),
        make_button("=", green_dim, green, "#2a5a4a", btn_w, btn_h, calculate),
        make_button("+", blue_dim, blue, "#0e4a5a", btn_w, btn_h, function() append_to_input("+") end),
        make_button(")", blue_dim, blue, "#0e4a5a", btn_w, btn_h, function() append_to_input(")") end),
        spacing = spacing,
        layout = wibox.layout.fixed.horizontal
    }

    -- Scientific toggle
    local sci_toggle = wibox.widget{
        markup = helpers.colorize_text("SCI", accent_dim),
        font = beautiful.font_name .. "bold 8",
        align = "center",
        valign = "center",
        forced_width = dpi(32),
        forced_height = dpi(20),
        shape = helpers.rrect(dpi(5)),
        bg = bg_surface,
        border_width = dpi(1),
        border_color = border_glow,
        widget = wibox.container.background
    }
    sci_toggle:connect_signal("mouse::enter", function()
        sci_toggle.bg = "#1a1a3a"
        sci_toggle.border_color = accent
        sci_toggle.markup = helpers.colorize_text("SCI", accent)
    end)
    sci_toggle:connect_signal("mouse::leave", function()
        sci_toggle.bg = bg_surface
        sci_toggle.border_color = border_glow
        sci_toggle.markup = helpers.colorize_text("SCI", accent_dim)
    end)
    sci_toggle:buttons(gears.table.join(
        awful.button({}, 1, function()
            toggle_scientific()
            if scientific_mode then
                sci_toggle.markup = helpers.colorize_text("SCI", purple)
                sci_toggle.border_color = purple
            else
                sci_toggle.markup = helpers.colorize_text("SCI", accent_dim)
                sci_toggle.border_color = border_glow
            end
        end)
    ))

    local buttons_area = wibox.widget{
        sci_rows,
        row1,
        row2,
        row3,
        row4,
        spacing = spacing,
        layout = wibox.layout.fixed.vertical
    }

    calc_container = wibox.widget{
        {
            titlebar,
            display_container,
            {
                {
                    nil,
                    sci_toggle,
                    expand = "none",
                    layout = wibox.layout.align.horizontal
                },
                margins = { left = dpi(12), right = dpi(12), top = dpi(0), bottom = dpi(0) },
                widget = wibox.container.margin
            },
            buttons_area,
            spacing = dpi(6),
            layout = wibox.layout.fixed.vertical
        },
        margins = dpi(8),
        widget = wibox.container.margin
    }

    calc_wibox = wibox({
        type = "dialog",
        screen = screen,
        height = dpi(390),
        width = dpi(320),
        shape = helpers.rrect(dpi(12)),
        bg = bg_main,
        ontop = true,
        visible = false,
        border_width = dpi(1),
        border_color = border_accent,
    })

    awful.placement.centered(calc_wibox, {honor_workarea = true})

    calc_wibox:setup{
        calc_container,
        bg = bg_main,
        shape = helpers.rrect(dpi(12)),
        widget = wibox.container.background
    }

    calc_wibox:buttons(gears.table.join(
        awful.button({"Mod4"}, 3, function() start_resize(calc_wibox) end)
    ))
end

function toggle_calculator()
    if not calc_wibox then
        local ok, err = pcall(create)
        if not ok then
            local naughty = require("naughty")
            naughty.notify({
                title = i18n.tr("widget.calculator_error"),
                text = tostring(err),
                timeout = 10,
            })
            return
        end
    end

    if calc_visible then
        close_calc()
    else
        calc_wibox.visible = true
        calc_visible = true
        awful.placement.centered(calc_wibox, {honor_workarea = true})

        calc_escape_key = awful.key({}, "Escape", function()
            if calc_visible then
                close_calc()
            end
        end)
        root.keys(gears.table.join(root.keys(), calc_escape_key))
    end
end

_G.toggle_calculator = toggle_calculator

return { toggle = toggle_calculator }
