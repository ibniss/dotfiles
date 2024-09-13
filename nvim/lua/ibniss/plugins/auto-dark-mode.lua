local function update_notify_color(color)
    local palette = require('tokyonight.colors').setup({
        style = color == 'dark' and 'moon' or 'day',
    }) -- this imports light/dark based on vim.o.background
    vim.cmd([[ hi NotifyBackground guibg = ]] .. palette.bg)
end

return {
    'f-person/auto-dark-mode.nvim',
    opts = {
        update_interval = 3000,
        set_dark_mode = function()
            vim.o.background = 'dark'
            update_notify_color('dark')
        end,
        set_light_mode = function()
            vim.o.background = 'light'
            update_notify_color('light')
        end,
    },
}
