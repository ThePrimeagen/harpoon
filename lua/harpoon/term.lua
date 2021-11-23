local harpoon = require("harpoon")
local log = require("harpoon.dev").log
local global_config = harpoon.get_global_settings()

local M = {}
local terminals = {}

local function create_terminal(create_with)
    if not create_with then
        create_with = ":terminal"
    end
    log.trace("term: _create_terminal(): Init:", create_with)
    local current_id = vim.api.nvim_get_current_buf()

    vim.cmd(create_with)
    local buf_id = vim.api.nvim_get_current_buf()
    local term_id = vim.b.terminal_job_id

    if term_id == nil then
        log.error("_create_terminal(): term_id is nil")
        -- TODO: Throw an error?
        return nil
    end

    -- Make sure the term buffer has "hidden" set so it doesn't get thrown
    -- away and cause an error
    vim.api.nvim_buf_set_option(buf_id, "bufhidden", "hide")

    -- Resets the buffer back to the old one
    vim.api.nvim_set_current_buf(current_id)
    return buf_id, term_id
end

local function find_terminal(args)
    log.trace("term: _find_terminal(): Terminal:", args)
    if type(args) == "number" then
        args = { idx = args }
    end
    local term_handle = terminals[args.idx]
    if not term_handle or not vim.api.nvim_buf_is_valid(term_handle.buf_id) then
        local buf_id, term_id = create_terminal(args.create_with)
        if buf_id == nil then
            error("Failed to find and create terminal.")
            return
        end

        term_handle = {
            buf_id = buf_id,
            term_id = term_id,
        }
        terminals[args.idx] = term_handle
    end
    return term_handle
end

local function get_first_empty_slot()
    log.trace("_get_first_empty_slot()")
    for idx, cmd in pairs(harpoon.get_term_config().cmds) do
        if cmd == "" then
            return idx
        end
    end
    return M.get_length() + 1
end

M.gotoTerminal = function(idx)
    log.trace("term: gotoTerminal(): Terminal:", idx)
    local term_handle = find_terminal(idx)

    vim.api.nvim_set_current_buf(term_handle.buf_id)
end

M.sendCommand = function(idx, cmd, ...)
    log.trace("term: sendCommand(): Terminal:", idx)
    local term_handle = find_terminal(idx)

    if type(cmd) == "number" then
        cmd = harpoon.get_term_config().cmds[cmd]
    end

    if global_config.enter_on_sendcmd then
        cmd = cmd .. "\n"
    end

    if cmd then
        log.debug("sendCommand:", cmd)
        vim.api.nvim_chan_send(term_handle.term_id, string.format(cmd, ...))
    end
end

M.clear_all = function()
    log.trace("term: clear_all(): Clearing all terminals.")
    for _, term in ipairs(terminals) do
        vim.api.nvim_buf_delete(term.buf_id, { force = true })
    end
    terminals = {}
end

M.get_length = function()
    log.trace("_get_length()")
    return table.maxn(harpoon.get_term_config().cmds)
end

M.valid_index = function(idx)
    if idx == nil or idx > M.get_length() or idx <= 0 then
        return false
    end
    return true
end

M.emit_changed = function()
    log.trace("_emit_changed()")
    if harpoon.get_global_settings().save_on_change then
        harpoon.save()
    end
end

M.add_cmd = function(cmd)
    log.trace("add_cmd()")
    local found_idx = get_first_empty_slot()
    harpoon.get_term_config().cmds[found_idx] = cmd
    M.emit_changed()
end

M.rm_cmd = function(idx)
    log.trace("rm_cmd()")
    if not M.valid_index(idx) then
        log.debug("rm_cmd(): no cmd exists for index", idx)
        return
    end
    table.remove(harpoon.get_term_config().cmds, idx)
    M.emit_changed()
end

M.set_cmd_list = function(new_list)
    log.trace("set_cmd_list(): New list:", new_list)
    for k in pairs(harpoon.get_term_config().cmds) do
        harpoon.get_term_config().cmds[k] = nil
    end
    for k, v in pairs(new_list) do
        harpoon.get_term_config().cmds[k] = v
    end
    M.emit_changed()
end

return M
