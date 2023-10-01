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
        local cfg = opts.global_settings
        local has_icons = cfg.tabline_icons

        for i, tab in ipairs(tabs) do
            local is_current = i == index

            local label

            if tab.filename == "" or tab.filename == "(empty)" then
                label = "(empty)"
                is_current = false
            else
                label = tab.filename
            end

            if has_icons then
                local extension = tab.filename:match("^.+(%..+)$") or ""
                local mime, color = require("nvim-web-devicons").get_icon(
                    tab.filename,
                    extension:sub(2, #extension),
                    { default = true }
                )

                if is_current then
                    tabline = tabline
                        .. "%#HarpoonNumberActive#"
                        .. (cfg.tabline_prefix or "   ")
                        .. i
                        .. " %*%#"
                        .. color
                        .. "#"
                        .. mime
                        .. "%*%#HarpoonActive# "
                else
                    tabline = tabline
                        .. "%#HarpoonNumberInactive#"
                        .. (cfg.tabline_prefix or "   ")
                        .. i
                        .. " %*%#"
                        .. color
                        .. "#"
                        .. mime
                        .. "%*"
                        .. "%#HarpoonInactive# "
                end
            else
                if is_current then
                    tabline = tabline
                        .. "%#HarpoonNumberActive#"
                        .. (cfg.tabline_prefix or "   ")
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
            end

            tabline = tabline .. label .. (cfg.tabline_suffix or "   ") .. "%*"

            if i < #tabs then
                tabline = tabline .. "%T"
            end
        end

        if (not index) and vim.fn.bufname() ~= "" then
            if cfg.tabline_show_current_buffer_not_added then
                local current_buffer_filename =
                    vim.fn.fnamemodify(vim.fn.bufname(), ":t")

                if has_icons then
                    local extension = current_buffer_filename:match(
                        "^.+(%..+)$"
                    ) or ""
                    -- local extension = tab.filename:match("^.+(%..+)$") or ""
                    local mime, color = require("nvim-web-devicons").get_icon(
                        current_buffer_filename,
                        extension:sub(2, #extension),
                        { default = true }
                    )

                    tabline = tabline
                        .. "%T"
                        .. "%#HarpoonNumberActive#"
                        .. (cfg.tabline_prefix or "   ")
                        .. "?"
                        .. " %*%#"
                        .. color
                        .. "#"
                        .. mime
                        .. "%*%#HarpoonActive# "
                        .. current_buffer_filename
                        .. (cfg.tabline_suffix or "   ")
                else
                    tabline = tabline
                        .. "%#HarpoonNumberActive#"
                        .. (cfg.tabline_prefix or "   ")
                        .. "?"
                        .. " %*"
                        .. "%#HarpoonActive#"
                        .. current_buffer_filename
                        .. (cfg.tabline_suffix or "   ")
                end
            end
        end

        if
            vim.fn.bufexists("#")
            and not (require("harpoon.mark").get_index_of(
                vim.fn.bufname("#") or ""
            ))
            and vim.fn.bufname("#") ~= ""
        then
            if cfg.tabline_show_previous_buffer then
                local previous_buffer_filename =
                    vim.fn.fnamemodify(vim.fn.bufname("#"), ":t")
                if cfg.tabline_icons then
                    local extension = previous_buffer_filename:match(
                        "^.+(%..+)$"
                    ) or ""
                    -- local extension = tab.filename:match("^.+(%..+)$") or ""
                    local mime, color = require("nvim-web-devicons").get_icon(
                        previous_buffer_filename,
                        extension:sub(2, #extension),
                        { default = true }
                    )

                    tabline = tabline
                        .. "%T"
                        .. "%#HarpoonNumberInactive#"
                        .. (cfg.tabline_prefix or "   ")
                        .. (cfg.tabline_previous_buffer_text or ":b#")
                        .. " %*%#"
                        .. color
                        .. "#"
                        .. mime
                        .. "%*%#HarpoonInactive# "
                        .. previous_buffer_filename
                        .. (cfg.tabline_suffix or "   ")
                else
                    tabline = tabline
                        .. "%#HarpoonNumberInactive#"
                        .. (cfg.tabline_prefix or "   ")
                        .. (cfg.tabline_previous_buffer_text or ":b#")
                        .. " %*"
                        .. "%#HarpoonInactive#"
                        .. previous_buffer_filename
                        .. (cfg.tabline_suffix or "   ")
                end
            end
        end

        tabline = tabline .. "%*"

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
