local harpoon = require('harpoon')

local M = {}
local terminals = {}

local function create_terminal()
    local current_id = vim.fn.bufnr()

    vim.cmd(":terminal")
    local buf_id = vim.fn.bufnr()
    local term_id  = vim.b.terminal_job_id

    if term_id == nil then
        -- TODO: Throw an erro?
        return nil
    end

    -- Make sure the term buffer has "hidden" set so it doesn't get thrown
    -- away and cause an error
    vim.api.nvim_buf_set_option(bufh, 'bufhidden', 'hide')

    -- Resets the buffer back to the old one
    vim.api.nvim_set_current_buf(current_id)
    return buf_id, term_id
end

local function process_wildcards(cmd)
    local wc = harpoon.get_wildcard()
    if wc == nil then
        return cmd
    end

    local cmd_parts = string.gmatch(cmd, "{}")
    if #cmd_parts == 1 then
        return cmd
    end

    local new_cmd = cmd[1]
    for idx = 2, #cmd_parts do
        new_cmd = new_cmd .. wc .. cmd_parts[idx]
    end
    return new_cmd
end

local function find_terminal(idx)
    local term_handle = terminals[idx]
    if not term_handle or not vim.api.nvim_buf_is_valid(term_handle.buf_id) then
        local buf_id, term_id = create_terminal()
        if buf_id == nil then
            return
        end

        term_handle = {
            buf_id = buf_id,
            term_id = term_id
        }
        terminals[idx] = term_handle
    end
    return term_handle
end

M.gotoTerminal = function(idx)
    local term_handle = find_terminal(idx)

    vim.api.nvim_set_current_buf(term_handle.buf_id)
end

M.sendCommand = function(idx, cmd)
    local term_handle = find_terminal(idx)

    if type(cmd) == "number" then
        cmd = harpoon.get_term_config().cmds[cmd]
    end

    cmd = process_wildcards(cmd)

    if cmd then
        vim.fn.chansend(term_handle.term_id, cmd)
    end
end

return M
