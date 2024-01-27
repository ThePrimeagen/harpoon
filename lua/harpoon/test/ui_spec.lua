local utils = require("harpoon.test.utils")
local Buffer = require("harpoon.buffer")
local harpoon = require("harpoon")
local extensions = require("harpoon.extensions")

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

    it("opens the selected file", function()
        local created_files = utils.fill_list_with_files(3, harpoon:list())

        for i, file in ipairs(created_files) do
            harpoon.ui:toggle_quick_menu(harpoon:list())
            vim.api.nvim_win_set_cursor(0, { i, 0 })
            require("harpoon.buffer"):run_select_command()

            eq(vim.api.nvim_buf_get_name(0), file)
        end
    end)

    it("can navigate with numbers on default list AND custom lists", function()
        harpoon:setup({
            ["cmd"] = {
                select = function(list_item)
                    vim.cmd(list_item.value)
                end,
            },
        })
        harpoon:extend(extensions.builtins.navigate_with_number())

        local default_list = harpoon:list()
        local created_files = utils.fill_list_with_files(3, default_list)

        local cmd_list = harpoon:list("cmd")
        local created_cmds = vim.tbl_map(function(filename)
            return "lua vim.api.nvim_buf_set_lines(0, 0, -1, false, { '"
                .. filename
                .. "' })"
        end, created_files)

        harpoon.ui:toggle_quick_menu(cmd_list)
        Buffer.set_contents(harpoon.ui.bufnr, created_cmds)
        harpoon.ui:save()
        harpoon.ui:close_menu()

        for i, filename in ipairs(created_files) do
            for j, list in ipairs({ default_list, cmd_list }) do
                local expected_line = j == 1 and "test" or filename
                harpoon.ui:toggle_quick_menu(list)
                key(tostring(i))

                eq(vim.api.nvim_buf_get_name(0), filename)
                eq(expected_line, vim.api.nvim_get_current_line())
            end
        end
    end)
end)
