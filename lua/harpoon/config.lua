local M = {}

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

---@return HarpoonConfig
function M.get_config(config, name)
    return vim.tbl_extend("force", {}, config.default, config[name] or {})
end

---@return HarpoonConfig
function M.get_default_config()
    return {
        settings = {
            save_on_toggle = true,
            jump_to_file_location = true,
        },

        default = {
            ---@param obj HarpoonListItem
            ---@return string
            encode = function(obj)
                return vim.json.encode(obj)
            end,

            ---@param str string
            ---@return HarpoonListItem
            decode = function(str)
                return vim.json.decode(str)
            end,

            key = function()
                return vim.loop.cwd()
            end,

            ---@param list_item HarpoonListItem
            display = function(list_item)
                return list_item.value
            end,

            ---@param list_item HarpoonListItem
            select = function(list_item)
                error("please implement select")
            end,

            ---@param list_item_a HarpoonListItem
            ---@param list_item_b HarpoonListItem
            equals = function(list_item_a, list_item_b)
                return list_item_a.value == list_item_b.value
            end,

            add = function()
                error("please implement add")
            end,
        }
    }
end

---@param partial_config HarpoonConfig
---@param latest_config HarpoonConfig?
---@return HarpoonConfig
function M.merge_config(partial_config, latest_config)
    local config = latest_config or M.get_default_config()
    for k, v in pairs(partial_config) do
        if k == "settings" then
            config.settings = vim.tbl_extend("force", config.settings, v)
        elseif k == "default" then
            config.default = vim.tbl_extend("force", config.default, v)
        else
            config[k] = vim.tbl_extend("force", config[k] or {}, v)
        end
    end
    return config
end

return M
