return {
    'nvim-pack/nvim-spectre',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
        local spectre = require('spectre')
        spectre.setup({
            default = {
                replace = {
                    cmd = 'oxi',
                },
            },
            mapping = {
                ['send_to_qf'] = {
                    map = '<C-q>',
                    cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
                    desc = 'send all items to quickfix',
                },
            },
        })

        -- Spectre for global find/replace
        vim.keymap.set(
            'n',
            '<leader>S',
            function() require('spectre').toggle() end,
            { desc = 'Toggle Spectre for global find/replace' }
        )

        -- Spectre for word under cursor (visual)
        vim.keymap.set(
            'n',
            '<leader>sw',
            function() require('spectre').open_visual({ select_word = true }) end,
            { desc = 'Search current word using Spectre' }
        )
    end,
}
