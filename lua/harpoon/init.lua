local Path = require("plenary.path")
local utils = require("harpoon.utils")
local Dev = require("harpoon.dev")
local log = Dev.log

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
    log.trace("_merge_tables()")
    local out = {}
    for i = 1, select("#", ...) do
        merge_table_impl(out, select(i, ...))
    end
    return out
end

local function ensure_correct_config(config)
    log.trace("_ensure_correct_config()")
    local projects = config.projects
    if projects[vim.loop.cwd()] == nil then
        log.debug(
            "ensure_correct_config(): No config found for:",
            vim.loop.cwd()
        )
        projects[vim.loop.cwd()] = {
            mark = {
                marks = {},
            },
            term = {
                cmds = {},
            },
        }
    end

    local proj = projects[vim.loop.cwd()]
    if proj.mark == nil then
        log.debug("ensure_correct_config(): No marks found for", vim.loop.cwd())
        proj.mark = { marks = {} }
    end

    if proj.term == nil then
        log.debug(
            "ensure_correct_config(): No terminal commands found for",
            vim.loop.cwd()
        )
        proj.term = { cmds = {} }
    end

    local marks = proj.mark.marks
    for idx = 1, #marks do
        local mark = marks[idx]
        if type(mark) == "string" then
            mark = {
                filename = mark,
            }
            marks[idx] = mark
        end

        marks[idx].filename = utils.normalize_path(mark.filename)
    end

    return config
end

local function expand_dir(config)
    log.trace("_expand_dir(): Config pre-expansion:", config)

    local projects = config.projects or {}
    for k in pairs(projects) do
        local expanded_path = Path.new(k):expand()
        projects[expanded_path] = projects[k]
        if expanded_path ~= k then
            projects[k] = nil
        end
    end

    log.trace("_expand_dir(): Config post-expansion:", config)
    return config
end

M.save = function()
    log.trace("save(): Saving cache config to", cache_config)
    Path:new(cache_config):write(vim.fn.json_encode(HarpoonConfig), "w")
end

local function read_config(local_config)
    log.trace("_read_config():", local_config)
    return vim.fn.json_decode(Path:new(local_config):read())
end

-- 1. saved.  Where do we save?
M.setup = function(config)
    log.trace("setup(): Setting up...")

    if not config then
        config = {}
    end

    local ok, u_config = pcall(read_config, user_config)

    if not ok then
        log.debug("setup(): No user config present at", user_config)
        u_config = {}
    end

    local ok2, c_config = pcall(read_config, cache_config)

    if not ok2 then
        log.debug("setup(): No cache config present at", cache_config)
        c_config = {}
    end

    local complete_config = merge_tables({
        projects = {},
        global_settings = {
            ["save_on_toggle"] = false,
            ["save_on_change"] = true,
        },
    }, expand_dir(c_config), expand_dir(u_config), expand_dir(config))

    -- There was this issue where the vim.loop.cwd() didn't have marks or term, but had
    -- an object for vim.loop.cwd()
    ensure_correct_config(complete_config)

    HarpoonConfig = complete_config
    log.debug("setup(): Complete config", HarpoonConfig)
    log.trace("setup(): log_key", Dev.get_log_key())
end

M.get_global_settings = function()
    log.trace("get_global_settings()")
    return HarpoonConfig.global_settings
end

M.get_term_config = function()
    log.trace("get_term_config()")
    return ensure_correct_config(HarpoonConfig).projects[vim.loop.cwd()].term
end

M.get_mark_config = function()
    log.trace("get_mark_config()")
    return ensure_correct_config(HarpoonConfig).projects[vim.loop.cwd()].mark
end

M.get_menu_config = function()
    log.trace("get_menu_config()")
    return HarpoonConfig.menu or {}
end

-- should only be called for debug purposes
M.print_config = function()
    print(vim.inspect(HarpoonConfig))
end

-- Sets a default config with no values
M.setup()

return M
