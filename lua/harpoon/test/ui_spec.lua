local utils = require("harpoon.test.utils")
local Buffer = require("harpoon.buffer")
local harpoon = require("harpoon")

local eq = assert.are.same
local be = utils.before_each(os.tmpname())

describe("harpoon", function()
    before_each(function()
        be()
        harpoon = require("harpoon")
    end)

    it("open the ui without any items in the list", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())

        local bufnr = harpoon.ui.bufnr
        local win_id = harpoon.ui.win_id

        eq(vim.api.nvim_buf_is_valid(bufnr), true)
        eq(vim.api.nvim_win_is_valid(win_id), true)

        harpoon.ui:toggle_quick_menu()

        eq(vim.api.nvim_buf_is_valid(bufnr), false)
        eq(vim.api.nvim_win_is_valid(win_id), false)
        eq(harpoon.ui.bufnr, nil)
        eq(harpoon.ui.win_id, nil)
    end)

    it("delete file from ui contents and save", function()
        local created_files = utils.fill_list_with_files(3, harpoon:list())
        eq(harpoon:list():length(), 3)

        harpoon.ui:toggle_quick_menu(harpoon:list())
        table.remove(created_files, 2)
        Buffer.set_contents(harpoon.ui.bufnr, created_files)
        harpoon.ui:save()

        eq(harpoon:list():length(), 2)
        eq(harpoon:list():display(), created_files)
    end)

    it("add file from ui contents and save", function()
        local list = harpoon:list()
        local created_files = utils.fill_list_with_files(3, list)
        table.insert(created_files, os.tmpname())

        eq(list:length(), 3)

        harpoon.ui:toggle_quick_menu(list)
        Buffer.set_contents(harpoon.ui.bufnr, created_files)
        harpoon.ui:save()

        eq(list:length(), 4)
        eq(list:display(), created_files)
    end)

    it("edit ui but toggle should not save", function()
        local list = harpoon:list()
        local created_files = utils.fill_list_with_files(3, list)

        eq(list:length(), 3)

        harpoon.ui:toggle_quick_menu(list)
        Buffer.set_contents(harpoon.ui.bufnr, {})
        harpoon.ui:toggle_quick_menu()

        eq(list:length(), 3)
        eq(created_files, list:display())

    end)
end)
