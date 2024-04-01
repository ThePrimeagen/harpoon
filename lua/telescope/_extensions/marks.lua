local action_state = require("telescope.actions.state")
local action_utils = require("telescope.actions.utils")
local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local harpoon = require("harpoon")

local generate_new_finder = function()
    local list = harpoon:list()
    local results = list.items
    local index_entry_width = math.log(#results, 10) + 1

    return finders.new_table({
        results = results,
        entry_maker = function(item)
            local line = list.config.display(item)
            local displayer = entry_display.create({
                separator = " ",
                items = {
                    { width = index_entry_width },
                    { remaining = true },
                },
            })
            local make_display = function(entry)
                return displayer({
                    tostring(entry.index),
                    line,
                })
            end

            return {
                value = item,
                ordinal = line,
                display = make_display,
                lnum = item.row,
                col = item.col,
                filename = item.value,
            }
        end,
    })
end

local delete_harpoon_mark = function(prompt_bufnr)
    local confirmation =
        vim.fn.input(string.format("Delete current mark(s)? [y/n]: "))
    if
        string.len(confirmation) == 0
        or string.sub(string.lower(confirmation), 0, 1) ~= "y"
    then
        print(string.format("Didn't delete mark"))
        return
    end

    local selection = action_state.get_selected_entry()
    harpoon:list():remove(selection.value)

    local function get_selections()
        local results = {}
        action_utils.map_selections(prompt_bufnr, function(entry)
            table.insert(results, entry)
        end)
        return results
    end

    local selections = get_selections()
    for _, current_selection in ipairs(selections) do
        harpoon:list():remove(current_selection.value)
    end

    local current_picker = action_state.get_current_picker(prompt_bufnr)
    current_picker:refresh(generate_new_finder(), { reset_prompt = true })
end

local move_mark_up = function(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    local length = harpoon:list():length()

    if selection.index == length then
        return
    end

    local mark_list = harpoon:list().items

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
    local mark_list = harpoon:list().items
    table.remove(mark_list, selection.index)
    table.insert(mark_list, selection.index - 1, selection.value)
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    current_picker:refresh(generate_new_finder(), { reset_prompt = true })
end

return function(opts)
    opts = opts or {}

    pickers
        .new(opts, {
            prompt_title = "Harpoon",
            finder = generate_new_finder(),
            sorter = conf.generic_sorter(opts),
            previewer = conf.grep_previewer(opts),
            attach_mappings = function(_, map)
                map("i", "<c-d>", delete_harpoon_mark)
                map("n", "<c-d>", delete_harpoon_mark)

                map("i", "<c-p>", move_mark_up)
                map("n", "<c-p>", move_mark_up)

                map("i", "<c-n>", move_mark_down)
                map("n", "<c-n>", move_mark_down)
                return true
            end,
        })
        :find()
end
