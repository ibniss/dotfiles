local RootUtil = require('ibniss.util.root')

local M = {}

---@param opts? {relative: "cwd"|"root", modified_hl: string?}
function M.pretty_path(opts)
    opts = vim.tbl_extend('force', {
        relative = 'cwd',
        modified_hl = 'Constant',
    }, opts or {})

    return function(self)
        local path = vim.fn.expand('%:p') --[[@as string]]

        if path == '' then return '' end
        local root = RootUtil.get({ normalize = true })
        local cwd = RootUtil.cwd()

        if opts.relative == 'cwd' and path:find(cwd, 1, true) == 1 then
            path = path:sub(#cwd + 2)
        end

        local sep = package.config:sub(1, 1)
        local parts = vim.split(path, '[\\/]')
        if #parts > 3 then
            parts = { parts[1], '…', parts[#parts - 1], parts[#parts] }
        end

        if opts.modified_hl and vim.bo.modified then
            parts[#parts] = M.format(self, parts[#parts], opts.modified_hl)
        end

        return table.concat(parts, sep)
    end
end

---@param opts? {cwd:false, subdirectory: true, parent: true, other: true, icon?:string}
function M.root_dir(opts)
    local special_hl = vim.api.nvim_get_hl(0, { name = 'Special' }).fg

    opts = vim.tbl_extend('force', {
        cwd = false,
        subdirectory = true,
        parent = true,
        other = true,
        icon = '󱉭 ',
        color = { fg = string.format('#%06x', special_hl) },
    }, opts or {})

    local function get()
        local cwd = RootUtil.cwd()
        local root = RootUtil.get({ normalize = true })
        local name = vim.fs.basename(root)

        if root == cwd then
            -- root is cwd
            return opts.cwd and name
        elseif root:find(cwd, 1, true) == 1 then
            -- root is subdirectory of cwd
            return opts.subdirectory and name
        elseif cwd:find(root, 1, true) == 1 then
            -- root is parent directory of cwd
            return opts.parent and name
        else
            -- root and cwd are not related
            return opts.other and name
        end
    end

    return {
        function() return (opts.icon and opts.icon .. ' ') .. get() end,
        cond = function() return type(get()) == 'string' end,
        color = opts.color,
    }
end

return M
