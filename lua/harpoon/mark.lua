local harpoon = require('harpoon')
local utils = require('harpoon.utils')

local M = {}

local function filter_empty_string(list)
    local next = {}
    for idx = 1, #list do
        if list[idx] ~= "" then
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

    local idx = M.get_index_of(id)
    if M.valid_index(idx) then
        return harpoon.get_mark_config().marks[idx]
    end
    --
    -- not sure what to do here...
    --
    return ""
end

M.get_index_of = function(item)
    if item == nil then
        error("You have provided a nil value to Harpoon, please provide a string rep of the file or the file idx.")
        return
    end

    local config = harpoon.get_mark_config()
    if type(item) == 'string' then
        local relative_item = utils.normalize_path(item)
        for idx = 1, M.get_length() do
           if config.marks[idx] == relative_item then
                return idx
            end
        end

        return nil
    end

    if vim.g.manage_a_mark_zero_index then
        item = item + 1
    end

    if item <= M.get_length() and item >= 1 then
        return item
    end

    return nil
end

M.valid_index = function(idx)
    local config = harpoon.get_mark_config()
    return idx ~= nil and config.marks[idx] ~= nil and config.marks[idx] ~= ""
end

M.add_file = function(file_name_or_buf_id)
    local buf_name = get_buf_name(file_name_or_buf_id)

    if M.valid_index(M.get_index_of(buf_name)) then
        -- we don't alter file layout.
        return
    end

    if buf_name == "" or buf_name == nil then
        error("Couldn't find a valid file name to mark, sorry.")
        return
    end

    local config = harpoon.get_mark_config()
    for idx = 1, M.get_length() do
        if config.marks[idx] == "" then
            config.marks[idx] = buf_name
            M.remove_empty_tail()
            return
        end
    end

    table.insert(config.marks, buf_name)
    M.remove_empty_tail()
end

M.remove_empty_tail = function()
    local config = harpoon.get_mark_config()

    for i = M.get_length(), 1, -1 do
        if config.marks[i] ~= "" then
            return
        end

        if config.marks[i] == "" then
            table.remove(config.marks, i)
        end
    end
end

M.store_offset = function()
    local buf_name = get_buf_name()
    local idx = M.get_index_of(buf_name)
    if not M.valid_index(idx) then
        return
    end

    local line = vim.api.nvim_eval("line('.')");
end

M.rm_file = function(file_name_or_buf_id)
    local buf_name = get_buf_name(file_name_or_buf_id)
    local idx = M.get_index_of(buf_name)

    if not M.valid_index(idx) then
        return
    end

    harpoon.get_mark_config().marks[idx] = ""
    M.remove_empty_tail()
end

M.clear_all = function()
    harpoon.get_mark_config().marks = {}
end

M.get_marked_file = function(idx)
    return harpoon.get_mark_config().marks[idx]
end

M.get_length = function()
    return table.maxn(harpoon.get_mark_config().marks)
end

M.set_current_at = function(idx)
    local config = harpoon.get_mark_config()
    local buf_name = get_buf_name()
    local current_idx = M.get_index_of(buf_name)

    -- Remove it if it already exists
    if M.valid_index(current_idx) then
        config.marks[current_idx] = ""
    end

    config.marks[idx] = buf_name

    for i = 1, M.get_length() do
        if not config.marks[i] then
            config.marks[i] = ""
        end
    end
end

M.to_quickfix_list = function()
    local config = harpoon.get_mark_config()
    local file_list = filter_empty_string(config.marks)
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

M.toggle_file = function(file_name_or_buf_id)
    local mark_count_before = #harpoon.get_mark_config().marks

    M.add_file(file_name_or_buf_id)

    local mark_count_after = #harpoon.get_mark_config().marks

    if (mark_count_before == mark_count_after) then
        M.rm_file(file_name_or_buf_id)
        print("Mark removed")
    else
        print("Mark Added")
    end
end

M.to_quickfix_list()

return M

