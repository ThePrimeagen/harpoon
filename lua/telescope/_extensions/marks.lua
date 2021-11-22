local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local sorters = require("telescope.sorters")
local harpoon = require("harpoon")
local entry_display = require("telescope.pickers.entry_display")

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
    }):find()
end
