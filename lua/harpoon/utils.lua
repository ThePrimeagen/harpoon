local cwd = cwd or vim.loop.cwd()
local data_path = vim.fn.stdpath("data")

local M = {
    cwd = cwd,
    data_path,
}

