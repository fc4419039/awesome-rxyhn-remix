local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local rubato = require("module.rubato")
local naughty = require("naughty")
local helpers = require("helpers")

local function create_system_menu(s)
    local screen_width = s.geometry.width
    local screen_height = s.geometry.height

    local menu = wibox({
        type = "dialog",
        screen = s,
        height = dpi(610),
        width = dpi(200),
        shape = helpers.rrect(beautiful.border_radius),
        bg = "#0a141980",
        ontop = true,
        visible = false,
    })
    menu.y = dpi(25)
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
        slide:set(screen_width - dpi(200) - dpi(10))
        menu_open = true
    end

    local function hide()
        slide:set(screen_width + dpi(50))
        menu_open = false
    end

    local hide_timer = gears.timer{
        timeout = 3,
        autostart = false,
        single_shot = true,
        callback = function()
            if menu.visible then hide() end
        end
    }

    menu:connect_signal("mouse::enter", function() hide_timer:stop() end)
    menu:connect_signal("mouse::leave", function() hide_timer:again() end)

    s.system_menu_toggle = function()
        if menu.visible then
            hide()
        else
            show()
        end
    end

    local function create_toggle_button(icon, label, color, callback)
        local icon_w = wibox.widget{
            markup = helpers.colorize_text(icon, color),
            font = beautiful.font_name .. "14",
            align = "center",
            valign = "center",
            forced_width = dpi(20),
            widget = wibox.widget.textbox
        }

        local label_w = wibox.widget{
            markup = helpers.colorize_text(label, beautiful.xforeground),
            font = beautiful.font_name .. "medium 10",
            valign = "center",
            widget = wibox.widget.textbox
        }

        local arrow = wibox.widget{
            markup = helpers.colorize_text("", beautiful.darker_bg),
            font = beautiful.font_name .. "9",
            align = "center",
            valign = "center",
            widget = wibox.widget.textbox
        }

        local accent = wibox.widget{
            bg = color,
            shape = helpers.rrect(dpi(2)),
            forced_width = dpi(3),
            forced_height = dpi(20),
            widget = wibox.container.background
        }

        local row = wibox.widget{
            accent,
            icon_w,
            label_w,
            nil,
            arrow,
            spacing = dpi(8),
            layout = wibox.layout.align.horizontal
        }

        local margin = wibox.widget{
            row,
            margins = dpi(6),
            widget = wibox.container.margin
        }

        local bg = wibox.container.background()
        bg:set_widget(margin)
        bg.bg = beautiful.dashboard_box_bg
        bg.shape = helpers.rrect(dpi(6))
        bg.forced_height = dpi(34)

        bg:connect_signal("mouse::enter", function()
            bg.bg = beautiful.lighter_bg
            icon_w.markup = helpers.colorize_text(icon, beautiful.xforeground)
        end)

        bg:connect_signal("mouse::leave", function()
            bg.bg = beautiful.dashboard_box_bg
            icon_w.markup = helpers.colorize_text(icon, color)
        end)

        bg:buttons(gears.table.join(
            awful.button({}, 1, function()
                if callback then callback() end
            end)
        ))

        return bg
    end

    local function section(title)
        local bar = wibox.widget{
            bg = beautiful.xcolor4,
            shape = helpers.rrect(dpi(2)),
            forced_width = dpi(3),
            forced_height = dpi(10),
            widget = wibox.container.background
        }
        local label = wibox.widget{
            markup = helpers.colorize_text(title, beautiful.xcolor8),
            font = beautiful.font_name .. "bold 8",
            valign = "center",
            widget = wibox.widget.textbox
        }
        return wibox.widget{
            bar,
            label,
            spacing = dpi(5),
            layout = wibox.layout.fixed.horizontal
        }
    end

    local function sep()
        return wibox.widget{
            forced_height = dpi(1),
            shape = helpers.rrect(dpi(1)),
            bg = beautiful.darker_bg,
            widget = wibox.container.background
        }
    end

    -- Buttons
    local blur_on = false
    local blur_btn = create_toggle_button("", "Blur", beautiful.xcolor4, function()
        blur_on = not blur_on
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/toggle-blur.sh")
    end)

    local volume_btn = create_toggle_button("", "Volume", beautiful.xcolor4, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/volumen")
    end)

    local night_mode_on = false
    local night_mode_btn = create_toggle_button("", "Night Mode", beautiful.xcolor5, function()
        night_mode_on = not night_mode_on
        if night_mode_on then
            awful.spawn.with_shell("redshift -O 3500")
            naughty.notify({text = "Modo noche activado", timeout = 1.5})
        else
            awful.spawn.with_shell("redshift -x")
            naughty.notify({text = "Modo noche desactivado", timeout = 1.5})
        end
    end)

    local powermenu_btn = create_toggle_button("⏻", "Power Menu", beautiful.xcolor1, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/powermenu.sh")
    end)

    local network_btn = create_toggle_button("", "Network", beautiful.xcolor2, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/network.sh")
    end)

    local bluetooth_btn = create_toggle_button("", "Bluetooth", beautiful.xcolor5, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/bluetooth.sh")
    end)

    local accent_btn = create_toggle_button("", "Cycle Accent", beautiful.xcolor5, function()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/cycle-accent.sh")
    end)

    local titlebar_btn = create_toggle_button("", "Titlebar", beautiful.xcolor6, function()
        hide()
        toggle_window_titlebars()
    end)

    local border_btn = create_toggle_button("", "Borders", beautiful.xcolor5, function()
        hide()
        toggle_window_borders()
    end)

    local sddm_btn = create_toggle_button("", "SDDM Wallpaper", beautiful.xcolor6, function()
        hide()
        awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/set-sddm-bg.sh")
    end)

    local wallpaper_btn = create_toggle_button("", "Wallpaper", beautiful.xcolor4, function()
        hide()
        awful.spawn.with_shell('file=$(yad --file --add-preview --file-filter="*.png *.jpg *.jpeg *.bmp *.webp" 2>/dev/null) && [ -n "$file" ] && echo "$file" > $HOME/.cache/wallpaper_fijo.txt && feh --bg-fill "$file"')
    end)

    local apps_btn = create_toggle_button("", "Apps", beautiful.xcolor2, function()
        hide()
        awful.spawn(launcher)
    end)

    local player_btn = create_toggle_button("", "Music", beautiful.xcolor5, function()
        hide()
        awful.spawn(music_client)
    end)

    local content = wibox.widget{
        {
            nil,
            {
                section("LAUNCH"),
                apps_btn,
                player_btn,
                sep(),
                section("CONNECT"),
                network_btn,
                bluetooth_btn,
                sep(),
                section("DISPLAY"),
                night_mode_btn,
                wallpaper_btn,
                blur_btn,
                sep(),
                section("AUDIO"),
                volume_btn,
                sep(),
                section("SYSTEM"),
                sddm_btn,
                accent_btn,
                titlebar_btn,
                border_btn,
                powermenu_btn,
                spacing = dpi(3),
                layout = wibox.layout.fixed.vertical
            },
            expand = "none",
            layout = wibox.layout.align.horizontal
        },
        margins = dpi(3),
        widget = wibox.container.margin
    }

    menu:setup {
        content,
        bg = "#0a141980",
        shape = helpers.rrect(beautiful.dashboard_radius),
        widget = wibox.container.background
    }

    return menu
end

_G.system_menu_toggle = function()
    local s = awful.screen.focused()
    if s and s.system_menu_toggle then
        s.system_menu_toggle()
    end
end

return create_system_menu
