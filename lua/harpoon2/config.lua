local M = {}

---@alias HarpoonListItem {value: any, context: any}
---@alias HarpoonListFileItem {value: string, context: {row: number, col: number}}

---@class HarpoonPartialConfigItem
---@field encode? (fun(list_item: HarpoonListItem): string)
---@field decode? (fun(obj: string): any)
---@field display? (fun(list_item: HarpoonListItem): string)
---@field select? (fun(list_item: HarpoonListItem, options: any?): nil)
---@field equals? (fun(list_line_a: HarpoonListItem, list_line_b: HarpoonListItem): boolean)
---@field add? fun(item: any?): HarpoonListItem

---@class HarpoonSettings
---@field save_on_toggle boolean defaults to true
---@field jump_to_file_location boolean defaults to true
---@field key (fun(): string)

---@class HarpoonPartialSettings
---@field save_on_toggle? boolean
---@field jump_to_file_location? boolean
---@field key? (fun(): string)


---@class HarpoonConfig
---@field default HarpoonPartialConfigItem
---@field settings HarpoonSettings
---@field [string] HarpoonPartialConfigItem

---@class HarpoonPartialConfig
---@field default? HarpoonPartialConfigItem
---@field settings? HarpoonPartialSettings
---@field [string] HarpoonPartialConfigItem


---@return HarpoonPartialConfigItem
function M.get_config(config, name)
    return vim.tbl_extend("force", {}, config.default, config[name] or {})
end

---@return HarpoonConfig
function M.get_default_config()
    return {

        settings = {
            save_on_toggle = true,
            jump_to_file_location = true,
            key = function()
                return vim.loop.cwd()
            end,
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

            ---@param list_item HarpoonListItem
            display = function(list_item)
                return list_item.value
            end,

            ---@param file_item HarpoonListFileItem
            select = function(file_item, options)
                if file_item == nil then
                    return
                end

                local bufnr = vim.fn.bufnr(file_item.value)
                local set_position = false
                if bufnr == -1 then
                    set_position = true
                    bufnr = vim.fn.bufnr(file_item.value, true)
                end

                if not options or not options.vsplit or not options.split then
                    vim.api.nvim_set_current_buf(bufnr)
                elseif options.vsplit then
                    vim.cmd("vsplit")
                    vim.api.nvim_set_current_buf(bufnr)
                elseif options.split then
                    vim.cmd("split")
                    vim.api.nvim_set_current_buf(bufnr)
                end

                if set_position then
                    vim.api.nvim_win_set_cursor(0, {
                        file_item.context.row or 1,
                        file_item.context.col or 0
                    })
                end
            end,

            ---@param list_item_a HarpoonListItem
            ---@param list_item_b HarpoonListItem
            equals = function(list_item_a, list_item_b)
                return list_item_a.value == list_item_b.value
            end,

            ---@param name any
            ---@return HarpoonListItem
            add = function(name)
                name = name or vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
                local bufnr = vim.fn.bufnr(name, false)

                local pos = {1, 0}
                if bufnr ~= -1 then
                    pos = vim.api.nvim_win_get_cursor(0)
                end

                return {
                    value = name,
                    context = {
                        row = pos[1],
                        col = pos[2],
                    }
                }
            end,
        }
    }
end

---@param partial_config HarpoonPartialConfig
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
