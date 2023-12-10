--local utils = require("harpoon.test.utils")
local Logger = require("harpoon.logger")

local eq = assert.are.same

describe("harpoon", function()
    before_each(function()
        Logger:clear()
    end)

    it("new lines are removed.  every log call is one line", function()
        Logger:log("hello\nworld")
        eq(Logger.lines, { "hello world" })
    end)

    it("new lines with vim.inspect get removed too", function()
        Logger:log({ hello = "world", world = "hello" })
        eq({ '{ hello = "world", world = "hello" }' }, Logger.lines)
    end)

    it("max lines", function()
        Logger.max_lines = 1
        Logger:log("one")
        eq({ "one" }, Logger.lines)
        Logger:log("two")
        eq({ "two" }, Logger.lines)
    end)
end)
