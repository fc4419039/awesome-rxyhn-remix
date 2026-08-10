local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local rubato = require("module.rubato")
local helpers = require("helpers")
local i18n = require("i18n")

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
    local menu_w = style.menu_w or beautiful.dashboard_width or dpi(300)
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
    local col_spacing = style.col_spacing or dpi(10)
    local btn_w = (menu_w - margin * 2 - row_spacing - col_spacing) / 2

    local screen_height = s.geometry.height

    local header_font = style.header_font or beautiful.font_name .. "8"
    local header_text = style.header_text or "ESC para cerrar"
    local header_color = style.header_color or beautiful.xcolor6

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
        bg._callback = callback

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

    local header_w = wibox.widget{
        markup = helpers.colorize_text(header_text, header_color),
        font = header_font,
        align = "center",
        valign = "center",
        forced_height = dpi(18),
        widget = wibox.widget.textbox
    }

    local function row(btn1, btn2)
        if btn2 then
            local w = wibox.widget{
                btn1,
                btn2,
                spacing = col_spacing,
                layout = wibox.layout.fixed.horizontal
            }
            btn1.forced_width = btn_w
            btn2.forced_width = btn_w
            return w
        end
        local w = wibox.widget{
            btn1,
            spacing = row_spacing,
            layout = wibox.layout.fixed.horizontal
        }
        btn1.forced_width = btn_w
        return w
    end

    local function row_single(btn)
        btn.forced_width = menu_w - margin * 2
        return btn
    end

    local count_rows = 17
    local menu_h = screen_height - dpi(30)

    local menu = wibox({
        type = "dialog",
        screen = s,
        height = menu_h,
        width = menu_w,
        shape = helpers.rrect(beautiful.dashboard_radius),
        bg = menu_bg,
        ontop = true,
        visible = false,
    })

    menu.y = dpi(15)

    local slide = rubato.timed{
        pos = s.geometry.x + dpi(-290),
        rate = 60,
        intro = 0.05,
        duration = 0.4,
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
        slide:set(s.geometry.x + dpi(64))
        menu_open = true
    end

    local function hide()
        slide:set(s.geometry.x - 375)
        menu_open = false
    end

    menu._show = show
    menu._hide = hide

    local function toggle()
        if menu_open then
            hide()
        else
            show()
        end
    end
    menu._toggle = toggle

    -- Keyboard navigation (2D grid: rows = filas, cols = botones dentro de la fila)
    local button_grid = {}
    local focused_row = 1
    local focused_col = 1
    local keygrabber_active = false

    local function get_focused_btn()
        local row = button_grid[focused_row]
        if not row then return nil end
        local col = math.min(focused_col, #row)
        return row[col]
    end

    local function update_focus()
        for _, row_btns in ipairs(button_grid) do
            for _, btn in ipairs(row_btns) do
                btn.bg = btn_bg
            end
        end
        local btn = get_focused_btn()
        if btn then btn.bg = hover_c end
    end

    local function grab_keys()
        -- Ensure any existing keygrabber is stopped first
        if keygrabber_active then
            awful.keygrabber.stop()
            keygrabber_active = false
        end
        keygrabber_active = true
        focused_row = 1
        focused_col = 1
        update_focus()
        awful.keygrabber.run(function(_, key, event)
            -- Only handle key press events, ignore release/repeat
            if event ~= "press" then return true end

            local row_count = #button_grid
            if focused_row < 1 then focused_row = 1 end
            if focused_row > row_count then focused_row = row_count end

            if key == "Up" then
                focused_row = focused_row - 1
                if focused_row < 1 then focused_row = row_count end
                focused_col = math.min(focused_col, #button_grid[focused_row])
                update_focus()
                return true
            elseif key == "Down" then
                focused_row = focused_row + 1
                if focused_row > row_count then focused_row = 1 end
                focused_col = math.min(focused_col, #button_grid[focused_row])
                update_focus()
                return true
            elseif key == "Left" then
                focused_col = focused_col - 1
                if focused_col < 1 then focused_col = #button_grid[focused_row] end
                update_focus()
                return true
            elseif key == "Right" then
                focused_col = focused_col + 1
                if focused_col > #button_grid[focused_row] then focused_col = 1 end
                update_focus()
                return true
            elseif key == "Return" or key == "KP_Enter" then
                local btn = get_focused_btn()
                if btn and btn._callback then
                    btn._callback()
                end
                return false
            elseif key == "Escape" then
                hide()
                return false
            elseif key == "Mod4" or key == "Super_L" or key == "Super_R" then
                hide()
                return false
            end
            return true
        end)
    end

    local function ungrab_keys()
        if keygrabber_active then
            awful.keygrabber.stop()
            keygrabber_active = false
        end
        focused_row = 1
        focused_col = 1
        update_focus()
    end

    local original_show = show
    local original_hide = hide
    show = function()
        original_show()
        grab_keys()
    end
    hide = function()
        original_hide()
        ungrab_keys()
    end
    menu._show = show
    menu._hide = hide

    local network_btn = create_btn("", i18n.tr("sm.network"), beautiful.xcolor2, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/network.sh")
    end)

    local bluetooth_btn = create_btn("", i18n.tr("sm.bluetooth"), beautiful.xcolor5, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/bluetooth.sh")
    end)

    local blur_btn = create_btn("", i18n.tr("sm.blur"), beautiful.xcolor4, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/toggle-blur.sh")
    end)

local transparency_btn = create_btn("", i18n.tr("sm.transparency"), beautiful.xcolor6, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/toggle-transparency.sh")
    end)

    local night_mode_btn = create_btn("", i18n.tr("sm.night"), beautiful.xcolor5, function()
        hide()
        awful.spawn.with_shell("redshift -O 3500")
    end)

    local wallpaper_btn = create_btn("", i18n.tr("sm.wallpaper"), beautiful.xcolor4, function()
        hide()
        require("ui.system_menu.wallpaper_picker").toggle()
    end)

    local volume_btn = create_btn("", i18n.tr("sm.volume"), beautiful.xcolor4, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/volumen")
    end)

    local music_btn = create_btn("", i18n.tr("sm.music"), beautiful.xcolor5, function()
        hide()
        awful.spawn(music_client)
    end)

    local accent_btn = create_btn("", i18n.tr("sm.accent"), beautiful.xcolor5, function()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/cycle-accent.sh")
    end)

    local titlebar_btn = create_btn("", i18n.tr("sm.titlebar"), beautiful.xcolor6, function()
        hide()
        toggle_window_titlebars()
    end)

    local border_btn = create_btn("", i18n.tr("sm.borders"), beautiful.xcolor5, function()
        hide()
        toggle_window_borders()
    end)

    local sddm_btn = create_btn("", i18n.tr("sm.sddm"), beautiful.xcolor6, function()
        hide()
        require("ui.system_menu.sddm_picker").toggle()
    end)

    local apps_btn = create_btn("", i18n.tr("sm.apps"), beautiful.xcolor2, function()
        hide()
        awful.spawn(launcher)
    end)

    local opencode_btn = create_btn("", i18n.tr("sm.opencode"), beautiful.xcolor4, function()
        hide()
        awful.spawn.with_shell(terminal .. " -e " .. opencode_bin)
    end)

    local resources_btn = create_btn("", i18n.tr("sm.resources"), beautiful.xcolor2, function()
        hide()
        require("ui.widgets.resources").toggle()
    end)

    local calculator_btn = create_btn("", i18n.tr("sm.calculator"), beautiful.xcolor6, function()
        hide()
        require("ui.widgets.calculator").toggle()
    end)

    local color_temp_btn = create_btn("", i18n.tr("sm.color_temp"), beautiful.xcolor3, function()
        hide()
        require("ui.system_menu.color_temp").create(awful.screen.focused())._toggle()
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

    local widgets_btn = create_btn("", i18n.tr("sm.widgets"), beautiful.xcolor3, function()
        hide()
        toggle_osd_widgets()
    end)

    local powermenu_btn = create_btn("⏻", i18n.tr("sm.power"), beautiful.xcolor1, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/powermenu.sh")
    end)

    local timezone_btn = create_btn("", i18n.tr("sm.timezone"), beautiful.xcolor6, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/change-timezone.sh")
    end)

    local keyboard_btn = create_btn("", i18n.tr("sm.keyboard"), beautiful.xcolor4, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/change-keyboard.sh")
    end)

    local locale_btn = create_btn("", i18n.tr("sm.language"), beautiful.xcolor3, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/change-locale.sh")
    end)

    local clean_btn = create_btn("", i18n.tr("sm.clean"), beautiful.xcolor2, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/clean-orphans.sh")
    end)

    -- Register all buttons for keyboard navigation (2D grid matching the layout)
    button_grid = {
        {network_btn, bluetooth_btn},
        {blur_btn, transparency_btn},
        {night_mode_btn, wallpaper_btn},
        {volume_btn, music_btn},
        {accent_btn, titlebar_btn},
        {border_btn, sddm_btn},
        {apps_btn, opencode_btn},
        {timezone_btn, keyboard_btn},
        {locale_btn, clean_btn},
        {resources_btn, calculator_btn},
        {color_temp_btn, widgets_btn},
        {powermenu_btn},
    }

    local rows = wibox.widget{
        header_w,
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
        row(color_temp_btn, widgets_btn),
        row_single(powermenu_btn),
        spacing = row_spacing,
        layout = wibox.layout.fixed.vertical
    }

    -- menu:connect_signal("mouse::enter", function()
    --     if menu._open_timer then menu._open_timer:stop() end
    --     if menu._hide_timer then menu._hide_timer:stop() end
    -- end)

    -- menu:connect_signal("mouse::leave", function()
    --     if menu._hide_timer then menu._hide_timer:again() end
    -- end)

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
