local function index_of(config, items, element)
    local index = -1
    for i, item in ipairs(items) do
        if config.equals(element, item) then
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

    local index = index_of(self.config, self.items, item)
    if index == -1 then
        table.insert(self.items, item)
    end

    return self
end

---@return HarpoonList
function HarpoonList:prepend(item)
    item = item or self.config.add()
    table.insert(self.items, 1, item)
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
    local not_found = {}

    for _, v in ipairs(displayed) do
        local found = false
        for _, in_table in ipairs(self.items) do
            if self.config.display(in_table) == v then
                found = true
                break
            end
        end

        if not found then
            table.insert(not_found, v)
        end
    end

    for _, v in ipairs(not_found) do
        self:remove(v)
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

