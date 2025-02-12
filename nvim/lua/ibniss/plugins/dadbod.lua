return {
    'kristijanhusak/vim-dadbod-ui',
    dependencies = {
        { 'tpope/vim-dadbod', lazy = true },
        {
            'kristijanhusak/vim-dadbod-completion',
            lazy = true,
            ft = { 'sql', 'mysql', 'plsql' },
        },
    },
    config = function()
        local cmp = require('cmp')

        local autocomplete_group = vim.api.nvim_create_augroup(
            'cmp_dadbod',
            { clear = true }
        )
        vim.api.nvim_create_autocmd('FileType', {
            pattern = { 'sql', 'mysql', 'plsql' },
            callback = function()
                cmp.setup.buffer({
                    sources = {
                        { name = 'vim-dadbod-completion' },
                        { name = 'buffer' },
                    },
                })
            end,
            group = autocomplete_group,
        })
    end,
}
