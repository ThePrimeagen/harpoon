local Path = require("plenary.path")
local cwd = cwd or vim.loop.cwd()

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

M.get_config = function() 
    return terminal_config
end

--[[
-- First iteration of the setup script
lua require("harpoon").setup({
    terminal: {
        "/home/theprimeagen/work/netflix": {
            "yarn build",
            "yarn test",
            "yarn dtest"
        }
    }
})
--]]

function getCmd(idx) 
    local commandSet = terminal_config[cwd]
    if not commandSet then
        return nil
    end
    return commandSet[idx]
end

--[[
{
    projects: {
        "/path/to/dir": {
            term: {
                cmds: string[],
                ... top level settings .. (we don't have)
            }
            mark: {
                marks: string[], // very skept -- has odd behavior
                ... top level settings .. (we don't have)
            }
        }
    }
}
--]]

M.setup = function(config) 
    terminal_config = config
    if terminal_config.cmds == nil then

        -- Resets terminal config if there is some missing values.
        --
        -- TODO: create a logging mechanism to get these values
        terminal_config = {
            cmds = {}
        }
    end
end

M.gotoTerminal = function(idx) 
    local term_handle = terminals[idx]

    if not term_handle then
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
        cmd = getCmd(cmd)
    end

    if cmd then
        vim.fn.chansend(term_handle.term_id, cmd)
    end
end

return M
