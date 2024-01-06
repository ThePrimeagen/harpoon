local Dev = require("harpoon.dev")
local log = Dev.log

local M = {}

local function get_color(group, attr)
    return vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(group)), attr)
end

local function shorten_filenames(filenames)
    local shortened = {}

    local counts = {}
    for _, file in ipairs(filenames) do
        local name = vim.fn.fnamemodify(file.filename, ":t")
        counts[name] = (counts[name] or 0) + 1
    end

    for _, file in ipairs(filenames) do
        local name = vim.fn.fnamemodify(file.filename, ":t")

        if counts[name] == 1 then
            table.insert(
                shortened,
                { filename = vim.fn.fnamemodify(name, ":t") }
            )
        else
            table.insert(shortened, { filename = file.filename })
        end
    end

    return shortened
end

function M.setup(opts)
    function _G.tabline()
        local tabs =
            shorten_filenames(require("harpoon").get_mark_config().marks)
        local tabline = ""

        local index = require("harpoon.mark").get_index_of(vim.fn.bufname())

        for i, tab in ipairs(tabs) do
            local is_current = i == index

            local label

            if tab.filename == "" or tab.filename == "(empty)" then
                label = "(empty)"
                is_current = false
            else
                label = tab.filename
            end

            if is_current then
                tabline = tabline
                    .. "%#HarpoonNumberActive#"
                    .. (opts.tabline_prefix or "   ")
                    .. i
                    .. " %*"
                    .. "%#HarpoonActive#"
            else
                tabline = tabline
                    .. "%#HarpoonNumberInactive#"
                    .. (opts.tabline_prefix or "   ")
                    .. i
                    .. " %*"
                    .. "%#HarpoonInactive#"
            end

            tabline = tabline .. label .. (opts.tabline_suffix or "   ") .. "%*"

            if i < #tabs then
                tabline = tabline .. "%T"
            end
        end

        return tabline
    end

    vim.opt.showtabline = 2

    vim.o.tabline = "%!v:lua.tabline()"

    vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("harpoon", { clear = true }),
        pattern = { "*" },
        callback = function()
            local color = get_color("HarpoonActive", "bg#")

            if color == "" or color == nil then
                vim.api.nvim_set_hl(0, "HarpoonInactive", { link = "Tabline" })
                vim.api.nvim_set_hl(0, "HarpoonActive", { link = "TablineSel" })
                vim.api.nvim_set_hl(
                    0,
                    "HarpoonNumberActive",
                    { link = "TablineSel" }
                )
                vim.api.nvim_set_hl(
                    0,
                    "HarpoonNumberInactive",
                    { link = "Tabline" }
                )
            end
        end,
    })

    log.debug("setup(): Tabline Setup", opts)
end

return M
