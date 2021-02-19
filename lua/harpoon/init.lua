local terminals = require("harpoon.term")
local manage = require("harpoon.mark")
local cwd = cwd or vim.loop.cwd()
local config_path = vim.fn.stdpath("config")
local data_path = vim.fn.stdpath("data")
local user_terminal_config = string.format("%s/harpoon-terminal.json", config_path)
local cache_terminal_config = string.format("%s/harpoon-terminal.json", data_path)

local M = {}

function expand_dir(projects) 
    local expanded_config = {}
    for k in pairs(projects) do
        local expanded_path = Path.new(k):expand()
        projects[expanded_path] = projects[k]
    end
end

-- 1. saved.  Where do we save?
M.setup = function(config) 
    function read_terminal_config(config)
        return vim.fn.json_decode(Path:new(config):read())
    end

    if not config then
        config = {}
    end

    local ok, user_config = pcall(read_terminal_config, user_terminal_config)
    local ok2, cache_config = pcall(read_terminal_config, data_terminal_config)

    if not ok then
        user_config = {}
    end

    if not ok2 then
        cache_config = {}
    end

    local complete_config = 
        vim.tbl_deep_extend("force", {}, cache_config, user_config, config)

    terminals.setup(complete_config)
    manage.setup(complete_config)
end

return M

