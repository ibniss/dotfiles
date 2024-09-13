return {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
    opts = {
        transparent = true,
        styles = {
            floats = 'transparent',
            sidebars = 'transparent',
        }
    },
    init = function()
        -- load the colorscheme here
        vim.cmd([[colorscheme tokyonight]])
    end,
}
