local utils = require("harpoon.test.utils")
local logger = require("harpoon.logger")

---@type Harpoon
local harpoon = require("harpoon")

local Extensions = require("harpoon.extensions")
local Config = require("harpoon.config")
local Data = require("harpoon.data")
local List = require("harpoon.list")

local eq = assert.are.same
local config = Config.get_default_config()
local be = utils.before_each(os.tmpname())

local function expect_data(data)
    local read_data = Data.test.read_data(config)
    local testies = read_data.testies

    for k, v in pairs(data) do
        local list = List.decode(Config.get_config(config, k), k, testies[k])
        eq(v, list.items)
    end
end

---@param out {row: number, col: number}
---@param expected {row: number, col: number}
local function out_of_bounds_test(out, expected)
    local file_name = "/tmp/harpoon-test"
    local list = harpoon:list()
    local to_unload = utils.create_file(file_name, {
        "foo",
        "bar",
        "baz",
        "qux",
    })
    list:add()

    utils.create_file(file_name .. "2", {
        "foo",
        "bar",
        "baz",
        "qux",
    })

    vim.api.nvim_buf_delete(to_unload, { force = true })

    -- i have to force it to be out of bounds
    list.items[1].context = out

    harpoon:list():select(1)

    eq({
        { value = file_name, context = expected },
    }, harpoon:list().items)
end

describe("harpoon", function()
    before_each(function()
        be()
        logger:clear()
        harpoon = require("harpoon")
    end)

    it("when we change buffers we update the row and column", function()
        local file_name = "/tmp/harpoon-test"
        local row = 1
        local col = 0
        local target_buf = utils.create_file(file_name, {
            "foo",
            "bar",
            "baz",
            "qux",
        }, row, col)

        harpoon:setup()
        harpoon:list():add()
        local other_buf = utils.create_file("/tmp/other-file", {
            "foo",
            "bar",
            "baz",
            "qux",
        }, row, col)

        vim.api.nvim_set_current_buf(target_buf)
        vim.api.nvim_win_set_cursor(0, { row + 1, col })
        vim.api.nvim_set_current_buf(other_buf)

        expect_data({
            [Config.DEFAULT_LIST] = {
                {
                    context = {
                        col = 0,
                        row = 2,
                    },
                    value = "/tmp/harpoon-test",
                },
            },
        })
    end)

    it("full harpoon add sync cycle", function()
        local file_name = "/tmp/harpoon-test"
        local row = 3
        local col = 1
        local default_list_name = harpoon:info().default_list_name
        utils.create_file(file_name, {
            "foo",
            "bar",
            "baz",
            "qux",
        }, row, col)

        local list = harpoon:list()
        list:add()
        harpoon:sync()

        eq(harpoon:dump(), {
            testies = {
                [default_list_name] = list:encode(),
            },
        })
    end)

    it("out of bounds test: row over", function()
        out_of_bounds_test({
            row = 5,
            col = 3,
        }, {
            row = 4,
            col = 2,
        })
    end)

    it("out of bounds test: col over", function()
        out_of_bounds_test({
            row = 4,
            col = 4,
        }, {
            row = 4,
            col = 2,
        })
    end)

    it("out of bounds test: both over", function()
        out_of_bounds_test({
            row = 5,
            col = 4,
        }, {
            row = 4,
            col = 2,
        })
    end)

    it("prepend/add double add", function()
        local file_name_1 = "/tmp/harpoon-test"
        local row_1 = 3
        local col_1 = 1

        local file_name_2 = "/tmp/harpoon-test-2"
        local row_2 = 1
        local col_2 = 2

        local contents = { "foo", "bar", "baz", "qux" }

        local bufnr_1 = utils.create_file(file_name_1, contents, row_1, col_1)
        harpoon:list():add()

        expect_data({
            [Config.DEFAULT_LIST] = {
                { value = file_name_1, context = { row = row_1, col = col_1 } },
            },
        })

        utils.create_file(file_name_2, contents, row_2, col_2)
        harpoon:list():prepend()
        expect_data({
            [Config.DEFAULT_LIST] = {
                { value = file_name_2, context = { row = row_2, col = col_2 } },
                { value = file_name_1, context = { row = row_1, col = col_1 } },
            },
        })

        harpoon:list():add()
        expect_data({
            [Config.DEFAULT_LIST] = {
                { value = file_name_2, context = { row = row_2, col = col_2 } },
                { value = file_name_1, context = { row = row_1, col = col_1 } },
            },
        })

        vim.api.nvim_set_current_buf(bufnr_1)
        harpoon:list():prepend()
        expect_data({
            [Config.DEFAULT_LIST] = {
                { value = file_name_2, context = { row = row_2, col = col_2 } },
                { value = file_name_1, context = { row = row_1, col = col_1 } },
            },
        })
    end)

    it("extension testing: setup and create list", function()
        local list_created = false
        local list_name = ""
        local setup = false
        local ext_config = {}

        harpoon:extend({
            [Extensions.event_names.LIST_CREATED] = function(list)
                list_created = true
                list_name = list.name
            end,
            [Extensions.event_names.SETUP_CALLED] = function(c)
                setup = true
                ext_config = c
            end,
        })

        harpoon:setup({
            foo = {},
        })
        harpoon:list()

        eq(true, setup)
        eq({}, ext_config.foo)

        eq(true, list_created)
        eq(Config.DEFAULT_LIST, list_name)
    end)
end)
