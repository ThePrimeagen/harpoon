---@param filepath string
---@param swap string
---@param on_choice fun(value: string)
local function show_swap_ui(filepath, swap, on_choice)
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

    -- Enable highlight of current line
    vim.wo[win_id].cursorline = true
    -- Optional: set a specific highlight (defaults to CursorLine)
    -- vim.api.nvim_set_hl(0, "CursorLine", { bg = "#3c3836" })

    -- Get start and end of actions
    local action_start, action_end
    for i, line in ipairs(lines) do
        if line:match(action_header) then
            action_start = i + 1
            action_end = #lines
            break
        end
    end

    local choice_map = {
        "readonly",
        "edit",
        "recover",
        "delete",
        "abort",
    }

    -- Place cursor on first option
    local column = 2
    vim.api.nvim_win_set_cursor(win_id, { action_start, column })

    vim.keymap.set("n", "<CR>", function()
        local lnum = vim.fn.line(".")
        local idx = lnum - action_start + 1
        local choice = choice_map[idx]
        if choice then
            vim.api.nvim_win_close(win_id, true)
            on_choice(choice)
        end
    end, { buffer = bufnr, nowait = true })

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

    local hotkeys = {
        O = "readonly",
        o = "readonly",
        E = "edit",
        e = "edit",
        R = "recover",
        r = "recover",
        D = "delete",
        d = "delete",
        A = "abort",
        a = "abort",
        Q = "abort",
        q = "abort",
    }
    for key, action in pairs(hotkeys) do
        vim.keymap.set("n", key, function()
            vim.api.nvim_win_close(win_id, true)
            on_choice(action)
        end, { buffer = bufnr, nowait = true })
    end

    local function close_abort()
        vim.api.nvim_win_close(win_id, true)
        on_choice("abort")
    end
    vim.keymap.set("n", "q", close_abort, { buffer = bufnr, nowait = true })
    vim.keymap.set("n", "<Esc>", close_abort, { buffer = bufnr, nowait = true })
end

return show_swap_ui
