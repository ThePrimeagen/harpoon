local harpoon = require("harpoon")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local action_utils = require("telescope.actions.utils")
local conf = require("telescope.config").values
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local pickers = require("telescope.pickers")
local entry_display = require("telescope.pickers.entry_display")
local utils = require("telescope.utils")
local strings = require("plenary.strings")

local function make_results(list)
    local results = {}
    for _, item in pairs(list) do
        table.insert(results, {
            value = item.value,
            context = {
                row = item.context.row,
                col = item.context.col,
            },
        })
    end
    return results
end

local generate_new_finder = function(opts)
    local results = make_results(harpoon:list().items)
    local results_idx_str_len = string.len(tostring(#results))
    local make_file_entry = make_entry.gen_from_file(opts)
    local disable_devicons = opts.disable_devicons

    local icon_width = 0
    if not disable_devicons then
        local icon, _ = utils.get_devicons("fname", disable_devicons)
        icon_width = strings.strdisplaywidth(icon)
    end

    return finders.new_table({
        results = results,
        entry_maker = function(harpoon_item)
            local entry = make_file_entry(harpoon_item.value) -- value => path
            local icon, hl_group = utils.get_devicons(entry.filename, disable_devicons)
            local display_config = nil
            if not disable_devicons then
                display_config = {
                    separator = " ",
                    items = {
                        { width = results_idx_str_len },
                        { width = icon_width },
                        { remaining = true },
                        { width = 6 },
                    },
                }
            else
                display_config = {
                    separator = " ",
                    items = {
                        { width = results_idx_str_len },
                        { remaining = true },
                        { width = 6 },
                    },
                }
            end
            local displayer = entry_display.create(display_config)
            entry.display = function(et)
                local et_idx_str = tostring(et.index)
                local et_idx_str_len = string.len(et_idx_str)
                local et_idx_lpad = string.rep(" ", results_idx_str_len - et_idx_str_len)
                local path_to_display = utils.transform_path(opts, et.value)
                local entry_values = nil
                local row = harpoon_item.context.row
                local column = harpoon_item.context.col + 1
                if not disable_devicons then
                    entry_values = {
                        { et_idx_lpad .. et_idx_str },
                        { icon, hl_group },
                        { path_to_display },
                        { row .. ":" .. column },
                    }
                else
                    entry_values = {
                        { et_idx_lpad .. et_idx_str },
                        { path_to_display },
                        { row .. ":" .. column },
                    }
                end
                return displayer(entry_values)
            end
            return entry
        end,
    })
end

local delete_mark_selections = function(prompt_bufnr)
    local selections = {}
    action_utils.map_selections(prompt_bufnr, function(entry)
        table.insert(selections, entry)
    end)
    table.sort(selections, function(a, b)
        return a.index < b.index
    end)

    local count = 0

    if #selections > 0 then
        -- delete marks from multi-selection
        for i = #selections, 1, -1 do
            local selection = selections[i]
            harpoon:list():removeAt(selection.index)
            count = count + 1
        end
    else
        -- delete marks from single-selection
        local selection = action_state.get_selected_entry()
        if selection ~= nil then
            harpoon:list():removeAt(selection.index)
            count = count + 1
        else
            return 0
        end
    end

    -- delete picker-selections
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    current_picker:delete_selection(function() end)

    return count
end

local delete_mark_selections_prompt = function(prompt_bufnr)
    vim.ui.input({
        prompt = "Delete selected marks? [Yes/no]: ",
        default = "y",
    }, function(input)
        if input == nil then
            return
        end

        local input_str = string.lower(input)
        if input_str == "y" or input_str == "yes" then
            local deletion_count = delete_mark_selections(prompt_bufnr)
            if deletion_count == 0 then
                print("No marks deleted")
            elseif deletion_count == 1 then
                print("Deleted 1 mark")
            else
                print("Deleted " .. deletion_count .. " marks")
            end
        else
            print("No action taken")
        end
    end)
end

local move_mark_next = function(prompt_bufnr)
    -- get current index
    local current_selection = action_state.get_selected_entry()
    local current_index = current_selection.index

    -- get next index
    actions.move_selection_next(prompt_bufnr)
    local next_selection = action_state.get_selected_entry()
    local next_index = next_selection.index

    -- swap harpoon-items
    local mark_list = harpoon:list().items
    local current_item = mark_list[current_index]
    local next_item = mark_list[next_index]
    mark_list[current_index] = next_item
    mark_list[next_index] = current_item

    -- swap telescope-entries
    local current_value = current_selection.value
    local next_value = next_selection.value
    local current_display = current_selection.display
    local next_display = next_selection.display
    current_selection.value = next_value
    next_selection.value = current_value
    current_selection.display = next_display
    next_selection.display = current_display

    -- refresh picker
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    local selection_row = current_picker:get_selection_row()
    current_picker:refresh()

    vim.wait(1) -- wait for refresh

    -- select row
    current_picker:set_selection(selection_row)
end

local move_mark_previous = function(prompt_bufnr)
    -- get current index
    local current_selection = action_state.get_selected_entry()
    local current_index = current_selection.index

    -- get previous index
    actions.move_selection_previous(prompt_bufnr)
    local previous_selection = action_state.get_selected_entry()
    local previous_index = previous_selection.index

    -- swap harpoon items
    local mark_list = harpoon:list().items
    local current_item = mark_list[current_index]
    local previous_item = mark_list[previous_index]
    mark_list[current_index] = previous_item
    mark_list[previous_index] = current_item

    -- swap telescope entries
    local current_value = current_selection.value
    local previous_value = previous_selection.value
    local current_display = current_selection.display
    local previous_display = previous_selection.display
    current_selection.value = previous_value
    previous_selection.value = current_value
    current_selection.display = previous_display
    previous_selection.display = current_display

    -- refresh picker
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    local selection_row = current_picker:get_selection_row()
    current_picker:refresh()

    vim.wait(1) -- wait for refresh

    -- select row
    current_picker:set_selection(selection_row)
end

return function(opts)
    opts = opts or {}
    pickers
        .new(opts, {
            prompt_title = "Harpoon Marks",
            finder = generate_new_finder(opts),
            sorter = conf.generic_sorter(opts),
            previewer = conf.file_previewer(opts),
            attach_mappings = function(_, map)
                map("i", "<c-d>", delete_mark_selections_prompt)
                map("n", "<c-d>", delete_mark_selections_prompt)
                map("i", "<c-p>", move_mark_previous)
                map("n", "<c-p>", move_mark_previous)
                map("i", "<c-n>", move_mark_next)
                map("n", "<c-n>", move_mark_next)
                return true
            end,
        })
        :find()
end
