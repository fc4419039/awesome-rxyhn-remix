-- i18n/init.lua — diccionario de idiomas para la UI de awesome.
-- Carga i18n/strings.tsv y expone:
--   i18n.tr(clave, fallback)      -> traduce (fallback: la propia clave)
--   i18n.format(clave, ...)       -> traduce y formatea con string.format
--   i18n.lang                     -> código del idioma activo (es/en/pt/fr/...)
-- Requerir antes que cualquier módulo de UI:
--   local i18n = require("i18n")

local i18n = {}

local COL = {
    es = 2, en = 3, pt = 4, fr = 5, de = 6,
    it = 7, ja = 8, ko = 9, zh = 10, ru = 11, ar = 12,
}

local function detect()
    local lang = os.getenv("LANG") or ""
    local f = io.open("/etc/locale.conf", "r")
    if f then
        for line in f:lines() do
            local v = line:match("^LANG=%s*([^\n]+)")
            if v then
                v = v:gsub('^"', ""):gsub('"$', "")
                v = v:gsub("^'", ""):gsub("'$", "")
                lang = v
                break
            end
        end
        f:close()
    end
    local code = lang:match("^%s*(%a%a)")
    return code and code:lower() or "en"
end

i18n.lang = detect()

local dict = {}

local function load()
    local base = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
    local f = io.open(base .. "/awesome/i18n/strings.tsv", "r")
    if not f then
        return false
    end
    f:read("*l")
    for line in f:lines() do
        if line ~= "" and not line:match("^#") then
            local vals = {}
            for tok in line:gmatch("[^\t]+") do
                vals[#vals + 1] = tok
            end
            local v = vals[COL[i18n.lang]] or vals[3]
            if v then
                dict[vals[1]] = v:gsub("\\n", "\n")
            end
        end
    end
    f:close()
    return true
end

load()

function i18n.tr(key, fallback)
    local v = dict[key]
    if v == nil or v == "" then
        return fallback or key
    end
    return v
end

function i18n.format(key, ...)
    return string.format(i18n.tr(key), ...)
end

return i18n
