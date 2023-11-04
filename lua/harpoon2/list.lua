local function index_of(items, element, config)
    local equals = config and config.equals or function(a, b) return a == b end
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
--- @field items HarpoonItem[]
local HarpoonList = {}

HarpoonList.__index = HarpoonList
function HarpoonList:new(config, name, items)
    return setmetatable({
        items = items,
        config = config,
        name = name,
    }, self)
end

---@return HarpoonList
function HarpoonList:append(item)
    item = item or self.config.add()

    local index = index_of(self.items, item, self.config)
    if index == -1 then
        table.insert(self.items, item)
    end

    return self
end

---@return HarpoonList
function HarpoonList:prepend(item)
    item = item or self.config.add()
    local index = index_of(self.items, item, self.config)
    if index == -1 then
        table.insert(self.items, 1, item)
    end

    return self
end

---@return HarpoonList
function HarpoonList:remove(item)
    for i, v in ipairs(self.items) do
        if self.config.equals(v, item) then
            table.remove(self.items, i)
            break
        end
    end
    return self
end

---@return HarpoonList
function HarpoonList:removeAt(index)
    table.remove(self.items, index)
    return self
end

function HarpoonList:get(index)
    return self.items[index]
end

--- much inefficiencies.  dun care
---@param displayed string[]
function HarpoonList:resolve_displayed(displayed)
    local new_list = {}

    local list_displayed = self:display()
    for i, v in ipairs(displayed) do
        local index = index_of(list_displayed, v)
        if index == -1 then
            table.insert(new_list, self.config.add(v))
        else
            local index_in_new_list = index_of(new_list, self.items[index], self.config)
            if index_in_new_list == -1 then
                table.insert(new_list, self.items[index])
            end
        end

    end

    self.items = new_list
end

function HarpoonList:select(index, options)
    local item = self.items[index]
    if item then
        self.config.select(item, options)
    end
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

