require("tests.mock_awesome")

local helpers = require("helpers")

describe("helpers.client", function()
    local client_helpers = helpers.client

    it("single_double_tap is a function", function()
        assert.is_function(client_helpers.single_double_tap)
    end)

    it("maximize is a function", function()
        assert.is_function(client_helpers.maximize)
    end)

    it("resize_dwim is a function", function()
        assert.is_function(client_helpers.resize_dwim)
    end)

    it("move_to_edge is a function", function()
        assert.is_function(client_helpers.move_to_edge)
    end)

    it("move_client_dwim is a function", function()
        assert.is_function(client_helpers.move_client_dwim)
    end)

    it("float_and_edge_snap is a function", function()
        assert.is_function(client_helpers.float_and_edge_snap)
    end)

    it("float_and_resize is a function", function()
        assert.is_function(client_helpers.float_and_resize)
    end)

    it("centered_client_placement is a function", function()
        assert.is_function(client_helpers.centered_client_placement)
    end)

    it("run_or_raise is a function", function()
        assert.is_function(client_helpers.run_or_raise)
    end)

    it("send_key is a function", function()
        assert.is_function(client_helpers.send_key)
    end)

    it("send_key_sequence is a function", function()
        assert.is_function(client_helpers.send_key_sequence)
    end)

    it("tag_back_and_forth is a function", function()
        assert.is_function(client_helpers.tag_back_and_forth)
    end)

    it("client_menu_toggle returns a function", function()
        local fn = client_helpers.client_menu_toggle()
        assert.is_function(fn)
    end)

    it("rofi_move_client_here is a function", function()
        assert.is_function(client_helpers.rofi_move_client_here)
    end)

    it("add_hover_cursor is a function", function()
        assert.is_function(client_helpers.add_hover_cursor)
    end)
end)

describe("helpers.wibox", function()
    local wibox_helpers = helpers.wibox

    it("vertical_pad returns a widget", function()
        local w = wibox_helpers.vertical_pad(10)
        assert.is_table(w)
        assert.equal(w.forced_height, 10)
    end)

    it("horizontal_pad returns a widget", function()
        local w = wibox_helpers.horizontal_pad(10)
        assert.is_table(w)
        assert.equal(w.forced_width, 10)
    end)

    it("pad returns a textbox", function()
        local w = wibox_helpers.pad(5)
        assert.is_table(w)
    end)
end)

describe("helpers.system", function()
    local system = helpers.system

    it("volume_control is a function", function()
        assert.is_function(system.volume_control)
    end)

    it("notifications_volume is a function", function()
        assert.is_function(system.notifications_volume)
    end)

    it("music_control is a function", function()
        assert.is_function(system.music_control)
    end)

    it("fake_escape is a function", function()
        assert.is_function(system.fake_escape)
    end)

    it("remote_watch is a function", function()
        assert.is_function(system.remote_watch)
    end)
end)