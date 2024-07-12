local function update_notify_color()
    local palette = require('rose-pine.palette') -- this imports light/dark based on vim.o.background
    vim.cmd([[ hi NotifyBackground guibg = ]] .. palette.base)
end

return {
    'f-person/auto-dark-mode.nvim',
    opts = {
        update_interval = 3000,
        set_dark_mode = function()
            vim.o.background = 'dark'
            vim.cmd('colorscheme rose-pine-moon')

            update_notify_color()
        end,
        set_light_mode = function()
            vim.o.background = 'light'
            vim.cmd('colorscheme rose-pine-dawn')
        end,
    },
}
