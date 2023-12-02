local List = require("harpoon.list")
local Config = require("harpoon.config")
local eq = assert.are.same

describe("list", function()
    it("decode", function()
        local config = Config.merge_config({
            foo = {
                decode = function(item)
                    -- split item on :
                    local parts = vim.split(item, ":")
                    return {
                        value = parts,
                        context = nil,
                    }
                end,

                display = function(item)
                    return table.concat(item.value, "---")
                end,
            },
        })
        local list_config = Config.get_config(config, "foo")

        local list = List.decode(list_config, "foo", { "foo:bar", "baz:qux" })
        local displayed = list:display()

        eq(displayed, {
            "foo---bar",
            "baz---qux",
        })
    end)

    it("select_with_nil", function()
        local foo_selected = nil
        local bar_selected = nil

        local config = Config.merge_config({
            foo = {
                select_with_nil = true,
                select = function(list_item, options)
                    foo_selected = { list_item, options }
                end,
            },
            bar = {
                select = function(list_item, options)
                    bar_selected = { list_item, options }
                end,
            },
        })
        local fooc = Config.get_config(config, "foo")
        local barc = Config.get_config(config, "bar")

        local foo = List.decode(fooc, "foo", {})
        local bar = List.decode(fooc, "bar", {})

        foo:select(4, {})
        bar:select(4, {})

        eq({ nil, {} }, foo_selected)
        eq(nil, bar_selected)
    end)
end)
