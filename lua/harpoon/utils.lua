local Path = require("plenary.path")
local data_path = vim.fn.stdpath("data")

local M = {
    data_path = data_path,
    normalize_path = function(item)
        return Path:new(item):make_relative(vim.loop.cwd())
    end
}

return M
