local terminals = require("harpoon.terminal")
local manage = require("harpoon.manage-a-mark")
local cwd = cwd or vim.loop.cwd()
local config_path = vim.fn.stdpath("config")
local terminal_config = string.format("%s/harpoon-terminal.json", config_path)

local M = {}

M.setup = function(config) 
    function read_terminal_config()
        return vim.fn.json_decode(Path:new(terminal_config):read())
    end

    -- TODO: Merge the configs instead of falling back
    if not config then
        local ok, res = pcall(read_terminal_config)
        if ok then
            config = res
        else
            config = {}
        end
    end

    terminals.setup(config)
    manage.setup(config)
end

return M

