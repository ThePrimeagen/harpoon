local utils = require("harpoon2.test.utils")
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
        local default_key = harpoon:info().default_key
        local bufnr = utils.create_file(file_name, {
            "foo",
            "bar",
            "baz",
            "qux"
        }, row, col)

        local list = harpoon:list():append()
        harpoon:sync()

        eq(harpoon:dump(), {
            [default_key] = list:encode()
        })
    end)

    it("prepend/append double add", function()
        local default_key = harpoon:info().default_key
        local file_name_1 = "/tmp/harpoon-test"
        local row_1 = 3
        local col_1 = 1

        local file_name_2 = "/tmp/harpoon-test-2"
        local row_2 = 1
        local col_2 = 2

        local contents = { "foo", "bar", "baz", "qux" }

        local bufnr_1 = utils.create_file(file_name_1, contents, row_1, col_1)
        local list = harpoon:list():append()

        utils.create_file(file_name_2, contents, row_2, col_2)
        harpoon:list():prepend()

        harpoon:sync()

        eq(harpoon:dump(), {
            [default_key] = list:encode()
        })

        eq(list.items, {
            {value = file_name_2, context = {row = row_2, col = col_2}},
            {value = file_name_1, context = {row = row_1, col = col_1}},
        })

        harpoon:list():append()
        vim.api.nvim_set_current_buf(bufnr_1)
        harpoon:list():prepend()

        eq(list.items, {
            {value = file_name_2, context = {row = row_2, col = col_2}},
            {value = file_name_1, context = {row = row_1, col = col_1}},
        })

    end)
end)


