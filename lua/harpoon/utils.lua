local Path = require("plenary.path")
local data_path = vim.fn.stdpath("data")
local Job = require("plenary.job")

local M = {}

M.data_path = data_path

function M.project_key()
    return vim.loop.cwd()
end

function M.branch_key()
    -- `git branch --show-current` requires Git v2.22.0+ so going with more
    -- widely available command
    local branch = M.get_os_command_output({
        "git",
        "rev-parse",
        "--abbrev-ref",
        "HEAD",
    })[1]

    if branch then
        return vim.loop.cwd() .. "-" .. branch
    else
        return M.project_key()
    end
end

function M.normalize_path(item, relative_path)
    if relative_path then
        return Path:new(item):make_relative(relative_path)
    else
        return Path:new(item):make_relative(M.project_key())
    end
end

function M.get_os_command_output(cmd, cwd)
    if type(cmd) ~= "table" then
        print("Harpoon: [get_os_command_output]: cmd has to be a table")
        return {}
    end
    local command = table.remove(cmd, 1)
    local stderr = {}
    local stdout, ret = Job
        :new({
            command = command,
            args = cmd,
            cwd = cwd,
            on_stderr = function(_, data)
                table.insert(stderr, data)
            end,
        })
        :sync()
    return stdout, ret, stderr
end

function M.split_string(str, delimiter)
    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

function M.is_white_space(str)
    return str:gsub("%s", "") == ""
end

return M
