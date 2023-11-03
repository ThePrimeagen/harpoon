local M = {}

function M.get_config(config, name)
    return vim.tbl_extend("force", {}, config.default, config[name] or {})
end

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
