---@class HarpoonLog
---@field lines string[]
local HarpoonLog = {}

HarpoonLog.__index = HarpoonLog

---@return HarpoonLog
function HarpoonLog:new()
    local logger = setmetatable({
        lines = {},
    }, self)

    return logger
end

---@vararg any
function HarpoonLog:log(...)
    local msg = {}
    for i = 1, select("#", ...) do
        local item = select(i, ...)
        table.insert(msg, vim.inspect(item))
    end

    table.insert(self.lines, table.concat(msg, " "))
end

function HarpoonLog:clear()
    self.lines = {}
end

function HarpoonLog:show()
    local bufnr = vim.api.nvim_create_buf(false, true)
    print(vim.inspect(self.lines))
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, self.lines)
    vim.api.nvim_win_set_buf(0, bufnr)
end

return HarpoonLog:new()
