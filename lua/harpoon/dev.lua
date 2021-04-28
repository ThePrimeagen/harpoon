-- Don't include this file, we should manually include it via
-- require("harpoon.dev").reload();
--
-- A quick mapping can be setup using something like:
-- :nmap <leader>rr :lua require("harpoon.dev").reload()<CR>
local M = {}

M.reload = function()
    require("plenary.reload").reload_module("harpoon")
end

local function set_log_level()
    local log_levels = { "trace", "debug", "info", "warning", "error", "fatal" }
    local log_level = vim.g.harpoon_log_level or vim.env.HARPOON_LOG

    for _, level in pairs(log_levels) do
        if level == log_level then
            return log_level
        end
    end

    return "warn" -- default, if user hasn't set to one from log_levels
end

M.log = require("plenary.log").new({
    plugin = "harpoon",
    level = set_log_level(),
})

return M
