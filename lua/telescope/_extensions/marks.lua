local action_state = require("telescope.actions.state")
local action_utils = require("telescope.actions.utils")
local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local utils = require("telescope.utils")
local make_entry = require("telescope.make_entry")
local strings = require("plenary.strings")
local conf = require("telescope.config").values
local harpoon = require("harpoon")

local function filter_empty_string(list)
    local next = {}
    for idx = 1, #list do
        if list[idx].value ~= "" then
            local item = list[idx]
            table.insert(next, {
                value = item.value,
                context = {
                    row = item.context.row,
                    col = item.context.col,
                },
            })
        end
    end

    return next
end

local generate_new_finder = function(opts)
    local results = filter_empty_string(harpoon:list().items)
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
                if not disable_devicons then
                    entry_values = {
                        { et_idx_lpad .. et_idx_str },
                        { icon, hl_group },
                        { path_to_display },
                        { harpoon_item.context.row .. ":" .. harpoon_item.context.col },
                    }
                else
                    entry_values = {
                        { et_idx_lpad .. et_idx_str },
                        { path_to_display },
                        { harpoon_item.context.row .. ":" .. harpoon_item.context.col },
                    }
                end
                return displayer(entry_values)
            end
            return entry
        end,
    })
end

local delete_harpoon_mark = function(prompt_bufnr, opts)
    local selections = {}
    action_utils.map_selections(prompt_bufnr, function(entry)
        table.insert(selections, entry)
    end)
    table.sort(selections, function(a, b)
        return a.index < b.index
    end)

    local count = 0

    if #selections > 0 then
        for i = #selections, 1, -1 do
            local selection = selections[i]
            harpoon:list():removeAt(selection.index)
            count = count + 1
        end
    else
        local selection = action_state.get_selected_entry()
        if selection ~= nil then
            harpoon:list():removeAt(selection.index)
            count = count + 1
        else
            return 0
        end
    end

    local current_picker = action_state.get_current_picker(prompt_bufnr)
    current_picker:refresh(generate_new_finder(opts), { reset_prompt = true })

    return count
end

local delete_harpoon_mark_prompt = function(opts)
    return function(prompt_bufnr)
        vim.ui.input({
            prompt = "Delete selected marks? [Yes/no]: ",
            default = "y",
        }, function(input)
            if input == nil then
                return
            end

            local input_str = string.lower(input)
            if input_str == "y" or input_str == "yes" then
                local deletion_count = delete_harpoon_mark(prompt_bufnr, opts)
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
end

local move_mark_up = function(opts)
    return function(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local length = harpoon:list():length()
        local current_index = selection.index
        if current_index == length then
            return
        end

        local mark_list = harpoon:list().items
        local current_item = mark_list[current_index]
        table.remove(mark_list, selection.index)
        table.insert(mark_list, selection.index + 1, current_item)

        local current_picker = action_state.get_current_picker(prompt_bufnr)
        current_picker:refresh(generate_new_finder(opts), { reset_prompt = true })
    end
end

local move_mark_down = function (opts)
    return function(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local current_index = selection.index
        if current_index == 1 then
            return
        end

        local mark_list = harpoon:list().items
        local current_item = mark_list[current_index]
        table.remove(mark_list, current_index)
        table.insert(mark_list, current_index - 1, current_item)

        local current_picker = action_state.get_current_picker(prompt_bufnr)
        current_picker:refresh(generate_new_finder(opts), { reset_prompt = true })
    end
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
                map("i", "<c-d>", delete_harpoon_mark_prompt(opts))
                map("n", "<c-d>", delete_harpoon_mark_prompt(opts))

                map("i", "<c-p>", move_mark_up(opts))
                map("n", "<c-p>", move_mark_up(opts))

                map("i", "<c-n>", move_mark_down(opts))
                map("n", "<c-n>", move_mark_down(opts))
                return true
            end,
        })
        :find()
end
