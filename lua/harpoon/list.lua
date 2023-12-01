local Listeners = require("harpoon.listeners")

local function index_of(items, element, config)
    local equals = config and config.equals
        or function(a, b)
            return a == b
        end
    local index = -1
    for i, item in ipairs(items) do
        if equals(element, item) then
            index = i
            break
        end
    end

    return index
end

--- @class HarpoonItem
--- @field value string
--- @field context any

--- @class HarpoonList
--- @field config HarpoonPartialConfigItem
--- @field name string
--- @field _index number
--- @field items HarpoonItem[]
local HarpoonList = {}

HarpoonList.__index = HarpoonList
function HarpoonList:new(config, name, items)
    return setmetatable({
        items = items,
        config = config,
        name = name,
        _index = 1,
    }, self)
end

---@return number
function HarpoonList:length()
    return #self.items
end

function HarpoonList:clear()
    self.items = {}
end

---@return HarpoonList
function HarpoonList:append(item)
    item = item or self.config.add(self.config)

    local index = index_of(self.items, item, self.config)
    if index == -1 then
        Listeners.listeners:emit(
            Listeners.event_names.ADD,
            { list = self, item = item, idx = #self.items + 1 }
        )
        table.insert(self.items, item)
    end

    return self
end

---@return HarpoonList
function HarpoonList:prepend(item)
    item = item or self.config.add(self.config)
    local index = index_of(self.items, item, self.config)
    if index == -1 then
        Listeners.listeners:emit(
            Listeners.event_names.ADD,
            { list = self, item = item, idx = 1 }
        )
        table.insert(self.items, 1, item)
    end

    return self
end

---@return HarpoonList
function HarpoonList:remove(item)
    item = item or self.config.add(self.config)
    for i, v in ipairs(self.items) do
        if self.config.equals(v, item) then
            Listeners.listeners:emit(
                Listeners.event_names.REMOVE,
                { list = self, item = item, idx = i }
            )
            table.remove(self.items, i)
            break
        end
    end
    return self
end

---@return HarpoonList
function HarpoonList:removeAt(index)
    Listeners.listeners:emit(
        Listeners.event_names.REMOVE,
        { list = self, item = self.items[index], idx = index }
    )
    table.remove(self.items, index)
    return self
end

function HarpoonList:get(index)
    return self.items[index]
end

function HarpoonList:get_by_display(name)
    local displayed = self:display()
    local index = index_of(displayed, name)
    if index == -1 then
        return nil
    end
    return self.items[index]
end

--- much inefficiencies.  dun care
---@param displayed string[]
function HarpoonList:resolve_displayed(displayed)
    local new_list = {}

    local list_displayed = self:display()

    for i, v in ipairs(list_displayed) do
        local index = index_of(list_displayed, v)
        if index == -1 then
            Listeners.listeners:emit(
                Listeners.event_names.REMOVE,
                { list = self, item = v, idx = i }
            )
        end
    end

    for i, v in ipairs(displayed) do
        local index = index_of(list_displayed, v)
        if index == -1 then
            Listeners.listeners:emit(
                Listeners.event_names.ADD,
                { list = self, item = v, idx = i }
            )
            new_list[i] = self.config.add(self.config, v)
        else
            local index_in_new_list =
                index_of(new_list, self.items[index], self.config)
            if index_in_new_list == -1 then
                new_list[i] = self.items[index]
            end
        end
    end

    self.items = new_list
end

function HarpoonList:select(index, options)
    local item = self.items[index]
    if item or self.config.select_with_nil then
        Listeners.listeners:emit(
            Listeners.event_names.SELECT,
            { list = self, item = item, idx = index }
        )
        self.config.select(item, self, options)
    end
end

function HarpoonList:next()
    self._index = self._index + 1
    if self._index > #self.items then
        self._index = 1
    end

    self:select(self._index)
end

function HarpoonList:prev()
    self._index = self._index - 1
    if self._index < 1 then
        self._index = #self.items
    end

    self:select(self._index)
end

--- @return string[]
function HarpoonList:display()
    local out = {}
    for _, v in ipairs(self.items) do
        table.insert(out, self.config.display(v))
    end

    return out
end

--- @return string[]
function HarpoonList:encode()
    local out = {}
    for _, v in ipairs(self.items) do
        table.insert(out, self.config.encode(v))
    end

    return out
end

--- @return HarpoonList
--- @param list_config HarpoonPartialConfigItem
--- @param name string
--- @param items string[]
function HarpoonList.decode(list_config, name, items)
    local list_items = {}

    for _, item in ipairs(items) do
        table.insert(list_items, list_config.decode(item))
    end

    return HarpoonList:new(list_config, name, list_items)
end

return HarpoonList
