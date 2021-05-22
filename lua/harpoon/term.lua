local harpoon = require("harpoon")
local log = require("harpoon.dev").log

local M = {}
local terminals = {}

local function create_terminal(create_cmd)
    if not create_cmd then
        create_cmd = ":terminal"
    end
    log.trace("_create_terminal(): Init:", create_cmd)
    local current_id = vim.fn.bufnr()

    vim.cmd(create_cmd)
    local buf_id = vim.fn.bufnr()
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

local function find_terminal(idx, create_cmd)
    log.trace("_find_terminal(): Terminal:", idx)
    local term_handle = terminals[idx]
    if not term_handle or not vim.api.nvim_buf_is_valid(term_handle.buf_id) then
        local buf_id, term_id = create_terminal(create_cmd)
        if buf_id == nil then
            return
        end

        term_handle = {
            buf_id = buf_id,
            term_id = term_id,
        }
        terminals[idx] = term_handle
    end
    return term_handle
end

M.gotoTerminal = function(idx, create_cmd)
    log.trace("gotoTerminal(): Terminal:", idx)
    local term_handle = find_terminal(idx, create_cmd)

    vim.api.nvim_set_current_buf(term_handle.buf_id)
end

M.sendCommand = function(idx, cmd, create_cmd)
    log.trace("sendCommand(): Terminal:", idx)
    local term_handle = find_terminal(idx, create_cmd)

    if type(cmd) == "number" then
        cmd = harpoon.get_term_config().cmds[cmd]
    end
    if type(cmd) == "string" then
        cmd = {cmd}
    end

    if cmd then
        log.debug("sendCommand:", cmd[1])
        vim.fn.chansend(term_handle.term_id, string.format(unpack(cmd)))
    end
end

return M
