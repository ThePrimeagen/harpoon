local Logger = require("harpoon.logger")
local List = require("harpoon.list")
local Extensions = require("harpoon.extensions")
local Config = require("harpoon.config")

--- @param items any[]
--- @return number
local function get_max_index(items)
    local max = 0
    for n, _ in pairs(items) do
        if type(n) == "number" and n > max then
            max = n
        end
    end
    return max
end

--- @class HarpoonTermList : HarpoonList
--- @field items table<number, HarpoonItem>
--- @field config HarpoonPartialConfigItem
--- @field name string
--- @field _length number
--- @field _index number
local HarpoonTermList = {}
HarpoonTermList.__index = HarpoonTermList
setmetatable(HarpoonTermList, { __index = List })

--- Terminal-specific HarpoonList
--- @param config HarpoonPartialConfigItem
--- @param name string
--- @param items any[]
--- @return HarpoonList
function HarpoonTermList:new(config, name, items)

    local merged_config = Config.get_config(Config.get_default_config(), name)
    if config then
        merged_config = vim.tbl_extend("force", merged_config, config)
    end

    -- overwrite terminal specific stuff
    local term_config = vim.tbl_extend("force", merged_config, {
        select_with_nil = true, -- Needed to index into not-yet-existing items
        encode = false, -- Never persist terminals
    })

    local list = List:new(term_config, name, items)
    setmetatable(list, self)
    list.__is_harpoon_list = true
    return list
end


--- Ensure there is a valid terminal at index
--- @param index number
--- @return HarpoonItem
function HarpoonTermList:ensure_terminal(index)
    local item = self.items[index]
    local buf_id = item and item.value
    if not buf_id or not vim.api.nvim_buf_is_valid(buf_id) then
        item = self:create_terminal(index)
    end
    return item
end

--- Create a new terminal buffer
--- @param index number
--- @return HarpoonItem
function HarpoonTermList:create_terminal(index)
    vim.cmd.term()
    local buf_id = vim.api.nvim_get_current_buf()
    local item = {value = buf_id, context = {}}
    self.items[index] = item
    if index > self._length then
        self._length = index
    end
    Logger:log("HarpoonTermList:create_terminal", { index = index, buf_id = buf_id })
    return item
end

--- Selects a terminal by index, creating it if needed
--- @param index number
--- @param options table|nil e.g: split, vsplit, tabedit
function HarpoonTermList:select(index, options)
    options = options or {}
    local item = self:ensure_terminal(index)
    local buf_id = item.value

    -- Handle window splits
    if options.vsplit then
        vim.cmd("vsplit")
    elseif options.split then
        vim.cmd("split")
    elseif options.tabedit then
        vim.cmd("tabedit")
    end

    -- Set current buffer to terminal
    vim.api.nvim_set_current_buf(buf_id)

    Extensions.extensions:emit(
        Extensions.event_names.SELECT,
        { list = self, item = buf_id, idx = index }
    )
end

--- Send command to terminal
--- @param index number
--- @param cmd string Command to send
--- @param ... any Format arguments for the command
function HarpoonTermList:send_command(index, cmd, ...)
    local item = self:ensure_terminal(index)
    local buf_id = item.value
    if not cmd then
        return
    end

    local formatted_cmd = string.format(cmd, ...)
    local chan_id = vim.api.nvim_buf_get_var(buf_id, "terminal_job_id")
    vim.api.nvim_chan_send(chan_id, formatted_cmd .. "\n")
    Logger:log("HarpoonTermList:send_command", { index = index, cmd = formatted_cmd })
end

--- Send the current visual selection or current line to terminal
--- @param index number
--- @param newline boolean? Whether to append a newline to the end of the text (default: true)
function HarpoonTermList:send_selection(index, newline)
    newline = newline or true
    local item = self:ensure_terminal(index)
    local buf_id = item.value
    local text

    -- Visual mode?
    local mode = vim.api.nvim_get_mode().mode
    if mode:match("[vV\22]") then
        -- Exit visual mode - gives issues with the <> marks not being correcly set
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)

        -- Get selected text
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")
        local start_line, start_col = start_pos[2], start_pos[3]
        local end_line, end_col = end_pos[2], end_pos[3]
        local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

        -- Handle part of a single line only
        if #lines == 0 then
            print("No lines selected")
            return nil
        elseif #lines == 1 then
            lines[1] = string.sub(lines[1], start_col, end_col)
        else
            lines[1] = string.sub(lines[1], start_col)
            lines[#lines] = string.sub(lines[#lines], 1, end_col)
        end

        text = table.concat(lines, "\n")
    else
        text = vim.api.nvim_get_current_line()
    end

    -- Send to terminal
    local chan_id = vim.api.nvim_buf_get_var(buf_id, "terminal_job_id")
    vim.api.nvim_chan_send(chan_id, text .. (newline and "\n" or ""))
    Logger:log("HarpoonTermList:send_selection", { index = index, text_length = #text })
end

function HarpoonTermList.create_list_item(_, _)
    print("Adding items directly to terminal list is not supported. Use select() with an index.")
    Logger:log("HarpoonTermList:create_list_item", { message = "Adding items to terminal list is not supported" })
    return nil
end

function HarpoonTermList:add(_)
    print("Adding items to terminal list is not supported directly. Use :select() with an index instead.")
    Logger:log("HarpoonTermList:add", { message = "Adding items to terminal list is not supported" })
    return self
end

function HarpoonTermList:prepend(_)
    print("Prepending items to terminal list is not supported directly. Use :select() with an index instead.")
    Logger:log("HarpoonTermList:prepend", { message = "Prepending to terminal list is not supported" })
    return self
end

function HarpoonTermList:remove(_)
    print("Removing terminals by item is not supported. Use :remove_at() with an index instead.")
    Logger:log("HarpoonTermList:remove", { message = "Removing terminal by item not supported" })
    return self
end

--- Remove terminal at a given index and delete its buffer
--- @param index number
function HarpoonTermList:remove_at(index)
    local item = self.items[index]
    if not item or not item.value then
        return
    end
    local buf_id = item.value
    self.items[index] = nil  -- remove from list
    if vim.api.nvim_buf_is_valid(buf_id) then
        vim.api.nvim_buf_delete(buf_id, { force = true })  -- kill buffer
    end
    -- cleanup
    if index == self._length then
        self._length = get_max_index(self.items)
    end
    Logger:log("HarpoonTermList:remove_at", { index = index, buf_id = buf_id })
end

--- @param value any
--- @return any
function HarpoonTermList:get_by_value(value)
    for _, item in ipairs(self.items) do
        if item.value == value then
            return item
        end
    end
    return nil
end

--- @return table<number, HarpoonItem>
function HarpoonTermList:display()
    local lines = {}
    for idx, item in pairs(self.items) do
        if item and item.value then
            table.insert(lines, string.format("Term %d - [buf:%d]", idx, item.value))
        end
    end
    return lines
end

--- Overwrite default resolve so we delete terminal buffers when removed from
--- the menu
function HarpoonTermList:resolve_displayed(displayed_lines, _)
    local present_bufs = {}
    for _, line in ipairs(displayed_lines) do
        local buf_id = tonumber(line:match("%[buf:(%d+)%]"))
        if buf_id then
            present_bufs[buf_id] = true
        end
    end

    -- Remove terms at the indexes we dropped
    for idx, item in pairs(self.items) do
        if item and item.value and not present_bufs[item.value] then
            self:remove_at(idx)
        end
    end
end

return HarpoonTermList
