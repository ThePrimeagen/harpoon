local Path = require("plenary.path")
local data_path = vim.fn.stdpath("data")
local Job = require("plenary.job")

local M = {}

local project_key = vim.loop.cwd()
M.project_key = project_key
M.branch_key = vim.loop.cwd()
M.data_path = data_path

function M.mark_config_key()
    return string.gsub(vim.loop.cwd() .. '-' .. vim.fn.system('git branch --show-current'), "\n", "")
end

function M.normalize_path(item)
    return Path:new(item):make_relative(M.branch_key)
end

function M.get_os_command_output(cmd, cwd)
    if type(cmd) ~= "table" then
        print("Harpoon: [get_os_command_output]: cmd has to be a table")
        return {}
    end
    local command = table.remove(cmd, 1)
    local stderr = {}
    local stdout, ret = Job:new({
        command = command,
        args = cmd,
        cwd = cwd,
        on_stderr = function(_, data)
            table.insert(stderr, data)
        end
    }):sync()
    return stdout, ret, stderr
end

function M.split_string(str, delimiter)
    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do table.insert(result, match) end
    return result
end

function M.is_white_space(str)
    return str:gsub("%s", "") == ""
end

return M
