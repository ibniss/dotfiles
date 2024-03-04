return {
    'f-person/auto-dark-mode.nvim',
    config = {
        update_interval = 3000,
        set_dark_mode = function()
            vim.o.background = 'dark'
            vim.cmd('colorscheme rose-pine-moon')
        end,
        set_light_mode = function()
            vim.o.background = 'light'
            vim.cmd('colorscheme rose-pine-dawn')
        end,
    },
}
