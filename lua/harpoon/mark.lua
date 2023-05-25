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
    log.trace("_emit_changed()")
    if harpoon.get_global_settings().save_on_change then
        harpoon.save()
    end

    if not callbacks["changed"] then
        log.trace("_emit_changed(): no callbacks for 'changed', returning")
        return
    end

    for idx, cb in pairs(callbacks["changed"]) do
        log.trace(
            string.format(
                "_emit_changed(): Running callback #%d for 'changed'",
                idx
            )
        )
        cb()
    end
end

local function filter_empty_string(list)
    log.trace("_filter_empty_string()")
    local next = {}
    for idx = 1, #list do
        if list[idx] ~= "" then
            table.insert(next, list[idx].filename)
        end
    end

    return next
end

local function get_first_empty_slot()
    log.trace("_get_first_empty_slot()")
    for idx = 1, M.get_length() do
        local filename = M.get_marked_file_name(idx)
        if filename == "" then
            return idx
        end
    end

    return M.get_length() + 1
end

local function get_buf_name(id)
    log.trace("_get_buf_name():", id)
    if id == nil then
        return utils.normalize_path(vim.api.nvim_buf_get_name(0))
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
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    log.trace(
        string.format(
            "_create_mark(): Creating mark at row: %d, col: %d for %s",
            cursor_pos[1],
            cursor_pos[2],
            filename
        )
    )
    return {
        filename = filename,
        row = cursor_pos[1],
        col = cursor_pos[2],
    }
end

local function mark_exists(buf_name)
    log.trace("_mark_exists()")
    for idx = 1, M.get_length() do
        if M.get_marked_file_name(idx) == buf_name then
            log.debug("_mark_exists(): Mark exists", buf_name)
            return true
        end
    end

    log.debug("_mark_exists(): Mark doesn't exist", buf_name)
    return false
end

local function validate_buf_name(buf_name)
    log.trace("_validate_buf_name():", buf_name)
    if buf_name == "" or buf_name == nil then
        log.error(
            "_validate_buf_name(): Not a valid name for a mark,",
            buf_name
        )
        error("Couldn't find a valid file name to mark, sorry.")
        return
    end
end

local function filter_filetype()
    local current_filetype = vim.bo.filetype
    local excluded_filetypes = harpoon.get_global_settings().excluded_filetypes

    if current_filetype == "harpoon" then
        log.error("filter_filetype(): You can't add harpoon to the harpoon")
        error("You can't add harpoon to the harpoon")
        return
    end

    if vim.tbl_contains(excluded_filetypes, current_filetype) then
        log.error(
            'filter_filetype(): This filetype cannot be added or is included in the "excluded_filetypes" option'
        )
        error(
            'This filetype cannot be added or is included in the "excluded_filetypes" option'
        )
        return
    end
end

local function notify(message, buf_name, index, level)
    if harpoon.get_global_settings().enable_notifications then
        vim.notify(string.format(message, buf_name, index), level)
    end
end

function M.get_index_of(item, marks)
    log.trace("get_index_of():", item)
    if item == nil then
        log.error(
            "get_index_of(): Function has been supplied with a nil value."
        )
        error(
            "You have provided a nil value to Harpoon, please provide a string rep of the file or the file idx."
        )
        return
    end

    if type(item) == "string" then
        local relative_item = utils.normalize_path(item)
        if marks == nil then
            marks = harpoon.get_mark_config().marks
        end
        for idx = 1, M.get_length(marks) do
            if marks[idx] and marks[idx].filename == relative_item then
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

function M.status(bufnr)
    log.trace("status()")
    local buf_name
    if bufnr then
        buf_name = vim.api.nvim_buf_get_name(bufnr)
    else
        buf_name = vim.api.nvim_buf_get_name(0)
    end

    local norm_name = utils.normalize_path(buf_name)
    local idx = M.get_index_of(norm_name)

    if M.valid_index(idx) then
        return "M" .. idx
    end
    return ""
end

function M.valid_index(idx, marks)
    log.trace("valid_index():", idx)
    if idx == nil then
        return false
    end

    local file_name = M.get_marked_file_name(idx, marks)
    return file_name ~= nil and file_name ~= ""
end

function M.add_file(file_name_or_buf_id)
    filter_filetype()
    local buf_name = get_buf_name(file_name_or_buf_id)
    log.trace("add_file():", buf_name)

    if M.valid_index(M.get_index_of(buf_name)) then
        -- we don't alter file layout.
        local found_idx = M.get_index_of(buf_name)
        notify("`%s` is already set as index `%d`", buf_name, found_idx, vim.log.levels.WARN)
        return
    end

    validate_buf_name(buf_name)

    local found_idx = get_first_empty_slot()
    notify("Added `%s` as index `%d`", buf_name, found_idx, vim.log.levels.INFO)

    harpoon.get_mark_config().marks[found_idx] = create_mark(buf_name)
    M.remove_empty_tail(false)
    emit_changed()
end

-- _emit_on_changed == false should only be used internally
function M.remove_empty_tail(_emit_on_changed)
    log.trace("remove_empty_tail()")
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

function M.store_offset()
    log.trace("store_offset()")
    local ok, res = pcall(function()
        local marks = harpoon.get_mark_config().marks
        local buf_name = get_buf_name()
        local idx = M.get_index_of(buf_name, marks)
        if not M.valid_index(idx, marks) then
            return
        end

        local cursor_pos = vim.api.nvim_win_get_cursor(0)
        log.debug(
            string.format(
                "store_offset(): Stored row: %d, col: %d",
                cursor_pos[1],
                cursor_pos[2]
            )
        )
        marks[idx].row = cursor_pos[1]
        marks[idx].col = cursor_pos[2]
    end)

    if not ok then
        log.warn("store_offset(): Could not store offset:", res)
    end

    emit_changed()
end

function M.rm_file(file_name_or_buf_id)
    local buf_name = get_buf_name(file_name_or_buf_id)
    local idx = M.get_index_of(buf_name)
    log.trace("rm_file(): Removing mark at id", idx)

    if not M.valid_index(idx) then
        log.debug("rm_file(): No mark exists for id", file_name_or_buf_id)
        return
    end

    harpoon.get_mark_config().marks[idx] = create_mark("")
    M.remove_empty_tail(false)
    emit_changed()
end

function M.clear_all()
    harpoon.get_mark_config().marks = {}
    log.trace("clear_all(): Clearing all marks.")
    emit_changed()
end

--- ENTERPRISE PROGRAMMING
function M.get_marked_file(idxOrName)
    log.trace("get_marked_file():", idxOrName)
    if type(idxOrName) == "string" then
        idxOrName = M.get_index_of(idxOrName)
    end
    return harpoon.get_mark_config().marks[idxOrName]
end

function M.get_marked_file_name(idx, marks)
    local mark
    if marks ~= nil then
        mark = marks[idx]
    else
        mark = harpoon.get_mark_config().marks[idx]
    end
    log.trace("get_marked_file_name():", mark and mark.filename)
    return mark and mark.filename
end

function M.get_length(marks)
    if marks == nil then
        marks = harpoon.get_mark_config().marks
    end
    log.trace("get_length()")
    return table.maxn(marks)
end

function M.set_current_at(idx)
    filter_filetype()
    local buf_name = get_buf_name()
    log.trace("set_current_at(): Setting id", idx, buf_name)
    local config = harpoon.get_mark_config()
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

function M.to_quickfix_list()
    log.trace("to_quickfix_list(): Sending marks to quickfix list.")
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
    log.debug("to_quickfix_list(): qf_list:", qf_list)
    vim.fn.setqflist(qf_list)
end

function M.set_mark_list(new_list)
    log.trace("set_mark_list(): New list:", new_list)

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

function M.toggle_file(file_name_or_buf_id)
    local buf_name = get_buf_name(file_name_or_buf_id)
    log.trace("toggle_file():", buf_name)

    validate_buf_name(buf_name)

    if mark_exists(buf_name) then
        M.rm_file(buf_name)
        print("Mark removed")
        log.debug("toggle_file(): Mark removed")
    else
        M.add_file(buf_name)
        print("Mark added")
        log.debug("toggle_file(): Mark added")
    end
end

function M.get_current_index()
    log.trace("get_current_index()")
    return M.get_index_of(vim.api.nvim_buf_get_name(0))
end

function M.on(event, cb)
    log.trace("on():", event)
    if not callbacks[event] then
        log.debug("on(): no callbacks yet for", event)
        callbacks[event] = {}
    end

    table.insert(callbacks[event], cb)
    log.debug("on(): All callbacks:", callbacks)
end

return M
