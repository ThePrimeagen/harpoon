---@class HarpoonExtensions
---@field listeners HarpoonExtension[]
local HarpoonExtensions = {}

---@class HarpoonExtension
---@field ADD? fun(...): nil
---@field SELECT? fun(...): nil
---@field REMOVE? fun(...): nil
---@field REORDER? fun(...): nil
---@field UI_CREATE? fun(...): nil
---@field SETUP_CALLED? fun(...): nil
---@field LIST_CREATED? fun(...): nil
---@field LIST_READ? fun(...): nil
---@field NAVIGATE? fun(...): nil

HarpoonExtensions.__index = HarpoonExtensions

function HarpoonExtensions:new()
    return setmetatable({
        listeners = {},
    }, self)
end

---@param extension HarpoonExtension
function HarpoonExtensions:add_listener(extension)
    table.insert(self.listeners, extension)
end

function HarpoonExtensions:clear_listeners()
    self.listeners = {}
end

---@param type string
---@param ... any
function HarpoonExtensions:emit(type, ...)
    for _, cb in ipairs(self.listeners) do
        if cb[type] then
            cb[type](...)
        end
    end
end

local extensions = HarpoonExtensions:new()
local Builtins = {}

function Builtins.command_on_nav(cmd)
    return {
        NAVIGATE = function()
            vim.cmd(cmd)
        end,
    }
end

function Builtins.navigate_with_number()
    return {
        UI_CREATE = function(cx)
            for i = 1, 9 do
                vim.keymap.set("n", "" .. i, function()
                    require("harpoon"):list():select(i)
                end, { buffer = cx.bufnr })
            end
        end,
    }
end

return {
    builtins = Builtins,
    extensions = extensions,
    event_names = {
        ADD = "ADD",
        SELECT = "SELECT",
        REMOVE = "REMOVE",
        REORDER = "REORDER",
        UI_CREATE = "UI_CREATE",
        SETUP_CALLED = "SETUP_CALLED",
        LIST_CREATED = "LIST_CREATED",
        NAVIGATE = "NAVIGATE",
        LIST_READ = "LIST_READ",
    },
}
