local Data = require("harpoon.data")

local M = {}

M.created_files = {}

local checkpoint_file = nil
local checkpoint_file_bufnr = nil
function M.create_checkpoint_file()
    checkpoint_file = os.tmpname()
    checkpoint_file_bufnr = M.create_file(checkpoint_file, { "test" })
end

function M.return_to_checkpoint()
    if checkpoint_file_bufnr == nil then
        return
    end

    vim.api.nvim_set_current_buf(checkpoint_file_bufnr)
    M.clean_files()
end

---@param name string
function M.before_each(name)
    return function()
        Data.set_data_path(name)
        Data.__dangerously_clear_data()

        require("plenary.reload").reload_module("harpoon")
        Data = require("harpoon.data")
        Data.set_data_path(name)
        local harpoon = require("harpoon")

        M.return_to_checkpoint()

        harpoon:setup({
            settings = {
                key = function()
                    return "testies"
                end,
            },
        })
    end
end

function M.clean_files()
    for _, bufnr in ipairs(M.created_files) do
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end

    M.created_files = {}
end

---@param name string
---@param contents string[]
function M.create_file(name, contents, row, col)
    local bufnr = vim.fn.bufnr(name, true)
    vim.api.nvim_buf_set_option(bufnr, "bufhidden", "hide")
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_buf_set_text(0, 0, 0, 0, 0, contents)
    if row then
        vim.api.nvim_win_set_cursor(0, { row or 1, col or 0 })
    end

    table.insert(M.created_files, bufnr)
    return bufnr
end

---@param count number
---@param list HarpoonList
function M.fill_list_with_files(count, list)
    local files = {}

    for _ = 1, count do
        local name = os.tmpname()
        table.insert(files, name)
        M.create_file(name, { "test" })
        list:append()
    end

    return files
end

return M
