local utils = require("harpoon.utils")

local M = {}

function M.default()
    return function(file)
        return file
    end
end

function M.keep_only_last_two_parts(payload)
    local include = payload.include
    return function(file)
        local parts = vim.split(file, "/")
        local c = 0
        local n = #parts

        local mapped_parts = {}

        for _, part in ipairs(parts) do
            c = c + 1
            local mapped = part

            -- while looping through all the parts, keep
            -- only the last two items
            -- Or those in the include list
            if c <= n - 2 then
                local part_to_replace = nil
                if type(include) == "string" then
                    part_to_replace = part:find(include) and include
                elseif type(include) == "table" then
                    for _, value in ipairs(include) do
                        if part:find(value) then
                            part_to_replace = value
                            break
                        end
                    end
                end

                mapped = part_to_replace ~= nil and part_to_replace or ""
            end

            if not utils.is_white_space(mapped) then
                table.insert(mapped_parts, mapped)
            end
        end

        return table.concat(
            utils.remove_contiguous_duplicates(mapped_parts),
            "/"
        )
    end
end

function M.minify_full_path_and_keep_last_two_parts(payload)
    local include = payload.include
    return function(file)
        local parts = vim.split(file, "/")
        local c = 0
        local n = #parts

        local mapped_parts = {}

        for _, part in ipairs(parts) do
            c = c + 1
            local mapped = part

            -- while looping through all the parts, keep
            -- the last two items
            -- and minify other parts
            if c <= n - 2 then
                local part_to_replace = nil
                if type(include) == "string" then
                    part_to_replace = part:find(include) and include
                elseif type(include) == "table" then
                    for _, value in ipairs(include) do
                        if part:find(value) then
                            part_to_replace = value
                            break
                        end
                    end
                end

                mapped = part_to_replace ~= nil and part_to_replace
                    or string.lower(string.sub(part, 1, 1))
            end

            if not utils.is_white_space(mapped) then
                table.insert(mapped_parts, mapped)
            end
        end

        return table.concat(mapped_parts, "/")
    end
end

return M
