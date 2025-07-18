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
                fzf = {},
            },
        })

        pcall(require('telescope').load_extension, 'fzf')
        pcall(require('telescope').load_extension, 'ui-select')

        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<C-p>', builtin.git_files, { desc = '[C-p] Git Files' })
        vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
        vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
        vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
        vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
        vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
        vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
        vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
        vim.keymap.set(
            'n',
            '<leader>s.',
            builtin.oldfiles,
            { desc = '[S]earch Recent Files ("." for repeat)' }
        )
        vim.keymap.set('n', '<leader>sb', builtin.buffers, { desc = '[S]earch [B]uffers' })
        vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch [W]ord' })

        vim.keymap.set('n', '<leader>/', function()
            -- You can pass additional configuration to Telescope to change the theme, layout, etc.
            builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown({
                previewer = false,
            }))
        end, { desc = '[/] Fuzzily search in current buffer' })
    end,
}
