vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true
vim.opt.breakindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv('HOME') .. '/.vim/undodir'
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

-- Better splitting
vim.opt.splitbelow = true
vim.opt.splitright = true

-- testing teej's settings
vim.opt.smartcase = true
vim.opt.ignorecase = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = 'yes'
vim.opt.isfname:append('@-@')

vim.opt.updatetime = 50

vim.opt.confirm = true

-- Don't have `o` add a comment
vim.opt.formatoptions:remove('o')

--- extra
vim.opt.showmode = false --- don't show mode as we have a statusline
vim.opt.cursorline = true
vim.opt.cursorlineopt = 'number'

-- fold stuff
require('ibniss.util.foldtext').setup()

-- filetypes
vim.filetype.add({
    extension = {
        mdx = 'markdown',
    },
})
