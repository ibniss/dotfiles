local LualineUtil = require('ibniss.util.lualine')

return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        require('lualine').setup({
            theme = 'auto',
            sections = {
                lualine_a = { 'mode' },
                lualine_b = { '%{FugitiveStatusline()}', 'diff' },
                lualine_c = {
                    LualineUtil.root_dir(),
                    {
                        'diagnostics',
                    },
                    { LualineUtil.pretty_path() },
                },

                lualine_x = { 'filetype' },
                lualine_y = { 'progress' },
                lualine_z = { 'location' },
            },
        })
    end,
}
