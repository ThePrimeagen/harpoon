local Path = require("plenary.path")
local data_path = vim.fn.stdpath("data")
local Job = require("plenary.job")

local M = {
    data_path = data_path,
    normalize_path = function(item)
        return Path:new(item):make_relative(vim.loop.cwd())
    end,
    get_os_command_output = function(cmd, cwd)
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
    end,
    split_string = function(str, delimiter)
        local result = {}

        for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
            table.insert(result, match)
        end

        return result
    end,
}

return M
