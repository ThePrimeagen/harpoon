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

    local lines = {
        "E325: ATTENTION",
        "",
        "Found a swap file with the name: " .. swap,
        "",
        "While opening file:" .. filepath,
        "",
        "",
        "Choose an action:",
        " [O]pen Read-only",
        " (E)dit anyway (Vim will prompt again)",
        " (R)ecover",
        " (D)elete swap & edit",
        " (A)bort",
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
        title_pos = "center",
    })

    -- Dynamically map line numbers to actions
    local action_start = 9 -- first line of actions in `lines` table
    local choice_map = {
        "readonly",
        "edit",
        "recover",
        "delete",
        "abort",
    }

    vim.keymap.set("n", "<CR>", function()
        local lnum = vim.fn.line(".")
        local idx = lnum - action_start + 1
        local choice = choice_map[idx]
        print("Select: " .. choice)
        if choice then
            vim.api.nvim_win_close(win_id, true)
            on_choice(choice)
        end
    end, { buffer = bufnr, nowait = true })

    vim.keymap.set("n", "q", function()
        on_choice("abort")
        vim.api.nvim_win_close(win_id, true)
    end, { buffer = bufnr, nowait = true })
end

return show_swap_ui
