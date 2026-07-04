local naughty = require("naughty")
local bling = require("module.bling")

local ok, playerctl_lib = pcall(bling.signal.playerctl.lib)
local playerctl = ok and playerctl_lib or { connect_signal = function() end }

if ok then
    playerctl:connect_signal("metadata", function(_, title, artist, album_path, album, new, player_name)
        if new == true and title and title ~= "" and player_name ~= "firefox" then
            naughty.notify ({
                app_name = 'Music',
                title = title,
                text = artist,
                image = (album_path and album_path ~= "") and album_path or nil,
            })
        end
    end)
end

return playerctl
