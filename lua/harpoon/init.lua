local Path = require("plenary.path")
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

-- tbl_deep_extend does not work the way you would think
function merge_table_impl(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k]) == "table" then
                merge_table_impl(t1[k], v)
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
end

function merge_tables(...) 
    local out = {}
    for i = 2, select("#",...) do
        merge_table_impl(out, select(i, ...))
    end
    return out
end

function ensure_correct_config(config) 
    local projects = config.projects
    if projects[cwd] == nil then
        projects[cwd] = {
            mark = {
                marks = {}
            },
            term = {
                cmds = {}
            },
        }
    end

    if projects[cwd].mark == nil then
        projects[cwd].mark = {marks = {}}
    end

    if projects[cwd].term == nil then
        projects[cwd].term = {cmds = {}}
    end
end

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
        merge_tables(
            {projects = {}}, 
            expand_dir(c_config), 
            expand_dir(u_config),
            expand_dir(config))

    -- There was this issue where the cwd didn't have marks or term, but had
    -- an object for cwd
    ensure_correct_config(complete_config)

    harpoon_config = complete_config
end

M.get_term_config = function()
    ensure_correct_config(harpoon_config)
    return harpoon_config.projects[cwd].term
end

M.get_mark_config = function()
    ensure_correct_config(harpoon_config)
    return harpoon_config.projects[cwd].mark
end

-- should only be called for debug purposes
M.print_config = function() 
    print(vim.inspect(harpoon_config))
end

-- Sets a default config with no values
M.setup({projects = {}})

return M

