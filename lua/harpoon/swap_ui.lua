---@class SwapUI
---@field ACTIONS table<string, string>
local M = {}

M.ACTIONS = {
    READONLY = "readonly",
    EDIT = "edit",
    RECOVER = "recover",
    DELETE = "delete",
    ABORT = "abort",
}

---@param filepath string
---@param swap string
---@param on_choice fun(value: string)
function M.show(filepath, swap, on_choice)
    local width = math.min(80, vim.o.columns - 10)
    local height = 14
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[bufnr].bufhidden = "wipe"

    local lines = {
        "E325: ATTENTION",
        "",
        "Found a swap file with the name: " .. swap,
        "",
        "While opening file: " .. filepath,
        "",
        "Choose an action:",
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

    local action_start = 8
    local action_end = #lines
    local column = 2
    vim.api.nvim_win_set_cursor(win_id, { action_start, column })

    local hotkeys = {
        O = M.ACTIONS.READONLY,
        o = M.ACTIONS.READONLY,
        E = M.ACTIONS.EDIT,
        e = M.ACTIONS.EDIT,
        R = M.ACTIONS.RECOVER,
        r = M.ACTIONS.RECOVER,
        D = M.ACTIONS.DELETE,
        d = M.ACTIONS.DELETE,
        A = M.ACTIONS.ABORT,
        a = M.ACTIONS.ABORT,
        Q = M.ACTIONS.ABORT,
        q = M.ACTIONS.ABORT,
        ["<Esc>"] = M.ACTIONS.ABORT,
    }

    local stop_on_key_id

    local function close(choice)
        -- Unregister on_key listener safely
        if stop_on_key_id then
            pcall(vim.on_key, nil, stop_on_key_id)
            stop_on_key_id = nil
        end
        if vim.api.nvim_win_is_valid(win_id) then
            vim.api.nvim_win_close(win_id, true)
        end
        if type(on_choice) == "function" then
            pcall(on_choice, choice)
        end
    end

    -- Map hotkeys
    for key, action in pairs(hotkeys) do
        vim.keymap.set("n", key, function()
            close(action)
        end, { buffer = bufnr, nowait = true, silent = true })
    end

    -- Enter selects current line
    vim.keymap.set("n", "<CR>", function()
        local lnum = vim.fn.line(".")
        local idx = math.max(1, math.min(lnum - action_start + 1, 5))
        local choice_map = {
            M.ACTIONS.READONLY,
            M.ACTIONS.EDIT,
            M.ACTIONS.RECOVER,
            M.ACTIONS.DELETE,
            M.ACTIONS.ABORT,
        }
        close(choice_map[idx] or M.ACTIONS.ABORT)
    end, { buffer = bufnr, nowait = true, silent = true })

    -- Navigation
    vim.keymap.set("n", "j", function()
        local lnum = vim.fn.line(".")
        if lnum >= action_end then
            vim.api.nvim_win_set_cursor(win_id, { action_start, column })
        else
            vim.api.nvim_win_set_cursor(win_id, { lnum + 1, column })
        end
    end, { buffer = bufnr, nowait = true, silent = true })

    vim.keymap.set("n", "k", function()
        local lnum = vim.fn.line(".")
        if lnum <= action_start then
            vim.api.nvim_win_set_cursor(win_id, { action_end, column })
        else
            vim.api.nvim_win_set_cursor(win_id, { lnum - 1, column })
        end
    end, { buffer = bufnr, nowait = true, silent = true })

    -- Silent abort on any other key
    stop_on_key_id = vim.on_key(function(key)
        local ok, key_str = pcall(vim.fn.nr2char, key)
        if not ok or not key_str or key_str == "" then
            return
        end
        if not hotkeys[key_str] then
            close(M.ACTIONS.ABORT)
        end
    end)
end

return M
