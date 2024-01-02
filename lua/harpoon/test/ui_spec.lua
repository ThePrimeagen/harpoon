local utils = require("harpoon.test.utils")
local Buffer = require("harpoon.buffer")
local harpoon = require("harpoon")

local eq = assert.are.same
local be = utils.before_each(os.tmpname())

---@param k string
local function key(k)
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes(k, true, false, true),
        "x",
        true
    )
end

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
        harpoon.ui:toggle_quick_menu()

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
        harpoon.ui:toggle_quick_menu()

        eq(list:length(), 4)
        eq(list:display(), created_files)
    end)

    it("add relative files from ui contents and save", function()
        local list = harpoon:list()
        local created_files = utils.fill_list_with_files(3, list)

        table.insert(created_files, "../relative_file_for_testing1")
        created_files[4] = "../relative_file_for_testing1"
        table.insert(created_files, "../harpoon/relative_file_for_testing2")
        created_files[5] = "relative_file_for_testing2"
        table.insert(created_files, "lua/relative_file_for_testing3")
        created_files[6] = "lua/relative_file_for_testing3"
        table.insert(created_files, "./lua/relative_file_for_testing3")
        created_files[7] = "lua/relative_file_for_testing4"

        eq(list:length(), 3)

        harpoon.ui:toggle_quick_menu(list)
        Buffer.set_contents(harpoon.ui.bufnr, created_files)
        harpoon.ui:save()
        harpoon.ui:toggle_quick_menu()

        eq(list:length(), 7)
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

    it("using :q to leave harpoon should quit everything", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())

        local bufnr = harpoon.ui.bufnr
        local win_id = harpoon.ui.win_id

        eq(vim.api.nvim_buf_is_valid(bufnr), true)
        eq(vim.api.nvim_win_is_valid(win_id), true)
        eq(vim.api.nvim_get_current_buf(), bufnr)

        vim.cmd([[ q! ]]) -- TODO: I shouldn't need q! here

        eq(vim.api.nvim_buf_is_valid(bufnr), false)
        eq(vim.api.nvim_win_is_valid(win_id), false)
        eq(harpoon.ui.bufnr, nil)
        eq(harpoon.ui.win_id, nil)
    end)

    it(
        "closing toggle_quick_menu with save_on_toggle should save contents",
        function()
            harpoon:setup({ settings = { save_on_toggle = true } })
            local list = harpoon:list()
            local created_files = utils.fill_list_with_files(3, list)

            harpoon.ui:toggle_quick_menu(list)
            table.remove(created_files, 2)
            Buffer.set_contents(harpoon.ui.bufnr, created_files)
            harpoon.ui:toggle_quick_menu()

            eq(list:length(), 2)
            eq(list:display(), created_files)
        end
    )

    it("exiting the ui with something like <C-w><C-w>", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())

        local bufnr = harpoon.ui.bufnr
        local win_id = harpoon.ui.win_id

        eq(vim.api.nvim_buf_is_valid(bufnr), true)
        eq(vim.api.nvim_win_is_valid(win_id), true)
        eq(vim.api.nvim_get_current_buf(), bufnr)

        key("<C-w><C-w>")

        eq(vim.api.nvim_buf_is_valid(bufnr), false)
        eq(vim.api.nvim_win_is_valid(win_id), false)
        eq(harpoon.ui.bufnr, nil)
        eq(harpoon.ui.win_id, nil)
    end)

    it("exiting the ui with q (see harpoon.buffer)", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())

        local bufnr = harpoon.ui.bufnr
        local win_id = harpoon.ui.win_id

        eq(vim.api.nvim_buf_is_valid(bufnr), true)
        eq(vim.api.nvim_win_is_valid(win_id), true)
        eq(vim.api.nvim_get_current_buf(), bufnr)

        key("q")

        eq(vim.api.nvim_buf_is_valid(bufnr), false)
        eq(vim.api.nvim_win_is_valid(win_id), false)
        eq(harpoon.ui.bufnr, nil)
        eq(harpoon.ui.win_id, nil)
    end)

    it("exiting the ui with <Esc> (see harpoon.buffer)", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())

        local bufnr = harpoon.ui.bufnr
        local win_id = harpoon.ui.win_id

        eq(vim.api.nvim_buf_is_valid(bufnr), true)
        eq(vim.api.nvim_win_is_valid(win_id), true)
        eq(vim.api.nvim_get_current_buf(), bufnr)

        key("<Esc>")

        eq(vim.api.nvim_buf_is_valid(bufnr), false)
        eq(vim.api.nvim_win_is_valid(win_id), false)
        eq(harpoon.ui.bufnr, nil)
        eq(harpoon.ui.win_id, nil)
    end)

    it("exiting the ui with something like :bprev / :bnext", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())

        local bufnr = harpoon.ui.bufnr
        local win_id = harpoon.ui.win_id

        eq(vim.api.nvim_buf_is_valid(bufnr), true)
        eq(vim.api.nvim_win_is_valid(win_id), true)
        eq(vim.api.nvim_get_current_buf(), bufnr)

        -- Some people use keymaps that trigger these commands
        vim.cmd("bprev")

        eq(vim.api.nvim_buf_is_valid(bufnr), false)
        eq(vim.api.nvim_win_is_valid(win_id), false)
        eq(harpoon.ui.bufnr, nil)
        eq(harpoon.ui.win_id, nil)
    end)
end)
