local naughty = require("naughty")
local bling = require("module.bling")

-- El backend lib de bling no gestiona los players de Chromium/Opera GX
-- (instancias tipo "chromium.instanceXXXX") de forma fiable. Usamos el
-- backend CLI con la misma lista de players que el resto de widgets.
local ok, playerctl = pcall(bling.signal.playerctl.cli, { player = {"firefox", "spotify", "%any"} })
playerctl = ok and playerctl or { connect_signal = function() end }

if ok then
    -- Navegadores (Chromium/Opera/etc.) exponen MPRIS por cada video que
    -- reproduce o se previsualiza en hover; eso generaria spam de "now playing".
    local browser_players = {"^chromium", "^chrome", "^opera", "^edge", "^brave", "^vivaldi", "^firefox"}
    local last_title, last_artist = "", ""
    playerctl:connect_signal("metadata", function(_, title, artist, album_path, album, player_name)
        local is_browser = false
        for _, pat in ipairs(browser_players) do
            if player_name and player_name:match(pat) then
                is_browser = true
                break
            end
        end
        if title and title ~= "" and not is_browser
           and (title ~= last_title or artist ~= last_artist) then
            last_title, last_artist = title, artist
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
