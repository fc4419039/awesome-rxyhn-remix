local markup = {}

function markup.colorize_text(txt, fg)
    if not fg then
        return txt or ""
    end
    return "<span foreground='" .. fg .. "'>" .. (txt or "") .. "</span>"
end

return markup