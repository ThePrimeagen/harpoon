local Config = require("harpoon.config")
local eq = assert.are.same

describe("config", function()
    it("default.create_list_item", function()
        local config = Config.get_default_config()
        local config_item = Config.get_config(config, "foo")

        local bufnr = vim.fn.bufnr("/tmp/harpoon-test", true)

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
            value = "/tmp/harpoon-test",
            context = {
                row = 3,
                col = 1,
            },
        })
    end)
end)
