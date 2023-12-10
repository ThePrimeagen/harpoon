local utils = require("harpoon.utils")

---@class HarpoonLog
---@field lines string[]
---@field max_lines number
---@field enabled boolean not used yet, but if we get reports of slow, we will use this
local HarpoonLog = {}

HarpoonLog.__index = HarpoonLog

---@return HarpoonLog
function HarpoonLog:new()
    local logger = setmetatable({
        lines = {},
        enabled = true,
        max_lines = 50,
    }, self)

    return logger
end

function HarpoonLog:disable()
    self.enabled = false
end

function HarpoonLog:enable()
    self.enabled = true
end

---@vararg any
function HarpoonLog:log(...)
    local processed = {}
    for i = 1, select("#", ...) do
        local item = select(i, ...)
        if type(item) == "table" then
            item = vim.inspect(item)
        end
        table.insert(processed, item)
    end

    local lines = {}
    for _, line in ipairs(processed) do
        local split = utils.split(line, "\n")
        for _, l in ipairs(split) do
            if not utils.is_white_space(l) then
                local ll = utils.trim(utils.remove_duplicate_whitespace(l))
                table.insert(lines, ll)
            end
        end
    end

    table.insert(self.lines, table.concat(lines, " "))

    while #self.lines > self.max_lines do
        table.remove(self.lines, 1)
    end
end

function HarpoonLog:clear()
    self.lines = {}
end

function HarpoonLog:show()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, self.lines)
    vim.api.nvim_win_set_buf(0, bufnr)
end

return HarpoonLog:new()
