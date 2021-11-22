local action_set = require("telescope.actions.set")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local sorters = require("telescope.sorters")
local harpoon = require("harpoon")
local harpoon_mark = require("harpoon.mark")

local function filter_empty_string(list)
    local next = {}
    for idx = 1, #list do
        if list[idx].filename ~= "" then
            table.insert(next, list[idx])
        end
    end

    return next
end

local generate_new_finder = function()
    return finders.new_table({
        results = filter_empty_string(harpoon.get_mark_config().marks),
        entry_maker = function(entry)
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
                    entry.filename,
                })
            end
            local line = entry.filename .. ":" .. entry.row .. ":" .. entry.col
            return {
                value = entry,
                ordinal = line,
                display = make_display,
                lnum = entry.row,
                col = entry.col,
                filename = entry.filename,
            }
        end,
    })
end

local delete_harpoon_mark = function(prompt_bufnr)
    local confirmation = vim.fn.input(string.format("Delete current mark? [y/n]: "))
    if string.len(confirmation) == 0 or string.sub(string.lower(confirmation), 0, 1) ~= "y" then
        print(string.format("Didn't delete mark"))
        return
    end
    local selection = action_state.get_selected_entry()
    harpoon_mark.rm_file(selection.filename)
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    current_picker:refresh(generate_new_finder(), { reset_prompt = true })
end

local move_mark_up = function(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    if harpoon_mark.get_length() == selection.index then
        return
    end
    local mark_list = harpoon.get_mark_config().marks
    table.remove(mark_list, selection.index)
    table.insert(mark_list, selection.index + 1, selection.value)
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    current_picker:refresh(generate_new_finder(), { reset_prompt = true })
end

local move_mark_down = function(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    if selection.index == 1 then
        return
    end
    local mark_list = harpoon.get_mark_config().marks
    table.remove(mark_list, selection.index)
    table.insert(mark_list, selection.index - 1, selection.value)
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    current_picker:refresh(generate_new_finder(), { reset_prompt = true })
end

return function(opts)
    opts = opts or {}

    pickers.new(opts, {
        prompt_title = "harpoon marks",
        finder = generate_new_finder(),
        sorter = sorters.get_fuzzy_file(),
        previewer = previewers.vim_buffer_cat.new({}),
        attach_mappings = function(_, map)
            map("i", "<c-d>", delete_harpoon_mark)
            map("n", "<c-d>", delete_harpoon_mark)
            map("i", "<c-p>", move_mark_up)
            map("n", "<c-p>", move_mark_up)
            map("i", "<c-n>", move_mark_down)
            map("n", "<c-n>", move_mark_down)
            return true
        end,
    }):find()
end
