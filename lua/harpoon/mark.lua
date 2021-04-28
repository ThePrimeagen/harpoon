local harpoon = require("harpoon")
local utils = require("harpoon.utils")
local log = require("harpoon.dev").log

-- I think that I may have to organize this better.  I am not the biggest fan
-- of procedural all the things
local M = {}
local callbacks = {}

-- I am trying to avoid over engineering the whole thing.  We will likely only
-- need one event emitted
local function emit_changed()
    log.debug("_emit_changed()")
    if harpoon.get_global_settings().save_on_change then
        harpoon.save()
    end

    if not callbacks["changed"] then
        log.debug("_emit_changed(): no callbacks for 'changed', returning")
        return
    end

    for idx, cb in pairs(callbacks["changed"]) do
        log.debug(string.format("_emit_changed(): Running callback #%d for 'changed'", idx))
        cb()
    end
end

local function filter_empty_string(list)
    log.debug("_filter_empty_string()")
    local next = {}
    for idx = 1, #list do
        if list[idx] ~= "" then
            table.insert(next, list[idx].filename)
        end
    end

    return next
end

local function get_first_empty_slot()
    log.debug("_get_first_empty_slot()")
    for idx = 1, M.get_length() do
        local filename = M.get_marked_file_name(idx)
        if filename == "" then
            return idx
        end
    end

    return M.get_length() + 1
end

local function get_buf_name(id)
    log.debug("_get_buf_name():", id)
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
    log.debug(string.format(
        "_create_mark(): Creating mark at row: %d, col: %d for %s",
        cursor_pos[2],
        cursor_pos[4],
        filename
    ))
    return {
        filename = filename,
        row = cursor_pos[2],
        col = cursor_pos[3],
    }
end

local function mark_exists(buf_name)
    log.debug("_mark_exists()")
    for idx = 1, M.get_length() do
        if M.get_marked_file_name(idx) == buf_name then
            log.trace("_mark_exists(): Mark exists", buf_name)
            return true
        end
    end

    log.trace("_mark_exists(): Mark doesn't exist", buf_name)
    return false
end

local function validate_buf_name(buf_name)
    log.debug("_validate_buf_name():", buf_name)
    if buf_name == "" or buf_name == nil then
        log.error("_validate_buf_name(): Not a valid name for a mark,", buf_name)
        return
    end
end

M.get_index_of = function(item)
    log.debug("get_index_of():", item)
    if item == nil then
        log.error("get_index_of(): You have provided a nil value to Harpoon, please provide a string rep of the file or the file idx.")
        return
    end

    if type(item) == "string" then
        local relative_item = utils.normalize_path(item)
        for idx = 1, M.get_length() do
            if M.get_marked_file_name(idx) == relative_item then
                return idx
            end
        end

        return nil
    end

    -- TODO move this to a "harpoon_" prefix or global config?
    if vim.g.manage_a_mark_zero_index then
        item = item + 1
    end

    if item <= M.get_length() and item >= 1 then
        return item
    end

    log.debug("get_index_of(): No item found,", item)
    return nil
end

M.status = function()
    log.debug("status()")
    local idx = M.get_index_of(get_buf_name())

    if M.valid_index(idx) then
        return "M" .. idx
    end
    return ""
end

M.valid_index = function(idx)
    log.debug("valid_index():", idx)
    if idx == nil then
        return false
    end

    local file_name = M.get_marked_file_name(idx)
    return file_name ~= nil and file_name ~= ""
end

M.add_file = function(file_name_or_buf_id)
    local buf_name = get_buf_name(file_name_or_buf_id)
    log.debug("add_file():", buf_name)

    if M.valid_index(M.get_index_of(buf_name)) then
        -- we don't alter file layout.
        return
    end

    validate_buf_name(buf_name)

    local found_idx = get_first_empty_slot()
    harpoon.get_mark_config().marks[found_idx] = create_mark(buf_name)
    M.remove_empty_tail(false)
    emit_changed()
end

-- _emit_on_changed == false should only be used internally
M.remove_empty_tail = function(_emit_on_changed)
    log.debug("remove_empty_tail()")
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
    log.debug("store_offset()")
    local ok, res = pcall(function()
        local buf_name = get_buf_name()
        local idx = M.get_index_of(buf_name)

        if not M.valid_index(idx) then
            return
        end

        local cursor_pos = vim.fn.getcurpos()
        log.debug(string.format("store_offset(): Stored row: %d, col: %d", cursor_pos[2], cursor_pos[3]))
        harpoon.get_mark_config().marks[idx].row = cursor_pos[2]
        harpoon.get_mark_config().marks[idx].col = cursor_pos[3]
    end)

    if not ok then
        log.warn("store_offset(): Could not store offset:", res)
    end

    emit_changed()
end

M.rm_file = function(file_name_or_buf_id)
    local buf_name = get_buf_name(file_name_or_buf_id)
    local idx = M.get_index_of(buf_name)

    if not M.valid_index(idx) then
        log.debug("rm_file(): No mark exists for id", file_name_or_buf_id)
        return
    end

    harpoon.get_mark_config().marks[idx] = create_mark("")
    M.remove_empty_tail(false)
    emit_changed()
    log.debug("rm_file(): Removed mark at id", idx)
end

M.clear_all = function()
    harpoon.get_mark_config().marks = {}
    log.debug("clear_all(): Clearing all marks.")
    emit_changed()
end

--- ENTERPRISE PROGRAMMING
M.get_marked_file = function(idxOrName)
    log.debug("get_marked_file():", idxOrName)
    if type(idxOrName) == "string" then
        idxOrName = M.get_index_of(idxOrName)
    end
    return harpoon.get_mark_config().marks[idxOrName]
end

M.get_marked_file_name = function(idx)
    local mark = harpoon.get_mark_config().marks[idx]
    log.debug("get_marked_file_name():", mark and mark.filename)
    return mark and mark.filename
end

M.get_length = function()
    log.debug("get_length()")
    return table.maxn(harpoon.get_mark_config().marks)
end

M.set_current_at = function(idx)
    local config = harpoon.get_mark_config()
    local buf_name = get_buf_name()
    local current_idx = M.get_index_of(buf_name)

    log.debug("set_current_at(): Setting id", idx, buf_name)

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
    log.debug("to_quickfix_list(): Sending marks to quickfix list.")
    vim.fn.setqflist(qf_list)
end

M.set_mark_list = function(new_list)
    log.debug("set_mark_list()")
    log.trace("set_mark_list(): new_list", new_list)

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

    log.debug("toggle_file():", buf_name)

    validate_buf_name(buf_name)

    if (mark_exists(buf_name)) then
        M.rm_file(buf_name)
        print("Mark removed")
        log.trace("toggle_file(): Mark removed")
    else
        M.add_file(buf_name)
        print("Mark added")
        log.trace("toggle_file(): Mark added")
    end
end

M.get_current_index = function()
    log.debug("get_current_index()")
    return M.get_index_of(vim.fn.bufname(vim.fn.bufnr()))
end

M.on = function(event, cb)
    log.debug("on():", event)
    if not callbacks[event] then
        log.debug("on(): no callbacks yet for", event)
        callbacks[event] = {}
    end

    table.insert(callbacks[event], cb)
    log.trace("on(): All callbacks:", callbacks)
end

return M
