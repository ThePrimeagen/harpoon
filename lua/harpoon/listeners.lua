---@alias HarpoonListener fun(type: string, args: any[] | any | nil): nil

--- TODO: Rename this... its an odd name "listeners"

---@class HarpoonListeners
---@field listeners table<HarpoonListener, HarpoonListener>
---@field listenersByType table<string, table<HarpoonListener, HarpoonListener>>
local HarpoonListeners = {}

HarpoonListeners.__index = HarpoonListeners

function HarpoonListeners:new()
    return setmetatable({
        listeners = {},
        listenersByType = {},
    }, self)
end

function HarpoonListeners:remove_listener(fn)
    if self.listeners[fn] then
        self.listeners[fn] = nil
    end
    for _, listeners in pairs(self.listenersByType) do
        if listeners[fn] then
            listeners[fn] = nil
        end
    end
end

---@param cbOrType HarpoonListener | string
---@param cbOrNil HarpoonListener | string | nil
function HarpoonListeners:add_listener(cbOrType, cbOrNil)
    if type(cbOrType) == "string" then
        if not cbOrNil then
            return
        end
        if not self.listenersByType[cbOrType] then
            self.listenersByType[cbOrType] = {}
        end
        self.listenersByType[cbOrType][cbOrNil] = cbOrNil
    else
        self.listeners[cbOrType] = cbOrType
    end
end

function HarpoonListeners:clear_listeners()
    self.listeners = {}
end

---@param type string
---@param args any[] | any | nil
function HarpoonListeners:emit(type, args)
    for _, cb in pairs(self.listeners) do
        cb(type, args)
    end

    local listeners = self.listenersByType[type]
    if listeners ~= nil then
        for _, cb in pairs(listeners) do
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
        REORDER = "REORDER",
        UI_CREATE = "UI_CREATE",
    },
}
