local Data = require("harpoon2.data")
local Config = require("harpoon2.config")
local List = require("harpoon2.list")

-- setup
-- read from a config file
--

local DEFAULT_LIST = "__harpoon_files"

---@class Harpoon
---@field config HarpoonConfig
---@field data HarpoonData
---@field lists HarpoonList[]
local Harpoon = {}

Harpoon.__index = Harpoon

---@return Harpoon
function Harpoon:new()
    local config = Config.get_default_config()

    return setmetatable({
        config = config,
        data = Data.Data:new(),
        lists = {},
    }, self)
end

---@param partial_config HarpoonPartialConfig
---@return Harpoon
function Harpoon:setup(partial_config)
    self.config = Config.merge_config(partial_config, self.config)
    return self
end

---@param name string?
---@return HarpoonList
function Harpoon:list(name)
    name = name or DEFAULT_LIST

    local existing_list = self.lists[name]

    if existing_list then
        return self.lists[name]
    end

    local data = self.data:data(name)
    local list_config = Config.get_config(self.config, name)

    local list = List.decode(list_config, name, data)
    self.lists[name] = list

    return list
end

function Harpoon:sync()
    for k, _ in pairs(self.data.seen) do
        local encoded = self.lists[k]:encode()
        self.data:update(k, encoded)
    end
    self.data:sync()
end

function Harpoon:setup_hooks()
    -- setup the autocommands
    -- vim exits sync data
    -- buf exit setup the cursor location
    error("I haven't implemented this yet")
end

function Harpoon:info()
    return {
        paths = Data.info(),
        default_key = DEFAULT_LIST,
    }
end

--- PLEASE DONT USE THIS OR YOU WILL BE FIRED
function Harpoon:dump()
    return self.data._data
end

return Harpoon:new()


