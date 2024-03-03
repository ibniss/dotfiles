vim.g.mapleader = ' '
-- open file system
vim.keymap.set('n', '<leader>pv', '<CMD>Oil<CR>', { desc = 'Open file system' })

-- this allow moving a block of code when highlighted up and down with J/K
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")

-- makes J work the same but cursor stays in place
vim.keymap.set('n', 'J', 'mzJ`z')

-- allow C-D/U (half page jumping) to keep cursor in the middle
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')

-- allows n/N to keep search term in the middle
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

-- paste and move into void register, otherwise replaced word would end up replacing previous copy
vim.keymap.set('x', '<leader>p', [["_dP]])

-- copy to clipboard
vim.keymap.set({ 'n', 'v' }, '<leader>y', [["+y]])
vim.keymap.set('n', '<leader>Y', [["+Y]])

-- delete into void
vim.keymap.set({ 'n', 'v' }, '<leader>d', [["_d]])

-- Sometimes in Visual Block replace only Escape work
vim.keymap.set('i', '<C-c>', '<Esc>')

-- Disables Q (ex mode)
vim.keymap.set('n', 'Q', '<nop>')

-- open tmux
vim.keymap.set('n', '<C-f>', '<cmd>silent !tmux neww tmux-sessionizer<CR>')

-- quick fix navigation?
vim.keymap.set('n', '<C-k>', '<cmd>cnext<CR>zz')
vim.keymap.set('n', '<C-j>', '<cmd>cprev<CR>zz')
vim.keymap.set('n', '<leader>k', '<cmd>lnext<CR>zz')
vim.keymap.set('n', '<leader>j', '<cmd>lprev<CR>zz')

-- replace selected word
vim.keymap.set(
    'n',
    '<leader>s',
    [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]]
)

-- chmod+x current file
vim.keymap.set('n', '<leader>x', '<cmd>!chmod +x %<CR>', { silent = true })
