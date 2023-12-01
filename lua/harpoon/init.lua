local Ui = require("harpoon.ui")
local Data = require("harpoon.data")
local Config = require("harpoon.config")
local List = require("harpoon.list")
local Listeners = require("harpoon.listeners")
local HarpoonGroup = require("harpoon.autocmd")

---@class Harpoon
---@field config HarpoonConfig
---@field ui HarpoonUI
---@field listeners HarpoonListeners
---@field data HarpoonData
---@field lists {[string]: {[string]: HarpoonList}}
---@field hooks_setup boolean
local Harpoon = {}

Harpoon.__index = Harpoon

---@return Harpoon
function Harpoon:new()
    local config = Config.get_default_config()

    local harpoon = setmetatable({
        config = config,
        data = Data.Data:new(),
        ui = Ui:new(config.settings),
        listeners = Listeners.listeners,
        lists = {},
        hooks_setup = false,
    }, self)

    return harpoon
end

---@param partial_config HarpoonPartialConfig
---@return Harpoon
function Harpoon:setup(partial_config)
    self.config = Config.merge_config(partial_config, self.config)
    self.ui:configure(self.config.settings)

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

    return self
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
        return existing_list
    end

    local data = self.data:data(key, name)
    local list_config = Config.get_config(self.config, name)

    local list = List.decode(list_config, name, data)
    lists[name] = list

    return list
end

---@param cb fun(list: HarpoonList, config: HarpoonPartialConfigItem, name: string)
function Harpoon:_for_each_list(cb)
    local key = self.config.settings.key()
    local seen = self.data.seen[key]
    local lists = self.lists[key]

    if not seen then
        return
    end

    for list_name, _ in pairs(seen) do
        local list_config = Config.get_config(self.config, list_name)
        cb(lists[list_name], list_config, list_name)
    end
end

function Harpoon:sync()
    local key = self.config.settings.key()
    self:_for_each_list(function(list, _, list_name)
        if list.encode == false then
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

function Harpoon:__debug_reset()
    require("plenary.reload").reload_module("harpoon")
end

return Harpoon:new()
