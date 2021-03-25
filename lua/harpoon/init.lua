local Path = require("plenary.path")
local cwd = vim.loop.cwd()
local config_path = vim.fn.stdpath("config")
local data_path = vim.fn.stdpath("data")
local utils = require("harpoon.utils")
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
HarpoonConfig = HarpoonConfig or {}

-- tbl_deep_extend does not work the way you would think
local function merge_table_impl(t1, t2)
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

local function merge_tables(...)
    local out = {}
    for i = 2, select("#",...) do
        merge_table_impl(out, select(i, ...))
    end
    return out
end

local function ensure_correct_config(config)
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

    local proj = projects[cwd]
    if proj.mark == nil then
        proj.mark = {marks = {}}
    end

    if proj.term == nil then
        proj.term = {cmds = {}}
    end

    local marks = proj.mark.marks
    for idx = 1, #marks do
        local mark = marks[idx]
        if type(mark) == "string" then
            mark = {
                filename = mark
            }
            marks[idx] = mark
        end

        marks[idx].filename = utils.normalize_path(mark.filename)
    end
end

local function expand_dir(config)
    local projects = config.projects or {}
    for k in pairs(projects) do
        local expanded_path = Path.new(k):expand()
        projects[expanded_path] = projects[k]
        if expanded_path ~= k then
            projects[k] = nil
        end
    end

    return config
end

M.save = function()
    Path:new(cache_config):write(vim.fn.json_encode(HarpoonConfig), 'w')
end

local function read_config(local_config)
    return vim.fn.json_decode(Path:new(local_config):read())
end

-- 1. saved.  Where do we save?
M.setup = function(config)

    if not config then
        config = {}
    end

    local ok, u_config = pcall(read_config, user_config)
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

    HarpoonConfig = complete_config
end

M.get_term_config = function()
    return HarpoonConfig.projects[cwd].term
end

M.get_mark_config = function()
    return HarpoonConfig.projects[cwd].mark
end

M.get_menu_config = function()
    return HarpoonConfig.menu or {}
end

-- should only be called for debug purposes
M.print_config = function()
    print(vim.inspect(HarpoonConfig))
end

-- Sets a default config with no values
M.setup({projects = {}})

return M

