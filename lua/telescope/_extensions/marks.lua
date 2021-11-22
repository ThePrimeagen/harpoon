local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local sorters = require("telescope.sorters")
local harpoon = require("harpoon")
local harpoon_mark = require("harpoon.mark")

local delete_harpoon_mark = function(prompt_bufnr)
    local confirmation = vim.fn.input(string.format("Delete current mark? [y/n]: "))
    if string.len(confirmation) == 0 or string.sub(string.lower(confirmation), 0, 1) ~= "y" then
        print(string.format("Didn't delete mark"))
        return
    end
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    current_picker:delete_selection(function(selection)
        harpoon_mark.rm_file(selection.filename)
    end)
end

return function(opts)
    opts = opts or {}

    pickers.new(opts, {
        prompt_title = "harpoon marks",
        finder = finders.new_table({
            results = harpoon.get_mark_config().marks,
            entry_maker = function(mark)
                local displayer = entry_display.create({
                    separator = " - ",
                    items = {
                        { width = 2 },
                        { width = 50 },
                        { remaining = true },
                    },
                })
                local make_display = function(entry)
                    return displayer({
                        tostring(entry.index),
                        mark.filename,
                    })
                end
                local line = mark.filename .. ":" .. mark.row .. ":" .. mark.col
                return {
                    value = mark,
                    ordinal = line,
                    display = make_display,
                    lnum = mark.row,
                    col = mark.col,
                    filename = mark.filename,
                }
            end,
        }),
        sorter = sorters.get_fuzzy_file(),
        previewer = previewers.vim_buffer_cat.new({}),
        attach_mappings = function(_, map)
            map("i", "<c-d>", delete_harpoon_mark)
            map("n", "<c-d>", delete_harpoon_mark)
            return true
        end,
    }):find()
end
