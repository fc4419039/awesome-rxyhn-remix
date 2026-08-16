require("tests.mock_awesome")

local helpers = require("helpers")

describe("helpers.shape", function()
    local shape = helpers.shape

    it("rrect returns a function", function()
        local fn = shape.rrect(10)
        assert.is_function(fn)
    end)

    it("pie returns a function", function()
        local fn = shape.pie(100, 100, 0, math.pi, 10)
        assert.is_function(fn)
    end)

    it("prgram returns a function", function()
        local fn = shape.prgram(20, 10)
        assert.is_function(fn)
    end)

    it("prrect returns a function", function()
        local fn = shape.prrect(10, true, false, true, false)
        assert.is_function(fn)
    end)

    it("rbar returns a function", function()
        local fn = shape.rbar(100, 20)
        assert.is_function(fn)
    end)

    it("custom_shape is a function", function()
        assert.is_function(shape.custom)
    end)
end)

describe("helpers.string", function()
    local str = helpers.string

    it("case_insensitive_pattern converts letters", function()
        local pattern = str.case_insensitive_pattern("test")
        assert.matches(pattern, "TEST")
        assert.matches(pattern, "Test")
        assert.matches(pattern, "test")
    end)

    it("contains finds existing values", function()
        assert.is_true(str.contains({1, 2, 3}, 2))
        assert.is_false(str.contains({1, 2, 3}, 4))
    end)

    it("pango_escape escapes special chars", function()
        local escaped = str.pango_escape("a<b&c>")
        assert.matches(escaped, "a<b&c>")
    end)

    it("upper_no_accents removes accents", function()
        local result = str.upper_no_accents("áéíóú")
        assert.equal(result, "AEIOU")
    end)
end)

describe("helpers.markup", function()
    local markup = helpers.markup

    it("colorize_text wraps text in span", function()
        local result = markup.colorize_text("hello", "#ff0000")
        assert.equal(result, "<span foreground='#ff0000'>hello</span>")
    end)

    it("colorize_text handles nil", function()
        local result = markup.colorize_text(nil, "#ff0000")
        assert.equal(result, "<span foreground='#ff0000'></span>")
    end)
end)

describe("helpers.misc", function()
    local misc = helpers.misc

    it("round works with different decimals", function()
        assert.equal(misc.round(1.2345, 2), 1.23)
        assert.equal(misc.round(1.2345, 0), 1)
        local r = misc.round(1.567, 2)
        assert.is_true(r >= 1.56 and r <= 1.58)
    end)
end)