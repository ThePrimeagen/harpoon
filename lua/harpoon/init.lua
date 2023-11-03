
-- setup
-- read from a config file
--

---@alias HarpoonListItem {value: any, context: any}

---@class HarpoonPartialConfigItem
---@field encode? (fun(list_item: HarpoonListItem): string)
---@field decode? (fun(obj: string): any)
---@field key? (fun(): string)
---@field display? (fun(list_item: HarpoonListItem): string)
---@field select? (fun(list_item: HarpoonListItem): nil)
---@field equals? (fun(list_line_a: HarpoonListItem, list_line_b: HarpoonListItem): boolean)
---@field add? fun(): HarpoonListItem

---@class HarpoonSettings
---@field save_on_toggle boolean defaults to true
---@field jump_to_file_location boolean defaults to true

---@class HarpoonConfig
---@field default HarpoonPartialConfigItem
---@field settings HarpoonSettings
---@field [string] HarpoonPartialConfigItem

local M = {}

---@param c HarpoonConfig
function config(c)
end

return M

