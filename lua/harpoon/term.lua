local Path = require("plenary.path")

local M = {}

terminal_config = terminal_config or { }
local terminals = {}

function create_terminal() 
    local current_id = vim.fn.bufnr()

    vim.cmd(":terminal")
    local buf_id = vim.fn.bufnr()
    local term_id  = vim.b.terminal_job_id

    if term_id == nil then
        -- TODO: Throw an erro?
        return nil
    end

    -- Resets the buffer back to the old one
    vim.api.nvim_set_current_buf(current_id)
    return buf_id, term_id
end

function getCmd(idx) 
    return 
end

M.gotoTerminal = function(idx) 
    local term_handle = terminals[idx]

    if not term_handle or nvim_is_buf_valid(term_handle.buf_id) then
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

    vim.api.nvim_set_current_buf(term_handle.buf_id)
end

M.sendCommand = function(idx, cmd) 
    local term_handle = terminals[idx]

    if not term_handle then
        M.gotoTerminal(idx)
        term_handle = terminals[idx]
    end

    if type(cmd) == "number" then
        cmd = terminal_config.cmds[cmd]
    end

    if cmd then
        vim.fn.chansend(term_handle.term_id, cmd)
    end
end

return M
