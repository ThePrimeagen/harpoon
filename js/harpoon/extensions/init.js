--- TODO: Rename this... its an odd name "listeners"


local HarpoonExtensions = {}



HarpoonExtensions.__index = HarpoonExtensions

function HarpoonExtensions:new()
    return setmetatable({
        listeners = {},
    }, self)
end

function HarpoonExtensions:add_listener(extension)
    table.insert(self.listeners, extension)
end

function HarpoonExtensions:clear_listeners()
    self.listeners = {}
end

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
    },
}
