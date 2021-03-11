local Path = require("plenary.path")
local cwd = vim.loop.cwd()
local data_path = vim.fn.stdpath("data")

local M = {
    cwd = cwd,
    data_path = data_path,
    normalize_path = function(item)
        return Path:new(item):make_relative(cwd)
    end
}

return M
