vim.g.mapleader = ' '
-- open file system
vim.keymap.set('n', '<leader>pv', '<CMD>Oil<CR>', { desc = 'Open file system' })

-- this allow moving a block of code when highlighted up and down with J/K
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")

-- makes J work the same but cursor stays in place
vim.keymap.set('n', 'J', 'mzJ`z')

-- Center cursor while jumping:
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll up and center cursor' })
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll down and center cursor' })
vim.keymap.set('n', '{', '{zz', { desc = 'Jump to previous paragraph and center' })
vim.keymap.set('n', '}', '}zz', { desc = 'Jump to next paragraph and center' })
vim.keymap.set('n', 'N', 'Nzz', { desc = 'Search previous and center' })
vim.keymap.set('n', 'n', 'nzz', { desc = 'Search next and center' })
vim.keymap.set('n', 'G', 'Gzz', { desc = 'Go to end of file and center' })
vim.keymap.set('n', 'gg', 'ggzz', { desc = 'Go to beginning of file and center' })
vim.keymap.set('n', 'gd', 'gdzz', { desc = 'Go to definition and center' })
vim.keymap.set('n', '%', '%zz', { desc = 'Jump to matching bracket and center' })
vim.keymap.set('n', '*', '*zz', { desc = 'Search for word under cursor and center' })
vim.keymap.set('n', '#', '#zz', { desc = 'Search backward for word under cursor and center' })

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

-- replace selected word
vim.keymap.set('n', '<leader>s', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- chmod+x current file
vim.keymap.set('n', '<leader>x', '<cmd>!chmod +x %<CR>', { silent = true })
