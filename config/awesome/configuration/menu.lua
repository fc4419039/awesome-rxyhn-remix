-- Standard Awesome Library
local awful = require("awful")
local hotkeys_popup = require("awful.hotkeys_popup")
local beautiful = require("beautiful")

-- Helpers
local helpers = require("helpers")

-- Lockscreen
local lock_screen = require("ui.lockscreen")

-- Create a launcher widget and a main menu
awful.screen.connect_for_each_screen(function(s)

    -- Submenu
    awesomemenu = {
        {"   " .. i18n.tr("menu.hotkeys"), function() hotkeys_popup.show_help(nil, awful.screen.focused()) end},
        {"   " .. i18n.tr("menu.manual"), terminal .. " -e man awesome"},
        {"   " .. i18n.tr("menu.edit_config"), editor .. " " .. awesome.conffile},
        {"   " .. i18n.tr("menu.restart"), function() require("ui.reload").restart() end},
        {"   " .. i18n.tr("menu.quit"), function() awesome.quit() end}
    }

    -- Powermenu
    powermenu = {
        {"   " .. i18n.tr("pm.power"), function() awful.spawn.with_shell("systemctl poweroff") end},
        {"   " .. i18n.tr("pm.reboot"), function() awful.spawn.with_shell("systemctl reboot") end},
        {"   " .. i18n.tr("pm.suspend"), function()
            lock_screen.show()
            awful.spawn.with_shell("systemctl suspend")
        end},
        {"   " .. i18n.tr("menu.lock_screen"), function() lock_screen.show() end}
    }

    -- Wallpaper submenu
    wallpapermenu = {
        {"  " .. i18n.tr("menu.wallpaper"), function() require("ui.system_menu.wallpaper_picker").toggle() end},
        {"  " .. i18n.tr("menu.sddm_bg"), function() require("ui.system_menu.sddm_picker").toggle() end}
    }

    -- Mainmenu
    mymainmenu = awful.menu({
        items = {
            {"   " .. i18n.tr("menu.terminal"), function() awful.spawn.with_shell(terminal) end},
            {"   " .. i18n.tr("menu.code_editor"), function() awful.spawn.with_shell(nvim) end},
            {"   " .. i18n.tr("menu.file_manager"), function() awful.spawn.with_shell(file_manager) end},
            {"   " .. i18n.tr("menu.web_browser"), function() awful.spawn.with_shell(browser) end},
            {"   " .. i18n.tr("menu.music"), function() awful.spawn.with_shell(music_client) end},
            {"   " .. i18n.tr("menu.wallpapers"), wallpapermenu},
            {"AwesomeWM", awesomemenu, beautiful.awesome_logo},
            {"   " .. i18n.tr("menu.power_menu"), powermenu}
        }
    })

    mymainmenu.wibox.shape = helpers.rrect(beautiful.border_radius)

end)
