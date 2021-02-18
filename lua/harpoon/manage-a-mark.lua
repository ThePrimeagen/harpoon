local Path = require('plenary.path')

local M = {}

harpoon_win_id = nil
harpoon_bufh = nil

local cwd = cwd or vim.loop.cwd()
local data_path = vim.fn.stdpath("data")

cwd = cwd:gsub("/", "_")

local file_name = string.format("%s/%s.cache", data_path, cwd)

function get_id_or_current_buffer(id)
    if id == nil then
        return vim.fn.bufname(vim.fn.bufnr())
    end

    return id
end

function hydrate_from_cache()
    ok, res = pcall(function()
        local results = Path:new(file_name):read()
        if results == nil then
            return {}, {}
        end
        return vim.fn.json_decode(results), {}
    end)

    if ok then
        return res, {}
    end

    return {}, {}
end

M.save = function()
    Path:new(file_name):write(vim.fn.json_encode(marked_files), 'w')
end

if not marked_files then
    marked_files, marked_offsets = hydrate_from_cache() 
end

function get_index_of(item)
    if item == nil then
        error("You have provided a nil value to Harpoon, please provide a string rep of the file or the file idx.")
        return
    end
    if type(item) == 'string' then
        for idx = 1, #marked_files do
            if marked_files[idx] == item then
                return idx
            end
        end

        return nil
    end

    if vim.g.manage_a_mark_zero_index then
        item = item + 1
    end

    if item <= #marked_files and item >= 1 then
        return item
    end

    return nil
end

function valid_index(idx) 
    return idx ~= nil and marked_files[idx] ~= nil
end

M.get_index_of = get_index_of
M.valid_index = valid_index

function swap(a_idx, b_idx) 
    local tmp = marked_files[a_idx]
    marked_files[a_idx] = marked_files[b_idx]
    marked_files[b_idx] = tmp
end

M.add_file = function()
    local buf_name = get_id_or_current_buffer()
    if valid_index(get_index_of(buf_name)) then
        -- we don't alter file layout.
        return
    end

    for idx = 1, #marked_files do
        if marked_files[idx] == nil then
            marked_files[idx] = buf_name
            return
        end
    end

    table.insert(marked_files, buf_name)
end

M.store_offset = function() 
    local idx = get_id_or_current_buffer()
    if not valid_index(idx) then
        return
    end

    local line = vim.api.nvim_eval("line('.')");
end

M.swap = function(a, b)
    a_idx = get_index_of(a)
    b_idx = get_index_of(get_id_or_current_buffer(b))

    if not valid_index(a_idx) or not valid_index(b_idx) then
        return
    end

    swap(a_idx, b_idx)
end

M.rm_file = function()
    id = get_id_or_current_buffer()
    idx = get_index_of(id)

    if not valid_index(idx) then
        return
    end

    marked_files[idx] = nil
end

M.clear_all = function()
    marked_files = {}
end

M.promote = function(id)
    id = get_id_or_current_buffer(id)
    idx = get_index_of(id)

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
    for idx = 1, #marked_files do
        if marked_files[idx] ~= nil then
            table.insert(next, marked_files[idx])
        end
    end

    marked_files = next
end

M.shorten_list = function(count) 
    local next = {}
    local up_to = math.min(count, #marked_files)
    for idx = 1, up_to do
        table.insert(next, marked_files[idx])
    end
    marked_files = next
end

M.get_marked_file = function(idx)
    return marked_files[idx]
end

M.get_length = function() 
    return #marked_files
end

return M

