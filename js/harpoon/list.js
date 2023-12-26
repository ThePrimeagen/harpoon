local Logger = require("harpoon.logger")
local Extensions = require("harpoon.extensions")

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

function HarpoonList:length()
    return #self.items
end

function HarpoonList:clear()
    self.items = {}
end

function HarpoonList:append(item)
    item = item or self.config.create_list_item(self.config)

    local index = index_of(self.items, item, self.config)
    Logger:log("HarpoonList:append", { item = item, index = index })
    if index == -1 then
        Extensions.extensions:emit(
            Extensions.event_names.ADD,
            { list = self, item = item, idx = #self.items + 1 }
        )
        table.insert(self.items, item)
    end

    return self
end

function HarpoonList:prepend(item)
    item = item or self.config.create_list_item(self.config)
    local index = index_of(self.items, item, self.config)
    Logger:log("HarpoonList:prepend", { item = item, index = index })
    if index == -1 then
        Extensions.extensions:emit(
            Extensions.event_names.ADD,
            { list = self, item = item, idx = 1 }
        )
        table.insert(self.items, 1, item)
    end

    return self
end

function HarpoonList:remove(item)
    item = item or self.config.create_list_item(self.config)
    for i, v in ipairs(self.items) do
        if self.config.equals(v, item) then
            Extensions.extensions:emit(
                Extensions.event_names.REMOVE,
                { list = self, item = item, idx = i }
            )
            Logger:log("HarpoonList:remove", { item = item, index = i })
            table.remove(self.items, i)
            break
        end
    end
    return self
end

function HarpoonList:removeAt(index)
    if self.items[index] then
        Logger:log(
            "HarpoonList:removeAt",
            { item = self.items[index], index = index }
        )
        Extensions.extensions:emit(
            Extensions.event_names.REMOVE,
            { list = self, item = self.items[index], idx = index }
        )
        table.remove(self.items, index)
    end
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
function HarpoonList:resolve_displayed(displayed)
    local new_list = {}

    local list_displayed = self:display()

    for i, v in ipairs(list_displayed) do
        local index = index_of(displayed, v)
        if index == -1 then
            Extensions.extensions:emit(
                Extensions.event_names.REMOVE,
                { list = self, item = self.items[i], idx = i }
            )
        end
    end

    for i, v in ipairs(displayed) do
        local index = index_of(list_displayed, v)
        if index == -1 then
            new_list[i] = self.config.create_list_item(self.config, v)
            Extensions.extensions:emit(
                Extensions.event_names.ADD,
                { list = self, item = new_list[i], idx = i }
            )
        else
            if index ~= i then
                Extensions.extensions:emit(
                    Extensions.event_names.REORDER,
                    { list = self, item = self.items[index], idx = i }
                )
            end
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
        Extensions.extensions:emit(
            Extensions.event_names.SELECT,
            { list = self, item = item, idx = index }
        )
        self.config.select(item, self, options)
    end
end

---
function HarpoonList:next(opts)
    opts = opts or {}

    self._index = self._index + 1
    if self._index > #self.items then
        if opts.ui_nav_wrap then
            self._index = 1
        else
            self._index = #self.items
        end
    end

    self:select(self._index)
end

---
function HarpoonList:prev(opts)
    opts = opts or {}

    self._index = self._index - 1
    if self._index < 1 then
        if opts.ui_nav_wrap then
            self._index = #self.items
        else
            self._index = 1
        end
    end

    self:select(self._index)
end

function HarpoonList:display()
    local out = {}
    for _, v in ipairs(self.items) do
        table.insert(out, self.config.display(v))
    end

    return out
end

function HarpoonList:encode()
    local out = {}
    for _, v in ipairs(self.items) do
        table.insert(out, self.config.encode(v))
    end

    return out
end


function HarpoonList.decode(list_config, name, items)
    local list_items = {}

    for _, item in ipairs(items) do
        table.insert(list_items, list_config.decode(item))
    end

    return HarpoonList:new(list_config, name, list_items)
end

return HarpoonList
