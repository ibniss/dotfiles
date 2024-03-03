return {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.5',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
        local builtin = require('telescope.builtin')
        --- Project Files (all)
        vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
        --- Git Files
        vim.keymap.set('n', '<C-p>', builtin.git_files, {})
        --- Project Search
        vim.keymap.set('n', '<leader>ps', function()
            builtin.grep_string({ search = vim.fn.input('Grep > ') })
        end)
        -- word search under cursor
        vim.keymap.set('n', '<leader>pws', function()
            builtin.grep_string({ search = vim.fn.expand('<cword>') })
        end)
        vim.keymap.set('n', '<leader>pWs', function()
            builtin.grep_string({ search = vim.fn.expand('<cWORD>') })
        end)
    end,
}
