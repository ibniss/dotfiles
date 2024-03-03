require("ibniss")

--- autocmd - highlight text being copied
local yank_group = vim.api.nvim_create_namespace('yank')
vim.api.nvim_create_autocmd('TextYankPost', {
    group = yank_group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch', -- same style as incremental search results
            timeout = 40,          -- 40ms
        })
    end,
})

--- autocmd - remove trailing whitespace
local group = vim.api.nvim_create_namespace("ibniss")
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    group = group,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})
