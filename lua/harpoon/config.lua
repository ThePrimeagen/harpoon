local Extensions = require("harpoon.extensions")
local Logger = require("harpoon.logger")
local Path = require("plenary.path")
local function normalize_path(buf_name, root)
    return Path:new(buf_name):make_relative(root)
end
local function to_exact_name(value)
    return "^" .. value .. "$"
end

local M = {}
local DEFAULT_LIST = "__harpoon_files"
M.DEFAULT_LIST = DEFAULT_LIST

---@alias HarpoonListItem {value: any, context: any}
---@alias HarpoonListFileItem {value: string, context: {row: number, col: number}}
---@alias HarpoonListFileOptions {split: boolean, vsplit: boolean, tabedit: boolean}

---@class HarpoonPartialConfigItem
---@field select_with_nil? boolean defaults to false
---@field encode? (fun(list_item: HarpoonListItem): string) | boolean
---@field decode? (fun(obj: string): any)
---@field display? (fun(list_item: HarpoonListItem): string)
---@field select? (fun(list_item?: HarpoonListItem, list: HarpoonList, options: any?): nil)
---@field equals? (fun(list_line_a: HarpoonListItem, list_line_b: HarpoonListItem): boolean)
---@field create_list_item? fun(config: HarpoonPartialConfigItem, item: any?): HarpoonListItem
---@field BufLeave? fun(evt: any, list: HarpoonList): nil
---@field VimLeavePre? fun(evt: any, list: HarpoonList): nil
---@field get_root_dir? fun(): string

---@class HarpoonSettings
---@field save_on_toggle boolean defaults to false
---@field sync_on_ui_close? boolean
---@field key (fun(): string)

---@class HarpoonPartialSettings
---@field save_on_toggle? boolean
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
            sync_on_ui_close = false,

            key = function()
                return vim.loop.cwd()
            end,
        },

        default = {

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
                local nbsp = "\u{00A0}"
                local icons_loaded, icons_package =
                    pcall(require, "nvim-web-devicons")

                if not icons_loaded then
                    return list_item.value
                end

                local icon = icons_package.get_icon(
                    vim.fn.fnamemodify(list_item.value, ":t")
                ) or ""

                return icon .. nbsp .. list_item.value
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
                if list_item == nil then
                    return
                end

                options = options or {}

                local bufnr = vim.fn.bufnr(to_exact_name(list_item.value))
                local set_position = false
                if bufnr == -1 then -- must create a buffer!
                    set_position = true
                    -- bufnr = vim.fn.bufnr(list_item.value, true)
                    bufnr = vim.fn.bufadd(list_item.value)
                end
                if not vim.api.nvim_buf_is_loaded(bufnr) then
                    vim.fn.bufload(bufnr)
                    vim.api.nvim_set_option_value("buflisted", true, {
                        buf = bufnr,
                    })
                end

                if options.vsplit then
                    vim.cmd("vsplit")
                elseif options.split then
                    vim.cmd("split")
                elseif options.tabedit then
                    vim.cmd("tabedit")
                end

                vim.api.nvim_set_current_buf(bufnr)

                if set_position then
                    local lines = vim.api.nvim_buf_line_count(bufnr)

                    local edited = false
                    if list_item.context.row > lines then
                        list_item.context.row = lines
                        edited = true
                    end

                    local row = list_item.context.row
                    local row_text =
                        vim.api.nvim_buf_get_lines(0, row - 1, row, false)
                    local col = #row_text[1]

                    if list_item.context.col > col then
                        list_item.context.col = col
                        edited = true
                    end

                    vim.api.nvim_win_set_cursor(0, {
                        list_item.context.row or 1,
                        list_item.context.col or 0,
                    })

                    if edited then
                        Extensions.extensions:emit(
                            Extensions.event_names.POSITION_UPDATED,
                            {
                                list_item = list_item,
                            }
                        )
                    end
                end

                Extensions.extensions:emit(Extensions.event_names.NAVIGATE, {
                    buffer = bufnr,
                })
            end,

            ---@param list_item_a HarpoonListItem
            ---@param list_item_b HarpoonListItem
            equals = function(list_item_a, list_item_b)
                if list_item_a == nil and list_item_b == nil then
                    return true
                elseif list_item_a == nil or list_item_b == nil then
                    return false
                end

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
                    or normalize_path(
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

            ---@param arg {buf: number}
            ---@param list HarpoonList
            BufLeave = function(arg, list)
                local bufnr = arg.buf
                local bufname = normalize_path(
                    vim.api.nvim_buf_get_name(bufnr),
                    list.config.get_root_dir()
                )
                local item = list:get_by_value(bufname)

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

                    Extensions.extensions:emit(
                        Extensions.event_names.POSITION_UPDATED,
                        item
                    )
                end
            end,

            autocmds = { "BufLeave" },
        },
    }
end

---@param partial_config HarpoonPartialConfig?
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

---@param settings HarpoonPartialSettings
function M.create_config(settings)
    local config = M.get_default_config()
    for k, v in ipairs(settings) do
        config.settings[k] = v
    end
    return config
end

return M
