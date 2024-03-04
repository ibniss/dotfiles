return {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
        'nvim-lua/plenary.nvim',
        {
            -- fzf native extension for perf
            'nvim-telescope/telescope-fzf-native.nvim',
            build = 'make',
        },
        { 'nvim-telescope/telescope-ui-select.nvim' },
        { 'nvim-tree/nvim-web-devicons' },
    },
    config = function()
        require('telescope').setup({
            extensions = {
                ['ui-select'] = {
                    require('telescope.themes').get_dropdown(),
                },
            },
        })

        pcall(require('telescope').load_extension, 'fzf')
        pcall(require('telescope').load_extension, 'ui-select')

        local builtin = require('telescope.builtin')
        --- Project Files (all)
        vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
        --- Git Files
        vim.keymap.set('n', '<C-p>', builtin.git_files, {})
        --- Project Search
        vim.keymap.set('n', '<leader>ps', builtin.live_grep, {})
        -- word search under cursor
        vim.keymap.set(
            'n',
            '<leader>pws',
            function()
                builtin.grep_string({ search = vim.fn.expand('<cword>') })
            end
        )
        vim.keymap.set(
            'n',
            '<leader>pWs',
            function()
                builtin.grep_string({ search = vim.fn.expand('<cWORD>') })
            end
        )
    end,
}
