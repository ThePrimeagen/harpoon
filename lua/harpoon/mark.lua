local Path = require('plenary.path')
local harpoon = require('harpoon')
local utils = require('harpoon.utils')

local M = {}

local function valid_index(idx)
    return idx ~= nil and harpoon.get_mark_config().marks[idx] ~= nil
end

local function get_index_of(item)
    if item == nil then
        error("You have provided a nil value to Harpoon, please provide a string rep of the file or the file idx.")
        return
    end
    local config = harpoon.get_mark_config()
    if type(item) == 'string' then
        local relative_item = utils.normalize_path(item)
        for idx = 1, #config.marks do
           if config.marks[idx] == relative_item then
                return idx
            end
        end

        return nil
    end

    if vim.g.manage_a_mark_zero_index then
        item = item + 1
    end

    if item <= #config.marks and item >= 1 then
        return item
    end

    return nil
end

local function filter_nulls(list)
    local next = {}
    for idx = 1, #list do
        if list[idx] ~= nil then
            table.insert(next, list[idx])
        end
    end

    return next
end

local function get_buf_name(id)
    if id == nil then
        return utils.normalize_path(vim.fn.bufname(vim.fn.bufnr()))
    elseif type(id) == "string" then
        return utils.normalize_path(id)
    end

    local idx = get_index_of(id)
    if valid_index(idx) then
        return harpoon.get_mark_config().marks[idx]
    end
    --
    -- not sure what to do here...
    --
    return ""
end

M.get_index_of = get_index_of
M.valid_index = valid_index

local function swap(a_idx, b_idx)
    local config = harpoon.get_mark_config()
    local tmp = config.marks[a_idx]
    config.marks[a_idx] = config.marks[b_idx]
    config.marks[b_idx] = tmp
end

M.add_file = function(file_name_or_buf_id)
    local buf_name = get_buf_name(file_name_or_buf_id)

    if valid_index(get_index_of(buf_name)) then
        -- we don't alter file layout.
        return
    end

    if buf_name == "" or buf_name == nil then
        error("Couldn't find a valid file name to mark, sorry.")
        return
    end

    local config = harpoon.get_mark_config()
    for idx = 1, #config.marks do
        if config.marks[idx] == nil then
            config.marks[idx] = buf_name
            return
        end
    end

    table.insert(config.marks, buf_name)
end

M.store_offset = function()
    local buf_name = get_buf_name()
    local idx = get_index_of(buf_name)
    if not valid_index(idx) then
        return
    end

    local line = vim.api.nvim_eval("line('.')");
end

M.swap = function(a, b)
    local a_idx = get_index_of(a)
    local b_idx = get_index_of(get_buf_name(b))

    if not valid_index(a_idx) or not valid_index(b_idx) then
        return
    end

    swap(a_idx, b_idx)
end

M.rm_file = function()
    local buf_name = get_buf_name()
    local idx = get_index_of(buf_name)

    if not valid_index(idx) then
        return
    end

    harpoon.get_mark_config().marks[idx] = nil
end

M.trim = function()
    M.shorten_list(idx)
end

M.clear_all = function()
    harpoon.get_mark_config().marks = {}
end

M.promote = function(id)
    local buf_name = get_buf_name(id)
    local idx = get_index_of(buf_name)

    if not valid_index(idx) or idx == 1 then
        return
    end

    swap(idx - 1, idx)
end

M.promote_to_front = function(id)
    local buf_name = get_buf_name(id)
    local idx = get_index_of(buf_name)

    if not valid_index(idx) or idx == 1 then
        return
    end

    swap(1, idx)
end

M.remove_nils = function()
    local config = harpoon.get_mark_config()
    config.marks = filter_nulls(config.marks)
end

M.shorten_list = function(count)
    if not count then
        local buf_name = get_buf_name()
        local idx = get_index_of(buf_name)

        if not valid_index(idx) then
            return
        end

        count = idx
    end

    local next = {}
    local config = harpoon.get_mark_config()
    local up_to = math.min(count, #config.marks)
    for idx = 1, up_to do
        table.insert(next, config.marks[idx])
    end
    config.marks = next
end

M.get_marked_file = function(idx)
    return harpoon.get_mark_config().marks[idx]
end

M.get_length = function()
    return #harpoon.get_mark_config().marks
end

M.to_quickfix_list = function()
    local config = harpoon.get_mark_config()
    local file_list = filter_nulls(config.marks)
    local qf_list = {}
    for idx = 1, #file_list do
        qf_list[idx] = {
            text = string.format("%d: %s", idx, file_list[idx]),
            filename = file_list[idx],
        }
    end
    vim.fn.setqflist(qf_list)
end

M.set_mark_list = function(new_list)
    local config = harpoon.get_mark_config()

    config.marks = new_list
end

M.to_quickfix_list()

return M

