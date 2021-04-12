local Path = require("plenary.path")
local config_path = vim.fn.stdpath("config")
local data_path = vim.fn.stdpath("data")
local utils = require("harpoon.utils")
local user_config = string.format("%s/harpoon.json", config_path)
local cache_config = string.format("%s/harpoon.json", data_path)

local M = {}

local function to_array(line, sep)
    local arr = {}
    local idx = 1
end

-- Directly taken from Stack overflow like a real man
local function split_str(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

local function get_project_config(config)
    local projs = config.projects
    local cwd = vim.loop.cwd()
    local cwd_parts = split_str(cwd, Path.path.sep)

    for k, v in pairs(projs) do
        local start = string.find(k, "{}", 1, true)

        if start == nil and k == cwd then
            return projs[k], k
        end

        local k_parts = split_str(k, Path.path.sep)

        if k_parts and #k_parts == #cwd_parts then
            local found = true
            local wildcard = nil
            for idx = 1, #k_parts do
                local k_part = k_parts[idx]
                found = found and (k_part == "{}" or k_part == cwd_parts[idx])

                if k_part == "{}" then
                    wildcard = cwd_parts[idx]
                end
            end

            if found then
                return projs[k], k, wildcard
            end
        end
    end

    return nil, nil
end

--[[
{
    projects = {
        ["/path/to/other/{}"] = {
            // TODO: pattern matching
        }
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
    menu = {
        // TODO: Be filled in on settings...
        // WE should also consider just having a help doc
    }
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
    local projects, cwd, wildcard = get_project_config(config)

    cwd = cwd or vim.loop.cwd
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
    proj.wildcard = wildcard
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

    return config
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

    -- There was this issue where the vim.loop.cwd() didn't have marks or term, but had
    -- an object for vim.loop.cwd()
    ensure_correct_config(complete_config)

    HarpoonConfig = complete_config
end

M.get_term_config = function()
    return ensure_correct_config(HarpoonConfig).projects[vim.loop.cwd()].term
end

M.get_wildcard = function()
    return ensure_correct_config(HarpoonConfig).projects.wildcard
end

M.get_mark_config = function()
    return ensure_correct_config(HarpoonConfig).projects[vim.loop.cwd()].mark
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

