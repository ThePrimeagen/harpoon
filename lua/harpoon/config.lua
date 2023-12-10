local Logger = require("harpoon.logger")
local utils = require("harpoon.utils")
local M = {}
local DEFAULT_LIST = "__harpoon_files"
M.DEFAULT_LIST = DEFAULT_LIST

---@alias HarpoonListItem {value: any, context: any}
---@alias HarpoonListFileItem {value: string, context: {row: number, col: number}}
---@alias HarpoonListFileOptions {split: boolean, vsplit: boolean}

---@class HarpoonPartialConfigItem
---@field select_with_nil? boolean defaults to false
---@field encode? (fun(list_item: HarpoonListItem): string)
---@field decode? (fun(obj: string): any)
---@field display? (fun(list_item: HarpoonListItem): string)
---@field select? (fun(list_item?: HarpoonListItem, list: HarpoonList, options: any?): nil)
---@field equals? (fun(list_line_a: HarpoonListItem, list_line_b: HarpoonListItem): boolean)
---@field create_list_item? fun(config: HarpoonPartialConfigItem, item: any?): HarpoonListItem
---@field BufLeave? fun(evt: any, list: HarpoonList): nil
---@field VimLeavePre? fun(evt: any, list: HarpoonList): nil
---@field get_root_dir? fun(): string

---@class HarpoonSettings
---@field border_chars string[] defaults to { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
---@field save_on_toggle boolean defaults to true
---@field select_current boolean default to false
---@field sync_on_ui_close? boolean
---@field ui_fallback_width number defaults 69, nice
---@field ui_width_ratio number defaults to 0.62569
---@field key (fun(): string)

---@class HarpoonPartialSettings
---@field save_on_toggle? boolean
---@field select_current? boolean
---@field sync_on_ui_close? boolean
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
            save_on_toggle = false,
            select_current = false,
            sync_on_ui_close = false,
            border_chars = {
                "─",
                "│",
                "─",
                "│",
                "╭",
                "╮",
                "╯",
                "╰",
            },
            ui_fallback_width = 69,
            ui_width_ratio = 0.62569,
            key = function()
                return vim.loop.cwd()
            end,
        },

        default = {
            --- ui_nav_wrap allows the ability to enable(true) or disable(false) wrapping on prev and next list calls.
            ui_nav_wrap = true,

            --- select_with_nill allows for a list to call select even if the provided item is nil
            select_with_nil = false,

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

            --- the select function is called when a user selects an item from
            --- the corresponding list and can be nil if select_with_nil is true
            ---@param list_item? HarpoonListFileItem
            ---@param list HarpoonList
            ---@param options HarpoonListFileOptions
            select = function(list_item, list, options)
                Logger:log(
                    "config_default#select",
                    list_item,
                    list.name,
                    options
                )
                options = options or {}
                if list_item == nil then
                    return
                end

                local bufnr = vim.fn.bufnr(list_item.value)
                local set_position = false
                if bufnr == -1 then
                    set_position = true
                    bufnr = vim.fn.bufnr(list_item.value, true)
                end
                if not vim.api.nvim_buf_is_loaded(bufnr) then
                    vim.fn.bufload(bufnr)
                    vim.api.nvim_buf_set_option(bufnr, "buflisted", true)
                end

                if options.vsplit then
                    vim.cmd("vsplit")
                    vim.api.nvim_set_current_buf(bufnr)
                elseif options.split then
                    vim.cmd("split")
                    vim.api.nvim_set_current_buf(bufnr)
                else
                    vim.api.nvim_set_current_buf(bufnr)
                end

                if set_position then
                    vim.api.nvim_win_set_cursor(0, {
                        list_item.context.row or 1,
                        list_item.context.col or 0,
                    })
                end
            end,

            ---@param list_item_a HarpoonListItem
            ---@param list_item_b HarpoonListItem
            equals = function(list_item_a, list_item_b)
                return list_item_a.value == list_item_b.value
            end,

            get_root_dir = function()
                return vim.loop.cwd()
            end,

            ---@param config HarpoonPartialConfigItem
            ---@param name? any
            ---@return HarpoonListItem
            create_list_item = function(config, name)
                name = name
                    -- TODO: should we do path normalization???
                    -- i know i have seen sometimes it becoming an absolute
                    -- path, if that is the case we can use the context to
                    -- store the bufname and then have value be the normalized
                    -- value
                    or utils.normalize_path(
                        vim.api.nvim_buf_get_name(
                            vim.api.nvim_get_current_buf()
                        ),
                        config.get_root_dir()
                    )

                Logger:log("config_default#create_list_item", name)

                local bufnr = vim.fn.bufnr(name, false)

                local pos = { 1, 0 }
                if bufnr ~= -1 then
                    pos = vim.api.nvim_win_get_cursor(0)
                end

                return {
                    value = name,
                    context = {
                        row = pos[1],
                        col = pos[2],
                    },
                }
            end,

            BufLeave = function(arg, list)
                local bufnr = arg.buf
                local bufname = vim.api.nvim_buf_get_name(bufnr)
                local item = list:get_by_display(bufname)

                if item then
                    local pos = vim.api.nvim_win_get_cursor(0)

                    Logger:log(
                        "config_default#BufLeave updating position",
                        bufnr,
                        bufname,
                        item,
                        "to position",
                        pos
                    )

                    item.context.row = pos[1]
                    item.context.col = pos[2]
                end
            end,

            autocmds = { "BufLeave" },
        },
    }
end

---@param partial_config HarpoonPartialConfig
---@param latest_config HarpoonConfig?
---@return HarpoonConfig
function M.merge_config(partial_config, latest_config)
    partial_config = partial_config or {}
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
