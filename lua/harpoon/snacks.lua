local M = {}

local harpoon = require("harpoon")

local changed = true
local function notify()
    changed = true
end

function M.setup()
    if not Snacks then
        error("harpoon requires folke/snacks.nvim")
    end
    Snacks.picker.sources.harpoon = {
        finder = function()
            local output = {}
            for _, item in ipairs(harpoon:list().items) do
                if item and item.value:match("%S") then
                    table.insert(output, {
                        text = item.value,
                        file = item.value,
                        pos = { item.context.row, item.context.col },
                    })
                end
            end
            return output
        end,
        filter = {
            -- reruns the finder on changes
            transform = function()
                if changed then
                    changed = false
                    return true
                end
            end,
        },
        format = function(item)
            return {
                { item.text },
                { ":", "SnacksPickerDelim" },
                { tostring(item.pos[1]), "SnacksPickerRow" },
                { ":", "SnacksPickerDelim" },
                { tostring(item.pos[2]), "SnacksPickerCol" },
            }
        end,
        preview = function(ctx)
            if Snacks.picker.util.path(ctx.item) then
                return Snacks.picker.preview.file(ctx)
            else
                return Snacks.picker.preview.none(ctx)
            end
        end,
        confirm = "jump",
    }
    -- rerun the finder on changes
    harpoon:extend({
        REPLACE = notify,
        ADD = notify,
        SELECT = notify,
        REMOVE = notify,
        POSITION_UPDATED = notify,
        LIST_CHANGE = notify,
        REORDER = notify,
    })
end

return M
