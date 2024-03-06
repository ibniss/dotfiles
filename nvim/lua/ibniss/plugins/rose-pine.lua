return {
    'rose-pine/neovim',
    name = 'rose-pine',
    lazy = false, --- main theme, always load
    priority = 1000,
    config = function()
        require('rose-pine').setup({
            --- light/dark mode variants based on vim.o.background
            variant = 'dawn',
            dark_variant = 'moon',
            styles = {
                transparency = false,
            },
        })

        vim.cmd('colorscheme rose-pine-moon')
    end,
}
