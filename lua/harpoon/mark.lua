local Path = require('plenary.path')

local M = {}
local cwd = cwd or vim.loop.cwd()

mark_config = mark_config or {}

function get_id_or_current_buffer(id)
    if id == nil then
        return vim.fn.bufname(vim.fn.bufnr())
    end

    return id
end

M.setup = function(config) 
    mark_config = config
    if mark_config.marks == nil then

        -- resetting the mark config if there is an issue loading the config
        -- this can hide errors.  
        --
        -- TODO: create a logging mechanism to get these values
        mark_config = {
            marks = {}
        }
    end
end

M.get_config = function() 
    return mark_config
end

function get_index_of(item)
    if item == nil then
        error("You have provided a nil value to Harpoon, please provide a string rep of the file or the file idx.")
        return
    end
    if type(item) == 'string' then
        for idx = 1, #mark_config.marks do
           if mark_config.marks[idx] == item then
                return idx
            end
        end

        return nil
    end

    if vim.g.manage_a_mark_zero_index then
        item = item + 1
    end

    if item <= #mark_config.marks and item >= 1 then
        return item
    end

    return nil
end

function valid_index(idx) 
    return idx ~= nil and mark_config.marks[idx] ~= nil
end

M.get_index_of = get_index_of
M.valid_index = valid_index

function swap(a_idx, b_idx) 
    local tmp = mark_config.marks[a_idx]
    mark_config.marks[a_idx] = mark_config.marks[b_idx]
    mark_config.marks[b_idx] = tmp
end

M.add_file = function()
    local buf_name = get_id_or_current_buffer()
    if valid_index(get_index_of(buf_name)) then
        -- we don't alter file layout.
        return
    end

    for idx = 1, #mark_config.marks do
        if mark_config.marks[idx] == nil then
            mark_config.marks[idx] = buf_name
            return
        end
    end

    table.insert(mark_config.marks, buf_name)
end

M.store_offset = function() 
    local id = get_id_or_current_buffer()
    local idx = get_index_of(id)
    if not valid_index(idx) then
        return
    end

    local line = vim.api.nvim_eval("line('.')");
end

M.swap = function(a, b)
    local a_idx = get_index_of(a)
    local b_idx = get_index_of(get_id_or_current_buffer(b))

    if not valid_index(a_idx) or not valid_index(b_idx) then
        return
    end

    swap(a_idx, b_idx)
end

M.rm_file = function()
    local id = get_id_or_current_buffer()
    local idx = get_index_of(id)

    if not valid_index(idx) then
        return
    end

    mark_config.marks[idx] = nil
end

M.trim = function() 
    M.shorten_list(idx)
end

M.clear_all = function()
    mark_config.marks = {}
end

M.promote = function(id)
    local id = get_id_or_current_buffer(id)
    local idx = get_index_of(id)

    if not valid_index(idx) or idx == 1 then
        return
    end

    swap(idx - 1, idx)
end

M.promote_to_front = function(id)
    id = get_id_or_current_buffer(id)

    idx = get_index_of(id)
    if not valid_index(idx) or idx == 1 then
        return
    end

    swap(1, idx)
end

M.remove_nils = function()
    local next = {}
    for idx = 1, #mark_config.marks do
        if mark_config.marks[idx] ~= nil then
            table.insert(next, mark_config.marks[idx])
        end
    end

    mark_config.marks = next
end

M.shorten_list = function(count) 
    if not count then
        local id = get_id_or_current_buffer()
        local idx = get_index_of(id)

        if not valid_index(idx) then
            return
        end

        count = idx
    end

    local next = {}
    local up_to = math.min(count, #mark_config.marks)
    for idx = 1, up_to do
        table.insert(next, mark_config.marks[idx])
    end
    mark_config.marks = next
end

M.get_marked_file = function(idx)
    return mark_config.marks[idx]
end

M.get_length = function() 
    return #mark_config.marks
end

return M

