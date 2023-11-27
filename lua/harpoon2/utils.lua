local Path = require("plenary.path")

local M = {}
function M.normalize_path(item)
    return Path:new(item):make_relative(M.project_key())
end

function M.is_white_space(str)
    return str:gsub("%s", "") == ""
end

return M
