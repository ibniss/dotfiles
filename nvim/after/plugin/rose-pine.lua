require('rose-pine').setup({
    --- light/dark mode variants based on vim.o.background
    variant = 'dawn',
    dark_variant = 'moon',
    styles = {
        transparency = true, --- let terminal dictate background colors, not the theme
    },
})

vim.cmd('colorscheme rose-pine-moon')
