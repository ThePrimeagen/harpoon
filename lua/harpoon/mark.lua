local harpoon = require('harpoon')
local utils = require('harpoon.utils')

-- I think that I may have to organize this better.  I am not the biggest fan
-- of procedural all the things
local M = {}
local callbacks = {}

-- I am trying to avoid over engineering the whole thing.  We will likely only
-- need one event emitted
local function emit_changed()
    if harpoon.get_global_settings().save_on_change then
        harpoon.save()
    end

    if not callbacks["changed"] then
        return
    end

    for _, cb in pairs(callbacks) do
        cb()
    end
end

local function filter_empty_string(list)
    local next = {}
    for idx = 1, #list do
        if list[idx] ~= "" then
            table.insert(next, list[idx].filename)
        end
    end

    return next
end

local function get_first_empty_slot()
    for idx = 1, M.get_length() do
        local filename = M.get_marked_file_name(idx)
        if filename == "" then
            return idx
        end
    end

    return M.get_length() + 1
end

local function get_buf_name(id)
    if id == nil then
        return utils.normalize_path(vim.fn.bufname(vim.fn.bufnr()))
    elseif type(id) == "string" then
        return utils.normalize_path(id)
    end

    local idx = M.get_index_of(id)
    if M.valid_index(idx) then
        return M.get_marked_file_name(idx)
    end
    --
    -- not sure what to do here...
    --
    return ""
end

local function create_mark(filename)
    local cursor_pos = vim.fn.getcurpos()
    return {
        filename = filename,
        row = cursor_pos[2],
        col = cursor_pos[3],
    }
end

local function mark_exists(buf_name)
    for idx = 1, M.get_length() do
        if M.get_marked_file_name(idx) == buf_name then
            return true
        end
    end

    return false
end

local function validate_buf_name(buf_name)
    if buf_name == "" or buf_name == nil then
        error("Couldn't find a valid file name to mark, sorry.")
        return
    end
end

M.get_index_of = function(item)
    if item == nil then
        error("You have provided a nil value to Harpoon, please provide a string rep of the file or the file idx.")
        return
    end

    if type(item) == 'string' then
        local relative_item = utils.normalize_path(item)
        for idx = 1, M.get_length() do
           if M.get_marked_file_name(idx) == relative_item then
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

M.status = function()
    local idx = M.get_index_of(get_buf_name())

    if M.valid_index(idx) then
        return "M" .. idx
    end
    return ""
end

M.valid_index = function(idx)
    if idx == nil then
        return false
    end

    local file_name = M.get_marked_file_name(idx)
    return file_name ~= nil and file_name ~= ""
end

M.add_file = function(file_name_or_buf_id)
    local buf_name = get_buf_name(file_name_or_buf_id)

    if M.valid_index(M.get_index_of(buf_name)) then
        -- we don't alter file layout.
        return
    end

    validate_buf_name(buf_name)

    local found_idx = get_first_empty_slot()
    harpoon.get_mark_config().marks[found_idx] = create_mark(buf_name)
    M.remove_empty_tail(false)
    emit_changed();
end

-- dont_emit_on_changed should only be used internally
M.remove_empty_tail = function(_emit_on_changed)
    _emit_on_changed = _emit_on_changed == nil or _emit_on_changed
    local config = harpoon.get_mark_config()
    local found = false

    for i = M.get_length(), 1, -1 do
        local filename = M.get_marked_file_name(i)
        if filename ~= "" then
            return
        end

        if filename == "" then
            table.remove(config.marks, i)
            found = found or _emit_on_changed
        end
    end

    if found then
        emit_changed()
    end
end

M.store_offset = function()
    local ok, res = pcall(function()
        local buf_name = get_buf_name()
        local idx = M.get_index_of(buf_name)
        if not M.valid_index(idx) then
            return
        end

        local cursor_pos = vim.fn.getcurpos()
        harpoon.get_mark_config().marks[idx].row = cursor_pos[2]
        harpoon.get_mark_config().marks[idx].col = cursor_pos[3]
    end)

    if not ok then
        -- TODO: Developer logs?
        print("M.store_offset#pcall failed:", res)
    end

    emit_changed()
end

M.rm_file = function(file_name_or_buf_id)
    local buf_name = get_buf_name(file_name_or_buf_id)
    local idx = M.get_index_of(buf_name)

    if not M.valid_index(idx) then
        return
    end

    harpoon.get_mark_config().marks[idx] = create_mark("")
    M.remove_empty_tail(false)
    emit_changed()
end

M.clear_all = function()
    harpoon.get_mark_config().marks = {}
    emit_changed()
end

--- ENTERPRISE PROGRAMMING
M.get_marked_file = function(idxOrName)
    if type(idxOrName) == "string" then
        idxOrName = M.get_index_of(idxOrName)
    end
    return harpoon.get_mark_config().marks[idxOrName]
end

M.get_marked_file_name = function(idx)
    local mark = harpoon.get_mark_config().marks[idx]
    return mark and mark.filename
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
        config.marks[current_idx] = create_mark("")
    end

    config.marks[idx] = create_mark(buf_name)

    for i = 1, M.get_length() do
        if not config.marks[i] then
            config.marks[i] = create_mark("")
        end
    end

    emit_changed()
end

M.to_quickfix_list = function()
    local config = harpoon.get_mark_config()
    local file_list = filter_empty_string(config.marks)
    local qf_list = {}
    for idx = 1, #file_list do
        local mark = M.get_marked_file(idx)
        qf_list[idx] = {
            text = string.format("%d: %s", idx, file_list[idx]),
            filename = mark.filename,
            row = mark.row,
            col = mark.col,
        }
    end
    vim.fn.setqflist(qf_list)
end

M.set_mark_list = function(new_list)

    local config = harpoon.get_mark_config()

    for k, v in pairs(new_list) do
        if type(v) == "string" then
            local mark = M.get_marked_file(v)
            if not mark then
                mark = create_mark(v)
            end

            new_list[k] = mark
        end
    end

    config.marks = new_list
    emit_changed()
end

M.toggle_file = function(file_name_or_buf_id)
    local buf_name = get_buf_name(file_name_or_buf_id)

    validate_buf_name(buf_name)

    if (mark_exists(buf_name)) then
        M.rm_file(buf_name)
        print("Mark removed")
    else
        M.add_file(buf_name)
        print("Mark Added")
    end
end

M.get_current_index = function()
    return M.get_index_of(vim.fn.bufname(vim.fn.bufnr()))
end

M.on = function(event, cb)
    if not callbacks[event] then
        callbacks[event] = {}
    end

    table.insert(callbacks[event], cb)
end

return M


