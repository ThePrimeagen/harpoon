local Path = require("plenary.path")
local terminals = require("harpoon.term")
local mark = require("harpoon.mark")
local cwd = cwd or vim.loop.cwd()
local config_path = vim.fn.stdpath("config")
local data_path = vim.fn.stdpath("data")
local user_config = string.format("%s/harpoon.json", config_path)
local cache_config = string.format("%s/harpoon.json", data_path)

local M = {}

--[[
{
    projects = {
        ["/path/to/director"] = {
            term = {
                cmds = {
                }
                ... is there antyhnig that could be options?
            },
            mark = {
                marks = {
                }
                ... is there antyhnig that could be options?
            }
        }
    },
    ... high level settings
}
--]]
harpoon_config = harpoon_config or {}

function expand_dir(config) 
    local projects = config.projects or {}
    local expanded_config = {}
    for k in pairs(projects) do
        local expanded_path = Path.new(k):expand()
        projects[expanded_path] = projects[k]
    end

    return config
end

M.save = function()
    local term_config = terminals.get_config()
    local mark_config = mark.get_config()

    if not harpoon_config.projects[cwd] then
        harpoon_config.projects[cwd] = {}
    end

    harpoon_config.projects[cwd].term = term_config
    harpoon_config.projects[cwd].mark = mark_config

    Path:new(cache_config):write(vim.fn.json_encode(harpoon_config), 'w')
end

-- 1. saved.  Where do we save?
M.setup = function(config) 
    function read_config(config)
        return vim.fn.json_decode(Path:new(config):read())
    end

    if not config then
        config = {}
    end

    local ok, u_config = pcall(read_config, user_terminal_config)
    local ok2, c_config = pcall(read_config, cache_config)

    if not ok then
        u_config = {}
    end

    if not ok2 then
        c_config = {}
    end

    local complete_config = 
        vim.tbl_deep_extend("force", 
            {projects = {}}, 
            expand_dir(c_config), 
            expand_dir(u_config),
            expand_dir(config))

    terminals.setup(complete_config)
    mark.setup(complete_config)
    harpoon_config = complete_config
end

return M

