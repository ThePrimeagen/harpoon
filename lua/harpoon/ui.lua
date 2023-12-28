local Buffer = require("harpoon.buffer")
local Logger = require("harpoon.logger")
local Extensions = require("harpoon.extensions")

---@class HarpoonToggleOptions
---@field border? any this value is directly passed to nvim_open_win
---@field title_pos? any this value is directly passed to nvim_open_win
---@field ui_fallback_width? number
---@field ui_width_ratio? number

---@return HarpoonToggleOptions
local function toggle_config(config)
    return vim.tbl_extend("force", {
        ui_fallback_width = 69,
        ui_width_ratio = 0.62569,
    }, config or {})
end

---@class HarpoonUI
---@field win_id number
---@field bufnr number
---@field settings HarpoonSettings
---@field active_list HarpoonList
local HarpoonUI = {}

---@param list HarpoonList
---@return string
local function list_name(list)
    return list and list.name or "nil"
end

HarpoonUI.__index = HarpoonUI

---@param settings HarpoonSettings
---@return HarpoonUI
function HarpoonUI:new(settings)
    return setmetatable({
        win_id = nil,
        bufnr = nil,
        active_list = nil,
        settings = settings,
    }, self)
end

function HarpoonUI:close_menu()
    if self.closing then
        return
    end

    self.closing = true
    Logger:log(
        "ui#close_menu name: ",
        list_name(self.active_list),
        "win and bufnr",
        {
            win = self.win_id,
            bufnr = self.bufnr,
        }
    )

    if self.bufnr ~= nil and vim.api.nvim_buf_is_valid(self.bufnr) then
        vim.api.nvim_buf_delete(self.bufnr, { force = true })
    end

    if self.win_id ~= nil and vim.api.nvim_win_is_valid(self.win_id) then
        vim.api.nvim_win_close(self.win_id, true)
    end

    self.active_list = nil
    self.win_id = nil
    self.bufnr = nil

    self.closing = false
end

--- TODO: Toggle_opts should be where we get extra style and border options
--- and we should create a nice minimum window
---@param toggle_opts HarpoonToggleOptions
---@return number,number
function HarpoonUI:_create_window(toggle_opts)
    local win = vim.api.nvim_list_uis()

    local width = toggle_opts.ui_fallback_width

    if #win > 0 then
        -- no ackshual reason for 0.62569, just looks complicated, and i want
        -- to make my boss think i am smart
        width = math.floor(win[1].width * toggle_opts.ui_width_ratio)
    end

    local height = 8
    local bufnr = vim.api.nvim_create_buf(false, true)
    local win_id = vim.api.nvim_open_win(bufnr, true, {
        relative = "editor",
        title = "Harpoon",
        title_pos = toggle_opts.title_pos or "left",
        row = math.floor(((vim.o.lines - height) / 2) - 1),
        col = math.floor((vim.o.columns - width) / 2),
        width = width,
        height = height,
        style = "minimal",
        border = toggle_opts.border or "single",
    })

    if win_id == 0 then
        Logger:log(
            "ui#_create_window failed to create window, win_id returned 0"
        )
        self.bufnr = bufnr
        self:close_menu()
        error("Failed to create window")
    end

    Buffer.setup_autocmds_and_keymaps(bufnr)

    self.win_id = win_id
    vim.api.nvim_set_option_value("number", true, {
        win = win_id,
    })

    return win_id, bufnr
end

---@param list? HarpoonList
---TODO: @param opts? HarpoonToggleOptions
function HarpoonUI:toggle_quick_menu(list, opts)
    opts = toggle_config(opts)
    if list == nil or self.win_id ~= nil then
        Logger:log("ui#toggle_quick_menu#closing", list and list.name)
        if self.settings.save_on_toggle then
            self:save()
        end
        self:close_menu()
        return
    end

    -- grab the current file before opening the quick menu
    local current_file = vim.api.nvim_buf_get_name(0)

    Logger:log("ui#toggle_quick_menu#opening", list and list.name)
    local win_id, bufnr = self:_create_window(opts)

    self.win_id = win_id
    self.bufnr = bufnr
    self.active_list = list

    local contents = self.active_list:display()
    vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, contents)

    Extensions.extensions:emit(Extensions.event_names.UI_CREATE, {
        win_id = win_id,
        bufnr = bufnr,
        current_file = current_file,
    })
end

---@param options? any
function HarpoonUI:select_menu_item(options)
    local idx = vim.fn.line(".")

    -- must first save any updates potentially made to the list before
    -- navigating
    local list = Buffer.get_contents(self.bufnr)
    self.active_list:resolve_displayed(list)

    Logger:log(
        "ui#select_menu_item selecting item",
        idx,
        "from",
        list,
        "options",
        options
    )

    list = self.active_list
    self:close_menu()
    list:select(idx, options)
end

function HarpoonUI:save()
    local list = Buffer.get_contents(self.bufnr)
    Logger:log("ui#save", list)
    self.active_list:resolve_displayed(list)
    if self.settings.sync_on_ui_close then
        require("harpoon"):sync()
    end
end

---@param settings HarpoonSettings
function HarpoonUI:configure(settings)
    self.settings = settings
end

return HarpoonUI
