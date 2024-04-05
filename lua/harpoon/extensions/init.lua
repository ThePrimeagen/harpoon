---@class HarpoonExtensions
---@field listeners HarpoonExtension[]
local HarpoonExtensions = {}

---@class HarpoonExtension
---@field ADD? fun(...): nil
---@field SELECT? fun(...): nil
---@field REMOVE? fun(...): nil
---@field REORDER? fun(...): nil
---@field UI_CREATE? fun(...): nil
---@field SETUP_CALLED? fun(...): nil
---@field LIST_CREATED? fun(...): nil
---@field LIST_READ? fun(...): nil
---@field NAVIGATE? fun(...): nil
---@field POSITION_UPDATED? fun(...): nil

HarpoonExtensions.__index = HarpoonExtensions

function HarpoonExtensions:new()
    return setmetatable({
        listeners = {},
    }, self)
end

---@param extension HarpoonExtension
function HarpoonExtensions:add_listener(extension)
    table.insert(self.listeners, extension)
end

function HarpoonExtensions:clear_listeners()
    self.listeners = {}
end

---@param type string
---@param ... any
function HarpoonExtensions:emit(type, ...)
    for _, cb in ipairs(self.listeners) do
        if cb[type] then
            cb[type](...)
        end
    end
end

local extensions = HarpoonExtensions:new()
local Builtins = {}

function Builtins.command_on_nav(cmd)
    return {
        NAVIGATE = function()
            vim.cmd(cmd)
        end,
    }
end

function Builtins.navigate_with_number()
    return {
        UI_CREATE = function(cx)
            for i = 1, 9 do
                vim.keymap.set("n", "" .. i, function()
                    require("harpoon"):list():select(i)
                end, { buffer = cx.bufnr })
            end
        end,
    }
end

function Builtins.sync_index_with_current_file()
    return {
        SELECT = function(cx)
            cx.list._index = cx.idx
        end,
        UI_CREATE = function(cx)
            local path = require("plenary.path"):new(cx.current_file)
            local current_file = path:make_relative(vim.loop.cwd())
            local contents = require("harpoon.buffer").get_contents(cx.bufnr)
            for i, file in ipairs(contents) do
                if file == current_file then
                    require("harpoon"):list()._index = i
                    vim.api.nvim_win_set_cursor(cx.win_id, { i, 0 })
                end
            end
        end,
    }
end

return {
    builtins = Builtins,
    extensions = extensions,
    event_names = {
        REPLACE = "REPLACE",
        ADD = "ADD",
        SELECT = "SELECT",
        REMOVE = "REMOVE",
        POSITION_UPDATED = "POSITION_UPDATED",

        --- This exists because the ui can change the list in dramatic ways
        --- so instead of emitting a REMOVE, then an ADD, then a REORDER, we
        --- instead just emit LIST_CHANGE
        LIST_CHANGE = "LIST_CHANGE",

        REORDER = "REORDER",
        UI_CREATE = "UI_CREATE",
        SETUP_CALLED = "SETUP_CALLED",
        LIST_CREATED = "LIST_CREATED",
        NAVIGATE = "NAVIGATE",
        LIST_READ = "LIST_READ",
    },
}
