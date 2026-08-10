-- Standard awesome library
local gears = require("gears")
local awful = require("awful")

-- Theme handling library
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

-- Widget library
local wibox = require("wibox")

-- Helpers
local helpers = require("helpers")

-- Lock
local lock_screen = require("ui.lockscreen")


-- Lock Screen
----------------

local lock_screen_box = wibox({visible = false, ontop = true, type = "splash", screen = screen.primary})
awful.placement.maximize(lock_screen_box)
-- lock_screen_box.bg = beautiful.transparent
lock_screen_box.bg = "#0a141922"

-- Add lockscreen to each screen
awful.screen.connect_for_each_screen(function(s)
    if s == screen.primary then
        s.mylockscreen = lock_screen_box
    else
        s.mylockscreen = helpers.screen_mask(s, beautiful.lock_screen_bg or beautiful.exit_screen_bg or beautiful.xbackground)
    end
end)

-- Vars
local char = "I T L I S A S A M P M A C Q U A R T E R D C T W E N T Y F I V E X H A L F S T E N F T O P A S T E R U N I N E O N E S I X T H R E E F O U R F I V E T W O E I G H T E L E V E N S E V E N T W E L V E T E N S E O C L O C K"

local pos_map = {
    ["it"] = {1, 2},
    ["is"] = {4, 5},
    ["a"] = {12, 12},
    ["quarter"] = {14, 20},
    ["twenty"] = {23,28},
    ["five"] = {29, 32},
    ["half"] = {34, 37},
    ["ten"] = {39, 41},
    ["past"] = {45, 48},
    ["to"] = {43, 44},
    ["1"] = {56, 58},
    ["2"] = {75, 77},
    ["3"] = {62, 66},
    ["4"] = {67, 70},
    ["5"] = {71, 74},
    ["6"] = {59, 61},
    ["7"] = {89, 93},
    ["8"] = {78, 82},
    ["9"] = {52, 55},
    ["10"] = {100, 102},
    ["11"] = {83, 88},
    ["12"] = {94, 99},
    ["oclock"] = {105, 110}
}

local char_map = {
    ["it"] = {},
    ["is"] = {},
    ["a"] = {},
    ["quarter"] = {},
    ["twenty"] = {},
    ["five"] = {},
    ["half"] = {},
    ["ten"] = {},
    ["past"] = {},
    ["to"] = {},
    ["1"] = {},
    ["2"] = {},
    ["3"] = {},
    ["4"] = {},
    ["5"] = {},
    ["6"] = {},
    ["7"] = {},
    ["8"] = {},
    ["9"] = {},
    ["10"] = {},
    ["11"] = {},
    ["12"] = {},
    ["oclock"] = {}
}

local reset_map = {4, 12, 14, 23, 29, 34, 39, 43, 45, 52, 56, 59, 62, 67, 71, 75, 78, 83, 89, 94, 100, 105}

local function split_str(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end

    return result;
end

local time_char = split_str(char, " ")

-- Helpers

local time = wibox.widget{
    forced_num_cols = 11,
    spacing = beautiful.useless_gap,
    layout = wibox.layout.grid
}

local function create_text_widget(index, w)
    local text_widget = wibox.widget{
        id = "t"..index,
        markup = w,
        font = beautiful.font_name .. "bold 18",
        align = "center",
        valign = "center",
        forced_width = dpi(25),
        forced_height = dpi(30),
        widget = wibox.widget.textbox
    }

    time:add(text_widget)

    return text_widget
end

local var_count = 0
for i, m in pairs(time_char) do
    -- local text = helpers.colorize_text(m, "#162026")
    local text = helpers.colorize_text(m, beautiful.lighter_bg:sub(1, 7) .. "55")

    var_count = var_count + 1
    local create_dummy_text = true

    for j, k in pairs(pos_map) do
        if i >= pos_map[j][1] and i <= pos_map[j][2] then
            char_map[j][var_count] = create_text_widget(i, text)
            create_dummy_text = false
        end

        for _, n in pairs(reset_map) do
            if i == n then
                var_count = 1
            end
        end

    end

    if create_dummy_text then
        create_text_widget(i, text)
    end

end

local function activate_word(w)
    for i, m in pairs(char_map[w]) do
        local text = m.text

        m.markup = helpers.colorize_text(text, beautiful.xforeground)

    end
end

local function deactivate_word(w)
    for i, m in pairs(char_map[w]) do
        local text = m.text

        m.markup = helpers.colorize_text(text, beautiful.lighter_bg:sub(1, 7) .. "55")

    end
end

local function reset_time()

    for j, k in pairs(char_map) do
        deactivate_word(j)
    end

    activate_word("it")
    activate_word("is")

end

local word_clock_timer = gears.timer {
    timeout   = 5,
    call_now  = true,
    autostart = false,
    callback  = function()
        local time = os.date('%I' .. ':%M')
        local h,m = time:match('(%d+):(%d+)')
        local min = tonumber(m)
        local hour = tonumber(h)

        reset_time()

        if min >= 0 and min <= 2 or min >= 58 and min <= 59 then
            activate_word("oclock")
        elseif min >= 3 and min <= 7 or min >= 53 and min <= 57 then
            activate_word("five")
        elseif min >= 8 and min <= 12 or min >= 48 and min <= 52 then
            activate_word("ten")
        elseif min >= 13 and min <= 17 or min >= 43 and min <= 47 then
            activate_word("a")
            activate_word("quarter")
        elseif min >= 18 and min <= 22 or min >= 38 and min <= 42 then
            activate_word("twenty")
        elseif min >= 23 and min <= 27 or min >= 33 and min <= 37 then
            activate_word("twenty")
            activate_word("five")
        elseif min >= 28 and min <= 32 then
            activate_word("half")
        end

        if min >= 3 and min <= 32 then
            activate_word("past")
        elseif min >= 33 and min <= 57 then
            activate_word("to")
        end

        local hh

        if min >= 0 and min <= 30 then
            hh = hour
        else
            hh = hour + 1
        end

        if hh > 12 then
            hh = hh - 12
        end

        activate_word(tostring(hh))
    end
}

-- Lock animation
local lock_screen_symbol = ""
local lock_screen_fail_symbol = ""
local lock_animation_icon = wibox.widget {
    -- Set forced size to prevent flickering when the icon rotates
    forced_height = dpi(80),
    forced_width = dpi(80),
    font = beautiful.icon_font_name .. "Outlined 24",
    align = "center",
    valign = "center",
    widget = wibox.widget.textbox(lock_screen_symbol)
}

local lock_animation_widget_rotate = wibox.container.rotate()

local arc = function()
    return function(cr, width, height)
        gears.shape.arc(cr, width, height, dpi(5), 0, math.pi/3, true, true)
    end
end

local lock_animation_arc = wibox.widget {
    shape = arc(),
    bg = "#00000000",
    forced_width = dpi(50),
    forced_height = dpi(50),
    widget = wibox.container.background
}

local lock_animation = {
    {
        lock_animation_arc,
        widget = lock_animation_widget_rotate
    },
    lock_animation_icon,
    layout = wibox.layout.stack
}

-- Lock helper functions
local characters_entered = 0
local function reset()
    characters_entered = 0;
    lock_animation_icon.markup = helpers.colorize_text(lock_screen_symbol, beautiful.xcolor7)
    lock_animation_widget_rotate.direction = "north"
    lock_animation_arc.bg = "#00000000"
end

local function fail()
    characters_entered = 0;
    lock_animation_icon.text = lock_screen_fail_symbol
    lock_animation_widget_rotate.direction = "north"
    lock_animation_arc.bg = "#00000000"
end

local animation_colors = {
    -- Rainbow sequence =)
    beautiful.xcolor1,
    beautiful.xcolor5,
    beautiful.xcolor4,
    beautiful.xcolor6,
    beautiful.xcolor2,
    beautiful.xcolor3,
}

local animation_directions = {"north", "west", "south", "east"}

-- Function that "animates" every key press
local function key_animation(char_inserted)
    local color
    local direction = animation_directions[(characters_entered % 4) + 1]
    if char_inserted then
        color = animation_colors[(characters_entered % 6) + 1]
        lock_animation_icon.text = lock_screen_symbol
    else
        if characters_entered == 0 then
            reset()
        else
            color = beautiful.xcolor7 .. "55"
        end
    end

    lock_animation_arc.bg = color
    lock_animation_widget_rotate.direction = direction
end

-- Guardar/restaurar atajos globales de Awesome mientras está bloqueado.
-- Esto evita que combos como Ctrl+C, Ctrl+Super+R, Super, etc. se ejecuten
-- durante el bloqueo: solo se aceptan caracteres de contraseña.
local saved_root_keys

local function clear_global_keys()
    saved_root_keys = root.keys()
    root.keys({})
end

local function restore_global_keys()
    if saved_root_keys then
        root.keys(saved_root_keys)
        saved_root_keys = nil
    end
end

local function set_visibility(v)
    for s in screen do
        s.mylockscreen.visible = v
    end
    if v then
        clear_global_keys()
        word_clock_timer:start()
    else
        restore_global_keys()
        word_clock_timer:stop()
    end
end

    -- Keygrabber estricto: mientras el lockscreen está activo, SOLO se aceptan
    -- caracteres de la contraseña (sin modificadores). Cualquier otro atajo
    -- (Super, Ctrl+C, Ctrl+Super+R, Escape, F-keys, combos, ...) se consume e
    -- ignora, de modo que no puede desbloquear ni disparar acciones.
    --
    -- IMPORTANTE: los eventos de *release* deben retornar false para que pasen
    -- al procesamiento normal de Awesome y actualizar el estado interno de
    -- modificadoras. Si se retorna true (consumir), las modificadoras quedan
    -- "atascadas" tras desbloquear: al bloquear con Super+L el modificador Super
    -- (Mod4) queda presionado; si su release se consume, Awesome nunca lo
    -- libera y los atajos de teclado (Ctrl, Super, etc.) dejan de funcionar.
    -- No se re-inicia grab_password() en release (la versión .codebak lo hacía)
    -- porque eso reiniciaba el buffer de la contraseña en cada liberación,
    -- bloqueando contraseñas de más de un carácter.
    local function grab_password()
        local password_buffer = ""
        awful.keygrabber.run(function(mod, key, event)
        if event == "release" then
            return false
        end
        if event ~= "press" then
            return true
        end

        -- Enter: autenticar
        if key == "Return" or key == "KP_Enter" then
            local ok = lock_screen.authenticate(password_buffer)
            if ok then
                -- YAY
                reset()
                set_visibility(false)
                awful.keygrabber.stop()
                -- Forzar liberación de modificadores (Hack preventivo)
                for _, mod in ipairs({"Control", "Mod1", "Mod4", "Mod5"}) do
                    root.fake_input("key_release", mod)
                end
                if lock_screen_on_unlock then lock_screen_on_unlock() end
                return false
             else
                -- NAY: contraseña incorrecta. Mostrar animación de error y
                -- permitir reintentar en el mismo lockscreen. El fail-secure
                -- con i3lock/slock se reserva para el caso de crasheo de
                -- awesome (manejado por el watchdog) o PAM no disponible.
                password_buffer = ""
                fail()
                return true
            end
        end

        -- BackSpace: borrar el último carácter
        if key == "BackSpace" then
            if #password_buffer > 0 then
                password_buffer = password_buffer:sub(1, -2)
                characters_entered = characters_entered - 1
                if characters_entered < 0 then characters_entered = 0 end
            end
            key_animation(false)
            return true
        end

        -- Escape: limpiar el buffer visual sin bloquear (no desbloquea)
        if key == "Escape" then
            password_buffer = ""
            characters_entered = 0
            reset()
            return true
        end

        -- Carácter de contraseña: tecla de un carácter (o espacio), sin
        -- modificadores salvo Shift (para mayúsculas/símbolos).
        local is_char = #key == 1 or key == "space"
        local blocked = mod.Control or mod.Mod1 or mod.Mod2 or mod.Mod3
            or mod.Mod4 or mod.Mod5 or mod.AltGr or mod.Lock
        if is_char and not blocked then
            password_buffer = password_buffer .. key
            characters_entered = characters_entered + 1
            key_animation(true)
            return true
        end

        -- Cualquier otra tecla/combo: ignorarla por completo. NO ejecuta atajos.
        return true
    end)
end

function lock_screen_show()
    set_visibility(true)
    grab_password()
end

lock_screen_box:setup {
    -- Horizontal centering
    nil,
    {
        -- Vertical centering
        nil,
        {
            {
                {
                    helpers.vertical_pad(dpi(10)),
                    time,
                    lock_animation,
                    spacing = dpi(20),
                    layout = wibox.layout.fixed.vertical
                },
                bottom = dpi(30),
                right = dpi(60),
                left = dpi(60),
                widget = wibox.container.margin
            },
            shape = helpers.rrect(beautiful.border_radius),
            bg = "00000000",
            widget = wibox.container.background
        },
        expand = "none",
        layout = wibox.layout.align.vertical
    },
    expand = "none",
    layout = wibox.layout.align.horizontal
}
