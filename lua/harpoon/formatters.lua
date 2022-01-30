local utils = require("harpoon.utils")

local M = {}

function M.keep_last_two_pieces(payload)
    local include = payload.include
    return function(file)
        local parts = vim.split(file, "/")
        local c = 0
        local n = #parts

        local mapped_parts = {}

        for k, part in ipairs(parts) do
            c = c + 1
            local mapped = part

            -- while looping through all the parts, keep
            -- only the last two items
            -- Or those in the include list
            if c <= n - 2 then
                if part:find("test") then
                    mapped = "test"
                else
                    mapped = ''
                    -- mapped = string.lower(string.sub(part, 1, 1))
                end
            end

            if not utils.is_white_space(mapped) then
                table.insert(mapped_parts, mapped)
            end
        end

        return table.concat(
            utils.remove_contiguous_duplicates(mapped_parts)
        , "/")
    end
end

return M
