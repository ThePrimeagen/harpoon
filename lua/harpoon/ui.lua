local float = require('plenary.window.float')
local Marked = require('harpoon.mark')

local factorw = 0.42069
local factorh = 0.69420

local M = {}

win_id = nil
bufh = nil

function create_window()
    local win_info = float.percentage_range_window(
        factorw,
        factorh,
        {
            winblend = 0
        })

    return win_info
end

function get_menu_items()
    local lines = vim.api.nvim_buf_get_lines(bufh, 0, -1, true)
    local indices = {}

    for idx = 1, #lines do
        local space_location = string.find(lines[idx], ' ')

        if space_location ~= nil then
            table.insert(indices, string.sub(lines[idx], space_location + 1))
        end
    end

    return indices
end

local save_changes = function()
    Marked.set_mark_list(get_menu_items())
end

M.toggle_quick_menu = function()
    if win_id ~= nil and vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_close(win_id, true)

        win_id = nil
        bufh = nil

        return
    end

    local win_info = create_window()
    local contents = {}

    win_id = win_info.win_id
    bufh = win_info.bufnr

    for idx = 1, Marked.get_length() do
        local file = Marked.get_marked_file(idx)
        if file == "" then
            file = "(empty)"
        end
        contents[idx] = string.format("%d %s", idx, file)
    end

    vim.api.nvim_buf_set_name(bufh, "harpoon-menu")
    vim.api.nvim_buf_set_lines(bufh, 0, #contents, false, contents)
    vim.api.nvim_buf_set_option(bufh, "filetype", "harpoon")
    vim.api.nvim_buf_set_option(bufh, "buftype", "acwrite")
    vim.api.nvim_buf_set_option(bufh, "bufhidden", "delete")
    vim.cmd(string.format("autocmd BufWriteCmd <buffer=%s> :lua require('harpoon.ui').on_menu_save()", bufh))
    vim.cmd(string.format("autocmd BufModifiedSet <buffer=%s> set nomodified", bufh))
end

M.on_menu_save = function()
    save_changes()
end

M.nav_file = function(id)
    idx = Marked.get_index_of(id)
    if not Marked.valid_index(idx) then
        return
    end

    local buf_id = vim.fn.bufnr(Marked.get_marked_file(idx))

    if vim.api.nvim_win_is_valid(buf_id) then
        vim.api.nvim_win_close(win_id)
    end

    if buf_id ~= nil and buf_id ~= -1 then
        vim.api.nvim_set_current_buf(buf_id)
    else
        vim.cmd(string.format("e %s", Marked.get_marked_file(idx)))
    end
end

function M.location_window(options)
    local default_options = {
        relative = 'editor',
        style = 'minimal',
        width = 30,
        height = 15,
        row = 2,
        col = 2,
    }
    options = vim.tbl_extend('keep', options, default_options)

    local bufnr = options.bufnr or vim.fn.nvim_create_buf(false, true)
    local win_id = vim.fn.nvim_open_win(bufnr, true, options)

    return {
        bufnr = bufnr,
        win_id = win_id,
    }
end

function M.notification(text)
    local win_stats = vim.api.nvim_list_uis()[1]
    local win_width = win_stats.width

    local prev_win = vim.api.nvim_get_current_win()

    local info = M.location_window({
        width = 20,
        height = 2,
        row = 1,
        col = win_width - 21
    })

    vim.api.nvim_buf_set_lines(info.bufnr, 0, 5, false, {"!!! Notification", text})
    vim.api.nvim_set_current_win(prev_win)

    return {
        bufnr = info.bufnr,
        win_id = info.win_id
    }
end

function M.close_notification(bufnr)
    vim.api.nvim_buf_delete(bufnr)
end

M.nav_next = function()
    local current_index = Marked.get_current_index()
    local number_of_items = Marked.get_length()

    if current_index  == nil then
        current_index = 1
    else
        current_index = current_index + 1
    end

    if (current_index > number_of_items)  then
        current_index = 1
    end
    M.nav_file(current_index)
end

M.nav_prev = function()
    local current_index = Marked.get_current_index()
    local number_of_items = Marked.get_length()

    if current_index  == nil then
        current_index = number_of_items
    else
        current_index = current_index - 1
    end

    if (current_index < 1)  then
        current_index = number_of_items
    end

    M.nav_file(current_index)
end

return M

