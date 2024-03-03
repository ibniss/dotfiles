return {
    'mrjones2014/smart-splits.nvim',
    lazy = false,
    config = function()
        local ss = require('smart-splits')
        ss.setup({})

        vim.keymap.set('n', '<C-a><Left>', ss.resize_left)
        vim.keymap.set('n', '<C-a><Down>', ss.resize_down)
        vim.keymap.set('n', '<C-a><Up>', ss.resize_up)
        vim.keymap.set('n', '<C-a><Right>', ss.resize_right)

        -- moving between splits (must match WezTerm config)
        vim.keymap.set('n', '<C-a>h', ss.move_cursor_left)
        vim.keymap.set('n', '<C-a>j', ss.move_cursor_down)
        vim.keymap.set('n', '<C-a>k', ss.move_cursor_up)
        vim.keymap.set('n', '<C-a>l', ss.move_cursor_right)

        -- swapping buffers between windows
        --vim.keymap.set('n', '<leader><leader>h', ss.swap_buf_left)
        --vim.keymap.set('n', '<leader><leader>j', ss.swap_buf_down)
        --vim.keymap.set('n', '<leader><leader>k', ss.swap_buf_up)
        --vim.keymap.set('n', '<leader><leader>l', ss.swap_buf_right)
    end,
}
