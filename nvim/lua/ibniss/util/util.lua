local M = {}

function M.is_win() return vim.loop.os_uname().sysname:find('Windows') ~= nil end

---@return string
function M.norm(path)
    if path:sub(1, 1) == '~' then
        local home = vim.loop.os_homedir()
        if home:sub(-1) == '\\' or home:sub(-1) == '/' then
            home = home:sub(1, -2)
        end
        path = home .. path:sub(2)
    end
    path = path:gsub('\\', '/'):gsub('/+', '/')
    return path:sub(-1) == '/' and path:sub(1, -2) or path
end

return M
