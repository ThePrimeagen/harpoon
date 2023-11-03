local get_config = require "harpoon.config".get_config

-- TODO: Define the config object

--- @class Item
--- @field value string
--- @field context any

--- create a table object to be new'd
--- @class List
--- @field config any
--- @field name string
--- @field items Item[]
local List = {}

List.__index = List
function List:new(config, name, items)
    return setmetatable({
        items = items,
        config = config,
        name = name,
    }, self)
end

function List:push(item)
    table.insert(self.items, item)
end

function List:addToFront(item)
    table.insert(self.items, 1, item)
end

function List:remove(item)
    for i, v in ipairs(self.items) do
        if get_config(self.config, self.name)(v, item) then
            table.remove(self.items, i)
            break
        end
    end
end

function List:removeAt(index)
    table.remove(self.items, index)
end

function List:get(index)
    return self.items[index]
end

--- much inefficiencies.  dun care
---@param displayed string[]
function List:resolve_displayed(displayed)
    local not_found = {}
    local config = get_config(self.config, self.name)
    for _, v in ipairs(displayed) do
        local found = false
        for _, in_table in ipairs(self.items) do
            found = config.display(in_table, v)
            break
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
function List:display()
    local out = {}
    local config = get_config(self.config, self.name)
    for _, v in ipairs(self.items) do
        table.insert(out, config.display(v))
    end

    return out
end

--- @return string[]
function List:encode()
    local out = {}
    local config = get_config(self.config, self.name)
    for _, v in ipairs(self.items) do
        table.insert(out, config.encode(v))
    end

    return out
end

--- @return List
--- @param config HarpoonConfig
--- @param name string
--- @param items string[]
function List.decode(config, name, items)
    local list_items = {}
    local c = get_config(config, name)

    for _, item in ipairs(items) do
        table.insert(list_items, c.decode(item))
    end

    return List:new(config, name, list_items)
end


return List

