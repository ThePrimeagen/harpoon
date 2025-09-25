local ACTIONS = {
    READONLY = "readonly",
    EDIT = "edit",
    RECOVER = "recover",
    DELETE = "delete",
    ABORT = "abort",
}

---@param filepath string
---@param swap string
---@param on_choice fun(value: string)
local function show(filepath, swap, on_choice)
    local width = math.min(80, vim.o.columns - 10)
    local height = 14
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    -- Create scratch buffer
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[bufnr].bufhidden = "wipe"
    vim.bo[bufnr].buftype = "nofile"
    vim.bo[bufnr].buflisted = false

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
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    -- Open floating window
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
        focusable = true,
    })
    vim.wo[win_id].cursorline = true

    local action_start, action_end = 8, 12
    local column = 2
    vim.api.nvim_win_set_cursor(win_id, { action_start, column })

    -- Prevent switching to another buffer or window
    local group =
        vim.api.nvim_create_augroup("HarpoonSwapModal", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
        group = group,
        callback = function(ev)
            if ev.buf ~= bufnr then
                vim.schedule(function()
                    if vim.api.nvim_win_is_valid(win_id) then
                        vim.api.nvim_set_current_win(win_id)
                    end
                end)
            end
        end,
    })

    local function close(choice)
        if vim.api.nvim_win_is_valid(win_id) then
            vim.api.nvim_win_close(win_id, true)
        end
        vim.api.nvim_del_augroup_by_id(group)
        on_choice(choice)
    end

    local choice_map = {
        ACTIONS.READONLY,
        ACTIONS.EDIT,
        ACTIONS.RECOVER,
        ACTIONS.DELETE,
        ACTIONS.ABORT,
    }

    -- <CR> to confirm
    vim.keymap.set("n", "<CR>", function()
        local lnum = vim.fn.line(".")
        local idx = lnum - action_start + 1
        local choice = choice_map[idx]
        if choice then
            close(choice)
        end
    end, { buffer = bufnr, nowait = true })

    -- j/k navigation
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
        O = ACTIONS.READONLY,
        o = ACTIONS.READONLY,
        E = ACTIONS.EDIT,
        e = ACTIONS.EDIT,
        R = ACTIONS.RECOVER,
        r = ACTIONS.RECOVER,
        D = ACTIONS.DELETE,
        d = ACTIONS.DELETE,
        A = ACTIONS.ABORT,
        a = ACTIONS.ABORT,
        Q = ACTIONS.ABORT,
        q = ACTIONS.ABORT,
    }
    for key, action in pairs(hotkeys) do
        vim.keymap.set("n", key, function()
            close(action)
        end, { buffer = bufnr, nowait = true })
    end

    vim.keymap.set("n", "<Esc>", function()
        close(ACTIONS.ABORT)
    end, { buffer = bufnr, nowait = true })
end

return {
    show = show,
    ACTIONS = ACTIONS,
}
