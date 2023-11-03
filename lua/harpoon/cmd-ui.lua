local harpoon = require("harpoon")
local popup = require("plenary.popup")
local utils = require("harpoon.utils")
local log = require("harpoon.dev").log
local term = require("harpoon.term")

local M = {}

Harpoon_cmd_win_id = nil
Harpoon_cmd_bufh = nil

local function close_menu(force_save)
    force_save = force_save or false
    local global_config = harpoon.get_global_settings()

    if global_config.save_on_toggle or force_save then
        require("harpoon.cmd-ui").on_menu_save()
    end

    vim.api.nvim_win_close(Harpoon_cmd_win_id, true)

    Harpoon_cmd_win_id = nil
    Harpoon_cmd_bufh = nil
end

local function create_window()
    log.trace("_create_window()")
    local config = harpoon.get_menu_config()
    local width = type(config.width) == "function" and config.width()
        or config.width
        or 60
    local height = config.height or 10
    local borderchars = config.borderchars
        or { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
    local bufnr = vim.api.nvim_create_buf(false, false)

    local Harpoon_cmd_win_id, win = popup.create(bufnr, {
        title = "Harpoon Commands",
        highlight = "HarpoonWindow",
        line = math.floor(((vim.o.lines - height) / 2) - 1),
        col = math.floor((vim.o.columns - width) / 2),
        minwidth = width,
        minheight = height,
        borderchars = borderchars,
    })

    vim.api.nvim_win_set_option(
        win.border.win_id,
        "winhl",
        "Normal:HarpoonBorder"
    )

    return {
        bufnr = bufnr,
        win_id = Harpoon_cmd_win_id,
    }
end

local function get_menu_items()
    log.trace("_get_menu_items()")
    local lines = vim.api.nvim_buf_get_lines(Harpoon_cmd_bufh, 0, -1, true)
    local indices = {}

    for _, line in pairs(lines) do
        if not utils.is_white_space(line) then
            table.insert(indices, line)
        end
    end

    return indices
end

function M.toggle_quick_menu()
    log.trace("cmd-ui#toggle_quick_menu()")
    if
        Harpoon_cmd_win_id ~= nil
        and vim.api.nvim_win_is_valid(Harpoon_cmd_win_id)
    then
        close_menu()
        return
    end

    local win_info = create_window()
    local contents = {}
    local global_config = harpoon.get_global_settings()

    Harpoon_cmd_win_id = win_info.win_id
    Harpoon_cmd_bufh = win_info.bufnr

    for idx, cmd in pairs(harpoon.get_term_config().cmds) do
        contents[idx] = cmd
    end

    vim.api.nvim_win_set_option(Harpoon_cmd_win_id, "number", true)
    vim.api.nvim_buf_set_name(Harpoon_cmd_bufh, "harpoon-cmd-menu")
    vim.api.nvim_buf_set_lines(Harpoon_cmd_bufh, 0, #contents, false, contents)
    vim.api.nvim_buf_set_option(Harpoon_cmd_bufh, "filetype", "harpoon")
    vim.api.nvim_buf_set_option(Harpoon_cmd_bufh, "buftype", "acwrite")
    vim.api.nvim_buf_set_option(Harpoon_cmd_bufh, "bufhidden", "delete")
    vim.api.nvim_buf_set_keymap(
        Harpoon_cmd_bufh,
        "n",
        "q",
        "<Cmd>lua require('harpoon.cmd-ui').toggle_quick_menu()<CR>",
        { silent = true }
    )
    vim.api.nvim_buf_set_keymap(
        Harpoon_cmd_bufh,
        "n",
        "<ESC>",
        "<Cmd>lua require('harpoon.cmd-ui').toggle_quick_menu()<CR>",
        { silent = true }
    )
    vim.api.nvim_buf_set_keymap(
        Harpoon_cmd_bufh,
        "n",
        "<CR>",
        "<Cmd>lua require('harpoon.cmd-ui').select_menu_item()<CR>",
        {}
    )
    vim.cmd(
        string.format(
            "autocmd BufWriteCmd <buffer=%s> lua require('harpoon.cmd-ui').on_menu_save()",
            Harpoon_cmd_bufh
        )
    )
    if global_config.save_on_change then
        vim.cmd(
            string.format(
                "autocmd TextChanged,TextChangedI <buffer=%s> lua require('harpoon.cmd-ui').on_menu_save()",
                Harpoon_cmd_bufh
            )
        )
    end
    vim.cmd(
        string.format(
            "autocmd BufModifiedSet <buffer=%s> set nomodified",
            Harpoon_cmd_bufh
        )
    )
end

function M.select_menu_item()
    log.trace("cmd-ui#select_menu_item()")
    local cmd = vim.fn.line(".")
    close_menu(true)
    local answer = vim.fn.input("Terminal index (default to 1): ")
    if answer == "" then
        answer = "1"
    end
    local idx = tonumber(answer)
    if idx then
        term.sendCommand(idx, cmd)
    end
end

function M.on_menu_save()
    log.trace("cmd-ui#on_menu_save()")
    term.set_cmd_list(get_menu_items())
end

return M
