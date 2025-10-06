return {
    'stevearc/oil.nvim',
    opts = {},
    -- Optional dependencies
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        require('oil').setup({
            default_file_explorer = true,
            view_options = {
                show_hidden = true,
            },
            use_default_keymaps = false, -- disable all keymaps
            -- explicit keymaps
            keymaps = {
                ['g?'] = 'actions.show_help',
                ['-'] = 'actions.parent',
                ['<CR>'] = 'actions.select',
            },
        })

        -- open file system
        vim.keymap.set('n', '<leader>pv', '<CMD>Oil<CR>', { desc = 'Open file system' })
    end,
}
