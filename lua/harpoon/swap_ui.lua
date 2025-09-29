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
    local info_height = 10
    local prompt_height = 3
    local row = math.floor((vim.o.lines - (info_height + prompt_height)) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    -- Info window
    local info_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[info_buf].bufhidden = "wipe"
    vim.bo[info_buf].modifiable = false
    local info_lines = {
        "E325: ATTENTION",
        "",
        "Found a swap file: " .. swap,
        "While opening file: " .. filepath,
        "",
        "Choose an action by typing the letter:",
        " [O]pen Read-only",
        " (E)dit anyway",
        " (R)ecover",
        " (D)elete swap & edit",
        " (A)bort / (Q)uit",
    }
    vim.api.nvim_buf_set_lines(info_buf, 0, -1, false, info_lines)

    local info_win = vim.api.nvim_open_win(info_buf, false, {
        relative = "editor",
        width = width,
        height = info_height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = "Info",
        title_pos = "center",
    })

    -- Prompt window
    local prompt_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[prompt_buf].bufhidden = "wipe"
    vim.bo[prompt_buf].modifiable = false
    vim.api.nvim_buf_set_lines(prompt_buf, 0, -1, false, { "Press a key: " })

    local prompt_win = vim.api.nvim_open_win(prompt_buf, true, {
        relative = "editor",
        width = width,
        height = prompt_height,
        row = row + info_height,
        col = col,
        style = "minimal",
        border = "rounded",
        title = "Prompt",
        title_pos = "center",
    })

    local allowed_keys = {
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

    local function finish(choice)
        vim.api.nvim_win_close(prompt_win, true)
        vim.api.nvim_win_close(info_win, true)
        on_choice(choice)
    end

    -- Set keymaps in prompt buffer only
    for key, action in pairs(allowed_keys) do
        vim.keymap.set("n", key, function()
            finish(action)
        end, { buffer = prompt_buf })
    end

    -- Block all other keys in prompt buffer
    vim.keymap.set("n", "<Any>", function() end, { buffer = prompt_buf })
end

return M
