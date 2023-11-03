local Data = require("harpoon.data")
local Config = require("harpoon.config")

-- setup
-- read from a config file
--

local DEFAULT_LIST = "__harpoon_files"

---@class Harpoon
---@field config HarpoonConfig
---@field data Data
local Harpoon = {}

Harpoon.__index = Harpoon

---@return Harpoon
function Harpoon:new()
    local config = Config.get_default_config()

    return setmetatable({
        config = config,
        data = Data:new()
    }, self)
end

---@param partial_config HarpoonPartialConfig
---@return Harpoon
function Harpoon:setup(partial_config)
    self.config = Config.merge_config(partial_config, self.config)
    return self
end

---@param list string?
---@return HarpoonList
function Harpoon:list(name)
    name = name or DEFAULT_LIST
end

return Harpoon:new()

