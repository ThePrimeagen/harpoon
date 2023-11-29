local List = require("harpoon2.list")
local Config = require("harpoon2.config")
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
end)
