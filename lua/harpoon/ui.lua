local harpoon = require("harpoon")
local popup = require("popup")
local Marked = require("harpoon.mark")
local log = require("harpoon.dev").log

local M = {}

Harpoon_win_id = nil
Harpoon_bufh = nil

local function create_window()
    log.debug("_create_window()")
    local config = harpoon.get_menu_config()
    local width = config.width or 60
    local height = config.height or 10
    local borderchars = config.borderchars or { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
    local bufnr = vim.api.nvim_create_buf(false, false)

    local Harpoon_win_id, win = popup.create(bufnr, {
        title = "Harpoon",
        highlight = "HarpoonWindow",
        line = math.floor(((vim.o.lines - height) / 2) - 1),
        col = math.floor((vim.o.columns - width) / 2),
        minwidth = width,
        minheight = height,
        borderchars = borderchars,
    })

    vim.api.nvim_win_set_option(win.border.win_id, "winhl", "Normal:HarpoonBorder")

    return {
        bufnr = bufnr,
        win_id = Harpoon_win_id,
    }
end

local function get_menu_items()
    local lines = vim.api.nvim_buf_get_lines(Harpoon_bufh, 0, -1, true)
    local indices = {}

    for idx = 1, #lines do
        local space_location = string.find(lines[idx], " ")

        if space_location ~= nil then
            table.insert(indices, string.sub(lines[idx], space_location + 1))
        end
    end

    return indices
end

M.toggle_quick_menu = function()
    log.debug("toggle_quick_menu()")
    if Harpoon_win_id ~= nil and vim.api.nvim_win_is_valid(Harpoon_win_id) then
        local global_config = harpoon.get_global_settings()

        if global_config.save_on_toggle then
            require("harpoon.ui").on_menu_save()
        end

        vim.api.nvim_win_close(Harpoon_win_id, true)

        Harpoon_win_id = nil
        Harpoon_bufh = nil

        return
    end

    local win_info = create_window()
    local contents = {}

    Harpoon_win_id = win_info.win_id
    Harpoon_bufh = win_info.bufnr

    for idx = 1, Marked.get_length() do
        local file = Marked.get_marked_file_name(idx)
        if file == "" then
            file = "(empty)"
        end
        contents[idx] = string.format("%d %s", idx, file)
    end

    vim.api.nvim_buf_set_name(Harpoon_bufh, "harpoon-menu")
    vim.api.nvim_buf_set_lines(Harpoon_bufh, 0, #contents, false, contents)
    vim.api.nvim_buf_set_option(Harpoon_bufh, "filetype", "harpoon")
    vim.api.nvim_buf_set_option(Harpoon_bufh, "buftype", "acwrite")
    vim.api.nvim_buf_set_option(Harpoon_bufh, "bufhidden", "delete")
    vim.cmd(string.format("autocmd BufWriteCmd <buffer=%s> :lua require('harpoon.ui').on_menu_save()", Harpoon_bufh))
    vim.cmd(string.format("autocmd BufModifiedSet <buffer=%s> set nomodified", Harpoon_bufh))
end

M.on_menu_save = function()
    log.debug("on_menu_save()")
    Marked.set_mark_list(get_menu_items())
end

M.nav_file = function(id)
    log.debug("nav_file(): Navigating to", id)
    local idx = Marked.get_index_of(id)
    if not Marked.valid_index(idx) then
        log.debug("nav_file(): No mark exists for id", id)
        return
    end

    local mark = Marked.get_marked_file(idx)
    local buf_id = vim.fn.bufnr(mark.filename, true)
    local set_row = not vim.api.nvim_buf_is_loaded(buf_id)

    vim.api.nvim_set_current_buf(buf_id)
    if set_row and mark.row then
        local ok, err = pcall(vim.cmd, string.format(":%d", mark.row))
        if not ok then
            log.warn("nav_file(): Could not set row to", mark.row, err)
        end
    end
end

function M.location_window(options)
    local default_options = {
        relative = "editor",
        style = "minimal",
        width = 30,
        height = 15,
        row = 2,
        col = 2,
    }
    options = vim.tbl_extend("keep", options, default_options)

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
        col = win_width - 21,
    })

    vim.api.nvim_buf_set_lines(info.bufnr, 0, 5, false, { "!!! Notification", text })
    vim.api.nvim_set_current_win(prev_win)

    return {
        bufnr = info.bufnr,
        win_id = info.win_id,
    }
end

function M.close_notification(bufnr)
    vim.api.nvim_buf_delete(bufnr)
end

M.nav_next = function()
    log.debug("nav_next()")
    local current_index = Marked.get_current_index()
    local number_of_items = Marked.get_length()

    if current_index == nil then
        current_index = 1
    else
        current_index = current_index + 1
    end

    if (current_index > number_of_items) then
        current_index = 1
    end
    M.nav_file(current_index)
end

M.nav_prev = function()
    log.debug("nav_prev()")
    local current_index = Marked.get_current_index()
    local number_of_items = Marked.get_length()

    if current_index == nil then
        current_index = number_of_items
    else
        current_index = current_index - 1
    end

    if (current_index < 1) then
        current_index = number_of_items
    end

    M.nav_file(current_index)
end

return M
