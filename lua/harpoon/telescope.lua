-- telescope.lua
--
-- A customizable finder for telescope.nvim
-- (https://github.com/nvim-telescope/telescope.nvim)
--
-- Usage: :lua require("harpoon.telescope").marks({results_title = 'My Title'})
local previewers = require('telescope.previewers')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local sorters = require('telescope.sorters')
local harpoon = require('harpoon')

local default_options = {
    results_title = 'Harpoon',
    finder = finders.new_table(harpoon.get_mark_config().marks),
    sorter = sorters.get_fuzzy_file(),
    previewer = previewers.vim_buffer_cat.new {}
}

local function merge_tables(tbl1, tbl2)
  local merged = {}

  for k, v in pairs(tbl1) do
    merged[k] = v
  end

  for k, v in pairs(tbl2) do
    merged[k] = v
  end

  return merged
end

M = {}

function M.marks(opts)
    opts = opts or {}
    local picker_options = merge_tables(default_options, opts)

    pickers.new(picker_options):find()
end

return M
