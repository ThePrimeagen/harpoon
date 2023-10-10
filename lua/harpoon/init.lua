local Path = require("plenary.path")
local utils = require("harpoon.utils")
local Dev = require("harpoon.dev")
local log = Dev.log

local config_path = vim.fn.stdpath("config")
local data_path = vim.fn.stdpath("data")
local user_config = string.format("%s/harpoon.json", config_path)
local cache_config = string.format("%s/harpoon.json", data_path)

local M = {}

local the_primeagen_harpoon = vim.api.nvim_create_augroup(
    "THE_PRIMEAGEN_HARPOON",
    { clear = true }
)

vim.api.nvim_create_autocmd({ "BufLeave", "VimLeave" }, {
    callback = function()
        require("harpoon.mark").store_offset()
    end,
    group = the_primeagen_harpoon,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "harpoon",
    group = the_primeagen_harpoon,

    callback = function()
        -- Open harpoon file choice in useful ways
        --
        -- vertical split (control+v)
        vim.keymap.set("n", "<C-V>", function()
            local curline = vim.api.nvim_get_current_line()
            local working_directory = vim.fn.getcwd() .. "/"
            vim.cmd("vs")
            vim.cmd("e " .. working_directory .. curline)
        end, { buffer = true, noremap = true, silent = true })

        -- horizontal split (control+x)
        vim.keymap.set("n", "<C-x>", function()
            local curline = vim.api.nvim_get_current_line()
            local working_directory = vim.fn.getcwd() .. "/"
            vim.cmd("sp")
            vim.cmd("e " .. working_directory .. curline)
        end, { buffer = true, noremap = true, silent = true })

        -- new tab (control+t)
        vim.keymap.set("n", "<C-t>", function()
            local curline = vim.api.nvim_get_current_line()
            local working_directory = vim.fn.getcwd() .. "/"
            vim.cmd("tabnew")
            vim.cmd("e " .. working_directory .. curline)
        end, { buffer = true, noremap = true, silent = true })
    end,
})
--[[
{
    projects = {
        ["/path/to/director"] = {
            term = {
                cmds = {
                }
                ... is there anything that could be options?
            },
            mark = {
                marks = {
                }
                ... is there anything that could be options?
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

local function mark_config_key(global_settings)
    global_settings = global_settings or M.get_global_settings()
    if global_settings.mark_branch then
        return utils.branch_key()
    else
        return utils.project_key()
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
    local mark_key = mark_config_key(config.global_settings)
    if projects[mark_key] == nil then
        log.debug("ensure_correct_config(): No config found for:", mark_key)
        projects[mark_key] = {
            mark = { marks = {} },
            term = {
                cmds = {},
            },
        }
    end

    local proj = projects[mark_key]
    if proj.mark == nil then
        log.debug("ensure_correct_config(): No marks found for", mark_key)
        proj.mark = { marks = {} }
    end

    if proj.term == nil then
        log.debug(
            "ensure_correct_config(): No terminal commands found for",
            mark_key
        )
        proj.term = { cmds = {} }
    end

    local marks = proj.mark.marks

    for idx, mark in pairs(marks) do
        if type(mark) == "string" then
            mark = { filename = mark }
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

function M.save()
    -- first refresh from disk everything but our project
    M.refresh_projects_b4update()

    log.trace("save(): Saving cache config to", cache_config)
    Path:new(cache_config):write(vim.fn.json_encode(HarpoonConfig), "w")
end

local function read_config(local_config)
    log.trace("_read_config():", local_config)
    return vim.json.decode(Path:new(local_config):read())
end

-- 1. saved.  Where do we save?
function M.setup(config)
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
            ["enter_on_sendcmd"] = false,
            ["tmux_autoclose_windows"] = false,
            ["excluded_filetypes"] = { "harpoon" },
            ["mark_branch"] = false,
            ["tabline"] = false,
            ["tabline_suffix"] = "   ",
            ["tabline_prefix"] = "   ",
        },
    }, expand_dir(c_config), expand_dir(u_config), expand_dir(config))

    -- There was this issue where the vim.loop.cwd() didn't have marks or term, but had
    -- an object for vim.loop.cwd()
    ensure_correct_config(complete_config)

    if complete_config.tabline then
        require("harpoon.tabline").setup(complete_config)
    end

    HarpoonConfig = complete_config

    log.debug("setup(): Complete config", HarpoonConfig)
    log.trace("setup(): log_key", Dev.get_log_key())
end

function M.get_global_settings()
    log.trace("get_global_settings()")
    return HarpoonConfig.global_settings
end

-- refresh all projects from disk, except our current one
function M.refresh_projects_b4update()
    log.trace(
        "refresh_projects_b4update(): refreshing other projects",
        cache_config
    )
    -- save current runtime version of our project config for merging back in later
    local cwd = mark_config_key()
    local current_p_config = {
        projects = {
            [cwd] = ensure_correct_config(HarpoonConfig).projects[cwd],
        },
    }

    -- erase all projects from global config, will be loaded back from disk
    HarpoonConfig.projects = nil

    -- this reads a stale version of our project but up-to-date versions
    -- of all other projects
    local ok2, c_config = pcall(read_config, cache_config)

    if not ok2 then
        log.debug(
            "refresh_projects_b4update(): No cache config present at",
            cache_config
        )
        c_config = { projects = {} }
    end
    -- don't override non-project config in HarpoonConfig later
    c_config = { projects = c_config.projects }

    -- erase our own project, will be merged in from current_p_config later
    c_config.projects[cwd] = nil

    local complete_config = merge_tables(
        HarpoonConfig,
        expand_dir(c_config),
        expand_dir(current_p_config)
    )

    -- There was this issue where the vim.loop.cwd() didn't have marks or term, but had
    -- an object for vim.loop.cwd()
    ensure_correct_config(complete_config)

    HarpoonConfig = complete_config
    log.debug("refresh_projects_b4update(): Complete config", HarpoonConfig)
    log.trace("refresh_projects_b4update(): log_key", Dev.get_log_key())
end

function M.get_term_config()
    log.trace("get_term_config()")
    return ensure_correct_config(HarpoonConfig).projects[utils.project_key()].term
end

function M.get_mark_config()
    log.trace("get_mark_config()")
    return ensure_correct_config(HarpoonConfig).projects[mark_config_key()].mark
end

function M.get_menu_config()
    log.trace("get_menu_config()")
    return HarpoonConfig.menu or {}
end

-- should only be called for debug purposes
function M.print_config()
    print(vim.inspect(HarpoonConfig))
end

-- Sets a default config with no values
M.setup()

return M
