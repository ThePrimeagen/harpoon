local popup = require("plenary").popup
local Buffer = require("harpoon.buffer")
local DEFAULT_WINDOW_WIDTH = 69 -- nice

---@class HarpoonUI
---@field win_id number
---@field border_win_id number
---@field bufnr number
---@field settings HarpoonSettings
---@field active_list HarpoonList
local HarpoonUI = {}

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

    local width = DEFAULT_WINDOW_WIDTH
    if #win > 0 then
        -- no ackshual reason for 0.62569, just looks complicated, and i want
        -- to make my boss think i am smart
        width = math.floor(win[1].width * 0.62569)
    end

    local height = 8
    local borderchars =
        { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
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

local count = 0

---@param list? HarpoonList
function HarpoonUI:toggle_quick_menu(list)
    count = count + 1

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

    self.active_list:select(idx, options)
    self:close_menu()
end

function HarpoonUI:save()
    local list = Buffer.get_contents(self.bufnr)
    self.active_list:resolve_displayed(list)
end

---@param settings HarpoonSettings
function HarpoonUI:configure(settings)
    self.settings = settings
end

--[[
function M.location_window(options)
    local default_options = {
        relative = "editor",
        style = "minimal",
        width = 30,
        height = 15,
        row = 2,
        col = 2,
    }
    options = vim.tbl_extend("keep", options, default_options)

    local bufnr = options.bufnr or vim.api.nvim_create_buf(false, true)
    local win_id = vim.api.nvim_open_win(bufnr, true, options)

    return {
        bufnr = bufnr,
        win_id = win_id,
    }
end

-- TODO: What is this used for?
function M.notification(text)
    local win_stats = vim.api.nvim_list_uis()[1]
    local win_width = win_stats.width

    local prev_win = vim.api.nvim_get_current_win()

    local info = M.location_window({
        width = 20,
        height = 2,
        row = 1,
        col = win_width - 21,
    })

    vim.api.nvim_buf_set_lines(
        info.bufnr,
        0,
        5,
        false,
        { "!!! Notification", text }
    )
    vim.api.nvim_set_current_win(prev_win)

    return {
        bufnr = info.bufnr,
        win_id = info.win_id,
    }
end

function M.close_notification(bufnr)
    vim.api.nvim_buf_delete(bufnr)
end
--]]

return HarpoonUI
