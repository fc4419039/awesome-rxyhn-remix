-- Standard Awesome Library
local awful = require("awful")
local hotkeys_popup = require("awful.hotkeys_popup")
local beautiful = require("beautiful")

-- Helpers
local helpers = require("helpers")

-- Create a launcher widget and a main menu
awful.screen.connect_for_each_screen(function(s)

    -- Submenu
    awesomemenu = {
        {"   Hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end},
        {"   Manual", terminal .. " -e man awesome"},
        {"   Edit Config", editor .. " " .. awesome.conffile},
        {"   Restart", awesome.restart},
        {"   Quit", function() awesome.quit() end}
    }

    -- Powermenu
    powermenu = {
        {"   Power OFF", function() awful.spawn.with_shell("systemctl poweroff") end},
        {"   Reboot", function() awful.spawn.with_shell("systemctl reboot") end},
        {"   Suspend", function()
            lock_screen_show()
            awful.spawn.with_shell("systemctl suspend")
        end},
        {"   Lock Screen", function() lock_screen_show() end}
    }

    -- Wallpaper submenu
    wallpapermenu = {
        {"   Fondo interactivo", function() awful.spawn.with_shell("rm -f $HOME/.cache/wallpaper_fijo.txt && " .. os.getenv("HOME") .. "/.config/cambiar_fondo.sh") end},
        {"   Elegir imagen", function() awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/set-wallpaper.sh") end},
        {"   Pantalla de bloqueo", function() awful.spawn.with_shell(os.getenv("HOME") .. "/.config/awesome/scripts/set-sddm-bg.sh") end}
    }

    -- Mainmenu
    mymainmenu = awful.menu({
        items = {
            {"   Terminal", function() awful.spawn.with_shell(terminal) end},
            {"   Code Editor", function() awful.spawn.with_shell(nvim) end},
            {"   File Manager", function() awful.spawn.with_shell(file_manager) end},
            {"   Web Browser", function() awful.spawn.with_shell(browser) end},
            {"   Music", function() awful.spawn.with_shell(music_client) end},
            {"   Fondos", wallpapermenu},
            {"AwesomeWM", awesomemenu,  beautiful.awesome_logo},
            {"   Power Menu", powermenu}
        }
    })

    mymainmenu.wibox.shape = helpers.rrect(beautiful.border_radius)

end)

