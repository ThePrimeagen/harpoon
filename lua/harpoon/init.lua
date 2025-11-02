local Log = require("harpoon.logger")
local Ui = require("harpoon.ui")
local Data = require("harpoon.data")
local Config = require("harpoon.config")
local List = require("harpoon.list")
local Extensions = require("harpoon.extensions")
local HarpoonGroup = require("harpoon.autocmd")

---@class Harpoon
---@field config HarpoonConfig
---@field ui HarpoonUI
---@field _extensions HarpoonExtensions
---@field data HarpoonData
---@field logger HarpoonLog
---@field lists {[string]: {[string]: HarpoonList}}
---@field hooks_setup boolean
local Harpoon = {}

Harpoon.__index = Harpoon

---@param harpoon Harpoon
local function sync_on_change(harpoon)
    local function sync(_)
        return function()
            harpoon:sync()
        end
    end

    Extensions.extensions:add_listener({
        ADD = sync("ADD"),
        REMOVE = sync("REMOVE"),
        REORDER = sync("REORDER"),
        LIST_CHANGE = sync("LIST_CHANGE"),
        POSITION_UPDATED = sync("POSITION_UPDATED"),
    })
end

---@return Harpoon
function Harpoon:new()
    local config = Config.get_default_config()

    local harpoon = setmetatable({
        config = config,
        data = Data.Data:new(config),
        logger = Log,
        ui = Ui:new(config.settings),
        _extensions = Extensions.extensions,
        lists = {},
        hooks_setup = false,
    }, self)
    sync_on_change(harpoon)

    return harpoon
end

---@param name string?
---@return HarpoonList
function Harpoon:list(name)
    name = name or Config.DEFAULT_LIST

    local key = self.config.settings.key()
    local lists = self.lists[key]

    if not lists then
        lists = {}
        self.lists[key] = lists
    end

    local existing_list = lists[name]

    if existing_list then
        self._extensions:emit(Extensions.event_names.LIST_READ, existing_list)
        return existing_list
    end

    local data = self.data:data(key, name)
    local list_config = Config.get_config(self.config, name)

    local list = List.decode(list_config, name, data)
    self._extensions:emit(Extensions.event_names.LIST_CREATED, list)
    lists[name] = list

    return list
end

---@param cb fun(list: HarpoonList, config: HarpoonPartialConfigItem, name: string)
function Harpoon:_for_each_list(cb)
    local key = self.config.settings.key()
    local lists = self.lists[key]
    if not lists then
        return
    end

    for name, list in pairs(lists) do
        local list_config = Config.get_config(self.config, name)
        cb(list, list_config, name)
    end
end

function Harpoon:sync()
    local key = self.config.settings.key()
    self:_for_each_list(function(list, _, list_name)
        if list.config.encode == false then
            return
        end

        local encoded = list:encode()
        self.data:update(key, list_name, encoded)
    end)
    self.data:sync()
end

--luacheck: ignore 212/self
function Harpoon:info()
    return {
        paths = Data.info(),
        default_list_name = Config.DEFAULT_LIST,
    }
end

--- PLEASE DONT USE THIS OR YOU WILL BE FIRED
function Harpoon:dump()
    return self.data._data
end

---@param extension HarpoonExtension
function Harpoon:extend(extension)
    self._extensions:add_listener(extension)
end

function Harpoon:__debug_reset()
    require("plenary.reload").reload_module("harpoon")
end

local the_harpoon = Harpoon:new()

---@param self Harpoon
---@param partial_config HarpoonPartialConfig?
---@return Harpoon
function Harpoon.setup(self, partial_config)
    if self ~= the_harpoon then
        ---@diagnostic disable-next-line: cast-local-type
        partial_config = self
        self = the_harpoon
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    self.config = Config.merge_config(partial_config, self.config)
    self.data = Data.Data:new(self.config)
    self.ui:configure(self.config.settings)
    self._extensions:emit(Extensions.event_names.SETUP_CALLED, self.config)

    ---TODO: should we go through every seen list and update its config?

    if self.hooks_setup == false then
        vim.api.nvim_create_autocmd({ "BufLeave", "VimLeavePre" }, {
            group = HarpoonGroup,
            pattern = "*",
            callback = function(ev)
                self:_for_each_list(function(list, config)
                    local fn = config[ev.event]
                    if fn ~= nil then
                        fn(ev, list)
                    end

                    if ev.event == "VimLeavePre" then
                        self:sync()
                    end
                end)
            end,
        })

        self.hooks_setup = true
    end

    sync_on_change(self)
    return self
end

return the_harpoon
