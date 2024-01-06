local Config = require("harpoon.config")
local eq = assert.are.same

describe("config", function()
    describe("default.create_list_item", function()
        it("sets position", function()
            local config = Config.get_default_config()
            local config_item = Config.get_config(config, "foo")

            local filename = os.tmpname()
            local bufnr = vim.fn.bufnr(filename, true)

            vim.api.nvim_set_current_buf(bufnr)
            vim.api.nvim_buf_set_text(0, 0, 0, 0, 0, {
                "foo",
                "bar",
                "baz",
                "qux",
            })
            vim.api.nvim_win_set_cursor(0, { 3, 1 })

            local item = config_item.create_list_item(config_item)
            eq(item, {
                value = filename,
                context = {
                    row = 3,
                    col = 1,
                },
            })
        end)
        it("normalizes filename with /./ in it", function()
            local config = Config.get_default_config()
            local config_item = Config.get_config(config, "foo")

            local filename = "/foo/./bar/./baz.txt"

            local item = config_item.create_list_item(config_item, filename)
            eq("/foo/bar/baz.txt", item.value)
        end)
        it("normalizes filename with bar/../bar/ in it", function()
            local config = Config.get_default_config()
            local config_item = Config.get_config(config, "foo")

            local filename = "/foo/bar/../bar/baz.txt"

            local item = config_item.create_list_item(config_item, filename)
            eq("/foo/bar/baz.txt", item.value)
        end)
        it("converts backtracking relative path to absolute", function()
            local config = Config.get_default_config()
            local config_item = Config.get_config(config, "foo")

            local filename = "../foo/bar/baz.txt"

            local item = config_item.create_list_item(config_item, filename)
            eq("/foo/bar/baz.txt", item.value)
        end)
        it("converts forward relative path to absolute", function()
            local config = Config.get_default_config()
            local config_item = Config.get_config(config, "foo")

            local filename = "foo/bar/baz.txt"

            local item = config_item.create_list_item(config_item, filename)
            eq(vim.loop.cwd() .. "/foo/bar/baz.txt", item.value)
        end)
    end)
end)
