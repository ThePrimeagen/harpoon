---@class SwapUI
---@field ACTIONS table<string, string>
local SwapUI = {}

SwapUI.ACTIONS = {
    READONLY = "readonly",
    EDIT = "edit",
    RECOVER = "recover",
    DELETE = "delete",
    ABORT = "abort",
}

---@param filepath string
---@param swap string
---@param on_choice fun(value: string)
function SwapUI.show(filepath, swap, on_choice)
    local width = math.min(80, vim.o.columns - 10)
    local height = 14
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[bufnr].bufhidden = "wipe"

    local action_header = "Choose an action:"
    local lines = {
        "E325: ATTENTION",
        "",
        "Found a swap file with the name: " .. swap,
        "",
        "While opening file: " .. filepath,
        "",
        action_header,
        " [O]pen Read-only",
        " (E)dit anyway",
        " (R)ecover",
        " (D)elete swap & edit",
        " (A)bort / (Q)uit",
    }

    vim.bo[bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.bo[bufnr].modifiable = false

    local win_id = vim.api.nvim_open_win(bufnr, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = "Harpoon: Swap File Found",
        title_pos = "left",
    })

    -- Detect action start/end
    local action_start, action_end
    for i, line in ipairs(lines) do
        if line:match(action_header) then
            action_start = i + 1
            action_end = #lines
            break
        end
    end

    local choice_map = {
        SwapUI.ACTIONS.READONLY,
        SwapUI.ACTIONS.EDIT,
        SwapUI.ACTIONS.RECOVER,
        SwapUI.ACTIONS.DELETE,
        SwapUI.ACTIONS.ABORT,
    }

    local column = 2
    vim.api.nvim_win_set_cursor(win_id, { action_start, column })

    -- Enter to select
    vim.keymap.set("n", "<CR>", function()
        local lnum = vim.fn.line(".")
        local idx = lnum - action_start + 1
        local choice = choice_map[idx]
        if choice then
            vim.api.nvim_win_close(win_id, true)
            on_choice(choice)
        end
    end, { buffer = bufnr, nowait = true })

    -- Cycle with j/k
    vim.keymap.set("n", "j", function()
        local lnum = vim.fn.line(".")
        if lnum >= action_end then
            vim.api.nvim_win_set_cursor(win_id, { action_start, column })
        else
            vim.api.nvim_win_set_cursor(win_id, { lnum + 1, column })
        end
    end, { buffer = bufnr, nowait = true })

    vim.keymap.set("n", "k", function()
        local lnum = vim.fn.line(".")
        if lnum <= action_start then
            vim.api.nvim_win_set_cursor(win_id, { action_end, column })
        else
            vim.api.nvim_win_set_cursor(win_id, { lnum - 1, column })
        end
    end, { buffer = bufnr, nowait = true })

    -- Hotkeys
    local hotkeys = {
        O = SwapUI.ACTIONS.READONLY,
        o = SwapUI.ACTIONS.READONLY,
        E = SwapUI.ACTIONS.EDIT,
        e = SwapUI.ACTIONS.EDIT,
        R = SwapUI.ACTIONS.RECOVER,
        r = SwapUI.ACTIONS.RECOVER,
        D = SwapUI.ACTIONS.DELETE,
        d = SwapUI.ACTIONS.DELETE,
        A = SwapUI.ACTIONS.ABORT,
        a = SwapUI.ACTIONS.ABORT,
        Q = SwapUI.ACTIONS.ABORT,
        q = SwapUI.ACTIONS.ABORT,
    }
    for key, action in pairs(hotkeys) do
        vim.keymap.set("n", key, function()
            vim.api.nvim_win_close(win_id, true)
            on_choice(action)
        end, { buffer = bufnr, nowait = true })
    end

    -- Escape closes window
    vim.keymap.set("n", "<Esc>", function()
        vim.api.nvim_win_close(win_id, true)
        on_choice(SwapUI.ACTIONS.ABORT)
    end, { buffer = bufnr, nowait = true })
end

return SwapUI
