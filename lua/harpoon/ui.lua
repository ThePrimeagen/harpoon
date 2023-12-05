local popup = require("plenary").popup
local Buffer = require("harpoon.buffer")
local Logger = require("harpoon.logger")

---@class HarpoonUI
---@field win_id number
---@field border_win_id number
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
        border_win_id = nil,
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

    if
        self.border_win_id ~= nil
        and vim.api.nvim_win_is_valid(self.border_win_id)
    then
        vim.api.nvim_win_close(self.border_win_id, true)
    end

    self.active_list = nil
    self.win_id = nil
    self.border_win_id = nil
    self.bufnr = nil

    self.closing = false
end

---@return number,number
function HarpoonUI:_create_window()
    local win = vim.api.nvim_list_uis()

    local width = self.settings.ui_fallback_width
    if #win > 0 then
        -- no ackshual reason for 0.62569, just looks complicated, and i want
        -- to make my boss think i am smart
        width = math.floor(win[1].width * self.settings.ui_width_ratio)
    end

    local height = 8
    local borderchars = self.settings.border_chars
    local bufnr = vim.api.nvim_create_buf(false, false)
    local _, popup_info = popup.create(bufnr, {
        title = "Harpoon",
        highlight = "HarpoonWindow",
        borderhighlight = "HarpoonBorder",
        titlehighlight = "HarpoonTitle",
        line = math.floor(((vim.o.lines - height) / 2) - 1),
        col = math.floor((vim.o.columns - width) / 2),
        minwidth = width,
        minheight = height,
        borderchars = borderchars,
    })
    local win_id = popup_info.win_id

    Buffer.setup_autocmds_and_keymaps(bufnr)

    self.win_id = win_id
    self.border_win_id = popup_info.border.win_id
    vim.api.nvim_win_set_option(win_id, "number", true)

    return win_id, bufnr
end

---@param list? HarpoonList
function HarpoonUI:toggle_quick_menu(list)
    Logger:log("ui#toggle_quick_menu", list and list.name)

    if list == nil or self.win_id ~= nil then
        if self.settings.save_on_toggle then
            self:save()
        end
        self:close_menu()
        return
    end

    local win_id, bufnr = self:_create_window()

    self.win_id = win_id
    self.bufnr = bufnr
    self.active_list = list

    local contents = self.active_list:display()
    vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, contents)
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

    self.active_list:select(idx, options)
    self:close_menu()
end

function HarpoonUI:save()
    local list = Buffer.get_contents(self.bufnr)
    Logger:log("ui#save", list)
    self.active_list:resolve_displayed(list)
end

---@param settings HarpoonSettings
function HarpoonUI:configure(settings)
    self.settings = settings
end

return HarpoonUI
