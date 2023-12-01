local utils = require("harpoon.utils")
local HarpoonGroup = require("harpoon.autocmd")

local M = {}

local HARPOON_MENU = "__harpoon-menu__"

-- simple reason here is that if we are deving harpoon, we will create several
-- ui objects, each with their own buffer, which will cause the name to be
-- duplicated and then we will get a vim error on nvim_buf_set_name
local harpoon_menu_id = math.random(1000000)

local function get_harpoon_menu_name()
    harpoon_menu_id = harpoon_menu_id + 1
    return HARPOON_MENU .. harpoon_menu_id
end

---TODO: I don't know how to do what i want to do, but i want to be able to
---make this so we use callbacks for these buffer actions instead of using
---strings back into the ui.  it feels gross and it puts odd coupling
---@param bufnr number
function M.setup_autocmds_and_keymaps(bufnr)
    local curr_file = vim.api.nvim_buf_get_name(0)
    local cmd = string.format(
        "autocmd Filetype harpoon "
            .. "let path = '%s' | call clearmatches() | "
            -- move the cursor to the line containing the current filename
            .. "call search('\\V'.path.'\\$') | "
            -- add a hl group to that line
            .. "call matchadd('HarpoonCurrentFile', '\\V'.path.'\\$')",
        curr_file:gsub("\\", "\\\\")
    )
    vim.cmd(cmd)

    if vim.api.nvim_buf_get_name(bufnr) == "" then
        vim.api.nvim_buf_set_name(bufnr, get_harpoon_menu_name())
    end

    vim.api.nvim_buf_set_option(bufnr, "filetype", "harpoon")
    vim.api.nvim_buf_set_option(bufnr, "buftype", "acwrite")
    vim.api.nvim_buf_set_option(bufnr, "bufhidden", "delete")

    vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        "q",
        "<Cmd>lua require('harpoon').ui:toggle_quick_menu()<CR>",
        { silent = true }
    )
    vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        "<ESC>",
        "<Cmd>lua require('harpoon').ui:toggle_quick_menu()<CR>",
        { silent = true }
    )
    vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        "<CR>",
        "<Cmd>lua require('harpoon').ui:select_menu_item()<CR>",
        {}
    )

    -- TODO: Do we want this?  is this a thing?
    -- its odd... why save on text change? shouldn't we wait until close / w / esc?
    --[[
    if global_config.save_on_change then
        vim.cmd(
            string.format(
                "autocmd TextChanged,TextChangedI <buffer=%s> lua require('harpoon').ui:save()",
                bufnr
            )
        )
    end
    --]]
    vim.cmd(
        string.format(
            "autocmd BufModifiedSet <buffer=%s> set nomodified",
            bufnr
        )
    )

    vim.api.nvim_create_autocmd({ "BufWriteCmd" }, {
        group = HarpoonGroup,
        pattern = "__harpoon*",
        callback = function()
            require("harpoon").ui:save()
            vim.schedule(function()
                require("harpoon").ui:toggle_quick_menu()
            end)
        end,
    })

    vim.api.nvim_create_autocmd({ "BufLeave" }, {
        group = HarpoonGroup,
        pattern = "__harpoon*",
        callback = function()
            require("harpoon").ui:toggle_quick_menu()
        end,
    })
end

---@param bufnr number
function M.get_contents(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
    local indices = {}

    for _, line in pairs(lines) do
        if not utils.is_white_space(line) then
            table.insert(indices, line)
        end
    end

    return indices
end

function M.set_contents(bufnr, contents)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, contents)
end

return M
