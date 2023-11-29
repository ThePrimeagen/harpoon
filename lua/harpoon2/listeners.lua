---@alias HarpoonListener fun(type: string, args: any[] | any | nil): nil

---@class HarpoonListeners
---@field listeners (HarpoonListener)[]
---@field listenersByType (table<string, HarpoonListener>)[]
local HarpoonListeners = {}

HarpoonListeners.__index = HarpoonListeners

function HarpoonListeners:new()
    return setmetatable({
        listeners = {},
        listenersByType = {},
    }, self)
end

---@param cbOrType HarpoonListener | string
---@param cbOrNil HarpoonListener | string
function HarpoonListeners:add_listener(cbOrType, cbOrNil)
    if type(cbOrType) == "string" then
        if not self.listenersByType[cbOrType] then
            self.listenersByType[cbOrType] = {}
        end
        table.insert(self.listenersByType[cbOrType], cbOrNil)
    else
        table.insert(self.listeners, cbOrType)
    end
end

function HarpoonListeners:clear_listeners()
    self.listeners = {}
end

---@param type string
---@param args any[] | any | nil
function HarpoonListeners:emit(type, args)
    for _, cb in ipairs(self.listeners) do
        cb(type, args)
    end

    local listeners = self.listenersByType[type]
    if listeners ~= nil then
        for _, cb in ipairs(listeners) do
            cb(type, args)
        end
    end
end

return {
    listeners = HarpoonListeners:new(),
    event_names = {
        ADD = "ADD",
        SELECT = "SELECT",
        REMOVE = "REMOVE",
    },
}
