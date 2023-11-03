local Path = require("plenary.path")

local data_path = vim.fn.stdpath("data")
local full_data_path = string.format("%s/harpoon2.json", data_path)

local M = {}

function M.set_data_path(path)
    full_data_path = path
end

local function has_keys(t)
    for _ in pairs(t) do
        return true
    end
    return false
end

--- @alias RawData {[string]: string[]}

--- @class Data
--- @field seen {[string]: boolean}
--- @field _data RawData
--- @field has_error boolean


-- 1. load the data
-- 2. keep track of the lists requested
-- 3. sync save

local Data = {}

Data.__index = Data

---@param data any
local function write_data(data)
    Path:new(full_data_path):write_data(vim.json.encode(data))
end

---@return RawData
local function read_data()
    return vim.json.decode(Path:new(full_data_path):read())
end

---@return Harpoon
function Data:new()
    local ok, data = pcall(read_data)

    return setmetatable({
        _data = data,
        has_error = not ok,
        seen = {}
    }, self)
end

---@param name string
---@return string[]
function Data:data(name)
    if self.has_error then
        error("Harpoon: there was an error reading the data file, cannot read data")
    end
    return self._data[name] or {}
end

---@param name string
---@param values string[]
function Data:update(name, values)
    if self.has_error then
        error("Harpoon: there was an error reading the data file, cannot update")
    end
    self.seen[name] = true
    self._data[name] = values
end

function Data:sync()
    if self.has_error then
        return
    end

    if not has_keys(self.seen) then
        return
    end

    local ok, data = pcall(read_data)
    if not ok then
        error("Harpoon: unable to sync data, error reading data file")
    end

    for k, v in pairs(self._data) do
        data[k] = v
    end

    pcall(write_data, data)
end


M.Data = Data

return M

