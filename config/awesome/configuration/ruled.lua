-- Standard awesome library
local awful = require("awful")

-- Theme handling library
local beautiful = require("beautiful")

-- Notification handling library
local naughty = require("naughty")

-- Timer handling library
local gears = require("gears")

-- Ruled
local ruled = require("ruled")

-- Helpers
local helpers = require("helpers")

ruled.client.connect_signal("request::rules", function()

    -- Global
    ruled.client.append_rule {
        id = "global",
        rule = {},
        properties = {
            focus = awful.client.focus.filter,
            raise = true,
            size_hints_honor = false,
            floating = false,
            maximized = false,
            screen = awful.screen.preferred,
            titlebars_enabled = beautiful.titlebar_enabled,
            placement = awful.placement.no_overlap+awful.placement.no_offscreen
        },
        callback = function(c)
            -- Evitar que las apps abran maximizadas al iniciar
            -- (muchas restauran su estado guardado).
            if c.maximized then
                c.maximized = false
            end
            local mx_guard
            mx_guard = function()
                if c.valid then c.maximized = false end
            end
            c:connect_signal("property::maximized", mx_guard)
            gears.timer.start_new(3, function()
                if c.valid then
                    pcall(c.disconnect_signal, c, "property::maximized", mx_guard)
                end
                return false
            end)
        end
    }

    -- Tasklist order
    ruled.client.append_rule {
        id = "tasklist_order",
        rule = {},
        properties = {},
        callback = awful.client.setslave
    }

    -- Firefox: ignorar size_hints para que respete el tiling al cambiar workarea
    ruled.client.append_rule {
        rule = { class = "firefox" },
        properties = { honor_size_hints = false }
    }

    -- Float
    ruled.client.append_rule {
        id = "floating",
        rule_any = {
            instance = {
                "Devtools", -- Firefox devtools
            },
            class = {
                "Lxappearance",
                "Nm-connection-editor",
            },
            name = {
                "Event Tester",  -- xev
            },
            role = {
                "AlarmWindow",
                "pop-up",
                "GtkFileChooserDialog",
                "conversation",
            },
            type = {
                "dialog",
            }
        },
        properties = { floating = true, placement = helpers.centered_client_placement }
    }

    -- Centered
    ruled.client.append_rule {
        id = "centered",
        rule_any = {
            type = {
                "dialog",
            },
            class = {
                -- "discord",
            },
            role = {
                "GtkFileChooserDialog",
                "conversation",
            }
        },
        properties = { placement = helpers.centered_client_placement },
    }

    -- Music clients (usually a terminal running ncmpcpp)
    ruled.client.append_rule {
        rule_any = {
            class = {
                "music"
            },
            instance = {
                "music"
            }
        },
        properties = {
            floating = true,
            placement = helpers.centered_client_placement
        },
        callback = function(c)
            local g = c.screen.geometry
            c.width = g.width * 0.25
            c.height = g.height * 0.4
        end
    }

    -- Image viewers
    ruled.client.append_rule {
        rule_any = {
            class = {
                "feh",
                "imv"
            }
        },
        properties = {
            floating = true
        },
        callback = function (c)
            local g = c.screen.geometry
            c.width = g.width * 0.7
            c.height = g.height * 0.75
            awful.placement.centered(c,{honor_padding = true, honor_workarea=true})
        end
    }

    -- Mpv
    ruled.client.append_rule {
        rule = { class = "mpv" },
        properties = {},
        callback = function (c)
            -- make it floating, ontop and move it out of the way if the current tag is maximized
            local g = c.screen.geometry
            if awful.layout.get(c.screen) == awful.layout.suit.floating then
                c.floating = true
                c.ontop = true
                c.width = g.width * 0.30
                c.height = g.height * 0.35
                awful.placement.bottom_right(c, {
                    honor_padding = true,
                    honor_workarea = true,
                    margins = { bottom = beautiful.useless_gap * 2, right = beautiful.useless_gap * 2 }
                })
                awful.titlebar.hide(c, beautiful.titlebar_pos)
            end

            -- restore `ontop` after fullscreen is disabled
            c:connect_signal("property::fullscreen", function ()
                if not c.fullscreen then
                    c.ontop = true
                end
            end)
        end
    }
end)

