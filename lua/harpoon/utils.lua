local M = {}

function M.is_white_space(str)
    return str:gsub("%s", "") == ""
end

return M
