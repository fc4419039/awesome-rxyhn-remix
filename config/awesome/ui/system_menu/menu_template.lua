local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local rubato = require("module.rubato")
local helpers = require("helpers")

local function find_opencode()
    local handle = io.popen("command -v opencode 2>/dev/null")
    if handle then
        local result = handle:read("*a"):gsub("%s+", "")
        handle:close()
        if result ~= "" then return result end
    end
    local home = os.getenv("HOME")
    local paths = {
        home .. "/.opencode/bin/opencode",
        "/usr/local/bin/opencode",
        "/usr/bin/opencode",
        "/opt/opencode/bin/opencode",
    }
    for _, p in ipairs(paths) do
        local f = io.open(p, "r")
        if f then f:close(); return p end
    end
    return "opencode"
end

local opencode_bin = find_opencode()

local function create_menu(s, style)
    style = style or {}
    local menu_w = style.width or dpi(270)
    local menu_bg = style.bg or beautiful.xbackground
    local border_c = style.border_color or beautiful.darker_bg
    local btn_bg = style.button_bg or beautiful.dashboard_box_bg
    local hover_c = style.hover_bg or beautiful.lighter_bg
    local icon_size = style.icon_size or dpi(24)
    local icon_font = style.icon_font or beautiful.font_name .. "16"
    local label_font = style.label_font or beautiful.font_name .. "9"
    local btn_h = style.btn_height or dpi(30)
    local row_spacing = style.row_spacing or dpi(4)
    local margin = style.margin or dpi(8)
    local show_accent = style.show_accent ~= false
    local accent_op = style.accent_opacity or "40"
    local btn_w = (menu_w - margin * 2 - row_spacing) / 2

    local screen_width = s.geometry.width

    local function create_btn(icon, label, color, callback)
        local icon_w = wibox.widget{
            markup = helpers.colorize_text(icon, color),
            font = icon_font,
            align = "center",
            valign = "center",
            forced_width = icon_size,
            widget = wibox.widget.textbox
        }

        local label_w = wibox.widget{
            markup = helpers.colorize_text(label, beautiful.xforeground),
            font = label_font,
            valign = "center",
            widget = wibox.widget.textbox
        }

        local row
        if show_accent then
            local accent = wibox.widget{
                bg = color .. accent_op,
                shape = helpers.rrect(dpi(2)),
                forced_width = dpi(3),
                forced_height = dpi(16),
                widget = wibox.container.background
            }
            row = wibox.widget{
                accent,
                icon_w,
                label_w,
                spacing = dpi(4),
                layout = wibox.layout.fixed.horizontal
            }
        else
            row = wibox.widget{
                icon_w,
                label_w,
                spacing = dpi(4),
                layout = wibox.layout.fixed.horizontal
            }
        end

        local bg = wibox.container.background()
        bg:set_widget(row)
        bg.bg = btn_bg
        bg.shape = helpers.rrect(dpi(5))
        bg.forced_height = btn_h
        bg.forced_width = btn_w

        bg:connect_signal("mouse::enter", function()
            bg.bg = hover_c
            icon_w.markup = helpers.colorize_text(icon, beautiful.xforeground)
        end)

        bg:connect_signal("mouse::leave", function()
            bg.bg = btn_bg
            icon_w.markup = helpers.colorize_text(icon, color)
        end)

        bg:buttons(gears.table.join(
            awful.button({}, 1, function()
                if callback then callback() end
            end)
        ))

        return bg
    end

    local function row(btn1, btn2)
        if btn2 then
            return wibox.widget{
                btn1,
                btn2,
                spacing = row_spacing,
                layout = wibox.layout.fixed.horizontal
            }
        end
        return wibox.widget{
            btn1,
            spacing = row_spacing,
            layout = wibox.layout.fixed.horizontal
        }
    end

    local count_rows = 13
    local menu_h = count_rows * btn_h + (count_rows - 1) * row_spacing + margin * 2

    local menu = wibox({
        type = "dialog",
        screen = s,
        height = menu_h,
        width = menu_w,
        shape = helpers.rrect(dpi(12)),
        bg = menu_bg,
        ontop = true,
        visible = false,
        border_width = dpi(1),
        border_color = border_c,
    })

    menu.y = dpi(30)
    menu.x = screen_width + dpi(50)

    local slide = rubato.timed{
        pos = screen_width + dpi(50),
        rate = 60,
        intro = 0.05,
        duration = 0.35,
        easing = rubato.quadratic,
        awestore_compat = true,
        subscribed = function(pos) menu.x = pos end
    }

    local menu_open = false
    slide.ended:subscribe(function()
        if not menu_open then menu.visible = false end
    end)

    local function show()
        menu.visible = true
        slide:set(screen_width - menu_w - dpi(10))
        menu_open = true
        if menu._open_timer then menu._open_timer:again() end
    end

    local function hide()
        slide:set(screen_width + dpi(50))
        menu_open = false
        if menu._open_timer then menu._open_timer:stop() end
        if menu._hide_timer then menu._hide_timer:stop() end
    end
    menu._show = show
    menu._hide = hide

    menu._open_timer = gears.timer{
        timeout = 5,
        autostart = false,
        single_shot = true,
        callback = function()
            if menu.visible then menu._hide() end
        end
    }

    menu._hide_timer = gears.timer{
        timeout = 2,
        autostart = false,
        single_shot = true,
        callback = function()
            if menu.visible then menu._hide() end
        end
    }

    local network_btn = create_btn("", "Network", beautiful.xcolor2, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/network.sh")
    end)

    local bluetooth_btn = create_btn("", "Bluetooth", beautiful.xcolor5, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/bluetooth.sh")
    end)

    local blur_btn = create_btn("", "Blur", beautiful.xcolor4, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/toggle-blur.sh")
    end)

    local transparency_btn = create_btn("", "Transparency", beautiful.xcolor6, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/toggle-transparency.sh")
    end)

    local night_mode_btn = create_btn("", "Night", beautiful.xcolor5, function()
        hide()
        awful.spawn.with_shell("redshift -O 3500")
    end)

    local wallpaper_btn = create_btn("", "Wallpaper", beautiful.xcolor4, function()
        hide()
        require("ui.system_menu.wallpaper_picker").toggle()
    end)

    local volume_btn = create_btn("", "Volume", beautiful.xcolor4, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/volumen")
    end)

    local music_btn = create_btn("", "Music", beautiful.xcolor5, function()
        hide()
        awful.spawn(music_client)
    end)

    local accent_btn = create_btn("", "Accent", beautiful.xcolor5, function()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/cycle-accent.sh")
    end)

    local titlebar_btn = create_btn("", "Titlebar", beautiful.xcolor6, function()
        hide()
        toggle_window_titlebars()
    end)

    local border_btn = create_btn("", "Borders", beautiful.xcolor5, function()
        hide()
        toggle_window_borders()
    end)

    local sddm_btn = create_btn("", "SDDM", beautiful.xcolor6, function()
        hide()
        require("ui.system_menu.sddm_picker").toggle()
    end)

    local apps_btn = create_btn("", "Apps", beautiful.xcolor2, function()
        hide()
        awful.spawn(launcher)
    end)

    local opencode_btn = create_btn("", "OpenCode", beautiful.xcolor4, function()
        hide()
        awful.spawn.with_shell(terminal .. " -e " .. opencode_bin)
    end)

    local resources_btn = create_btn("", "Resources", beautiful.xcolor2, function()
        hide()
        require("ui.widgets.resources").toggle()
    end)

    local calculator_btn = create_btn("", "Calculator", beautiful.xcolor6, function()
        hide()
        require("ui.widgets.calculator").toggle()
    end)

    local function toggle_osd_widgets()
        for s in screen do
            if s.datetime_widget then
                s.datetime_widget.visible = not s.datetime_widget.visible
            end
            if s.desktop_sysmon then
                s.desktop_sysmon.visible = not s.desktop_sysmon.visible
            end
            if s.desktop_music then
                s.desktop_music.visible = not s.desktop_music.visible
            end

        end
    end

    local widgets_btn = create_btn("", "Widgets", beautiful.xcolor3, function()
        hide()
        toggle_osd_widgets()
    end)

    local powermenu_btn = create_btn("⏻", "Power", beautiful.xcolor1, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/powermenu.sh")
    end)

    local timezone_btn = create_btn("", "Timezone", beautiful.xcolor6, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/change-timezone.sh")
    end)

    local keyboard_btn = create_btn("", "Keyboard", beautiful.xcolor4, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/change-keyboard.sh")
    end)

    local locale_btn = create_btn("", "Language", beautiful.xcolor3, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/change-locale.sh")
    end)

    local clean_btn = create_btn("", "Clean", beautiful.xcolor2, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/clean-orphans.sh")
    end)

    local rows = wibox.widget{
        row(network_btn, bluetooth_btn),
        row(blur_btn, transparency_btn),
        row(night_mode_btn, wallpaper_btn),
        row(volume_btn, music_btn),
        row(accent_btn, titlebar_btn),
        row(border_btn, sddm_btn),
        row(apps_btn, opencode_btn),
        row(timezone_btn, keyboard_btn),
        row(locale_btn, clean_btn),
        row(resources_btn, calculator_btn),
        row(widgets_btn, powermenu_btn),
        spacing = row_spacing,
        layout = wibox.layout.fixed.vertical
    }

    menu:connect_signal("mouse::enter", function()
        if menu._open_timer then menu._open_timer:stop() end
        if menu._hide_timer then menu._hide_timer:stop() end
    end)

    menu:connect_signal("mouse::leave", function()
        if menu._hide_timer then menu._hide_timer:again() end
    end)

    local container = wibox.container.margin()
    container:set_widget(rows)
    container:set_margins(margin)

    local brand = helpers.brand_watermark()
    if brand then
        local stack = wibox.layout.stack()
        stack:add(brand)
        stack:add(container)
        menu:set_widget(stack)
    else
        menu:set_widget(container)
    end

    return menu
end

return create_menu
