return {
    'tpope/vim-fugitive',
    config = function()
        --- \gs ~ git status
        vim.keymap.set('n', '<leader>gs', vim.cmd.Git)

        --- gf/gj (left-right) accept changes in left or right in diff view
        vim.keymap.set('n', 'gf', '<cmd>diffget //2<CR>')
        vim.keymap.set('n', 'gj', '<cmd>diffget //3<CR>')
    end,
}
