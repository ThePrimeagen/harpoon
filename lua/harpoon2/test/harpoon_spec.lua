local Data = require("harpoon2.data")
local harpoon = require("harpoon2")

local eq = assert.are.same

describe("harpoon", function()

    before_each(function()
        Data.set_data_path("/tmp/harpoon2.json")
        Data.__dangerously_clear_data()
        require("plenary.reload").reload_module("harpoon2")
        Data = require("harpoon2.data")
        Data.set_data_path("/tmp/harpoon2.json")
        harpoon = require("harpoon2")
    end)

    it("full harpoon add sync cycle", function()
        local file_name = "/tmp/harpoon-test"
        local row = 3
        local col = 1
        local bufnr = vim.fn.bufnr(file_name, true)
        local default_key = harpoon:info().default_key
        vim.api.nvim_set_current_buf(bufnr)
        vim.api.nvim_buf_set_text(0, 0, 0, 0, 0, {
            "foo",
            "bar",
            "baz",
            "qux"
        })
        vim.api.nvim_win_set_cursor(0, {row, col})

        local list = harpoon:list():push()
        harpoon:sync()

        eq(harpoon:dump(), {
            [default_key] = list:encode()
        })
    end)
end)


