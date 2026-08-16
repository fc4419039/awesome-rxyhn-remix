local markup = {}

function markup.colorize_text(txt, fg)
    return "<span foreground='" .. fg .. "'>" .. (txt or "") .. "</span>"
end

return markup