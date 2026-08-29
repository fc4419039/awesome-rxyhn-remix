local string_helpers = {}

function string_helpers.case_insensitive_pattern(s)
    return s:gsub("%a", function(c) return "[" .. c:lower() .. c:upper() .. "]" end)
end

function string_helpers.contains(tbl, val)
    for _, v in ipairs(tbl) do
        if val == v then return true end
    end
    return false
end

function string_helpers.pango_escape(s)
    return (string.gsub(s, "[&<>]",
        {["&"] = "&", ["<"] = "<", [">"] = ">"}))
end

-- Devuelve el codepoint UTF-8 en la posicion i y el siguiente indice.
-- No depende de la libreria `utf8` (solo existe en Lua 5.3+), asi que
-- funciona en Lua 5.1/5.2/5.3/5.4 y LuaJIT.
function string_helpers.utf8_next(s, i)
    local b1 = s:byte(i)
    if not b1 then return nil end
    if b1 < 0x80 then
        return b1, i + 1
    elseif b1 < 0xE0 then
        return (b1 - 0xC0) * 64 + (s:byte(i + 1) - 0x80), i + 2
    elseif b1 < 0xF0 then
        return ((b1 - 0xE0) * 64 + (s:byte(i + 1) - 0x80)) * 64 + (s:byte(i + 2) - 0x80), i + 3
    else
        return (((b1 - 0xF0) * 64 + (s:byte(i + 1) - 0x80)) * 64 + (s:byte(i + 2) - 0x80)) * 64 + (s:byte(i + 3) - 0x80), i + 4
    end
end

function string_helpers.upper_no_accents(str)
    local map = {
        [0xC1] = "A", [0xC9] = "E", [0xCD] = "I", [0xD3] = "O", [0xDA] = "U",
        [0xC0] = "A", [0xC8] = "E", [0xCC] = "I", [0xD2] = "O", [0xD9] = "U",
        [0xC2] = "A", [0xCA] = "E", [0xCE] = "I", [0xD4] = "O", [0xDB] = "U",
        [0xC3] = "A", [0xD5] = "O", [0xC7] = "C", [0xD1] = "N",
        [0xE1] = "A", [0xE9] = "E", [0xED] = "I", [0xF3] = "O", [0xFA] = "U",
        [0xE0] = "A", [0xE8] = "E", [0xEC] = "I", [0xF2] = "O", [0xF9] = "U",
        [0xE2] = "A", [0xEA] = "E", [0xEE] = "I", [0xF4] = "O", [0xFB] = "U",
        [0xE3] = "A", [0xF5] = "O", [0xE7] = "C", [0xF1] = "N",
    }
    local chars = {}
    local i, n = 1, #str
    while i <= n do
        local cp, next_i = string_helpers.utf8_next(str, i)
        chars[#chars + 1] = map[cp] or str:sub(i, next_i - 1)
        i = next_i
    end
    return string.upper(table.concat(chars))
end

return string_helpers