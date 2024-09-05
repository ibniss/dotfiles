local LualineUtil = require('ibniss.util.lualine')

return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'VeryLazy',
    init = function()
        vim.g.lualine_laststatus = vim.o.laststatus
        if vim.fn.argc(-1) > 0 then
            -- set an empty statusline till lualine loads
            vim.o.statusline = ' '
        else
            -- hide the statusline on the starter page
            vim.o.laststatus = 0
        end
    end,
    config = function()
        require('lualine').setup({
            theme = 'auto',
            sections = {
                lualine_a = { 'mode' },
                lualine_b = {
                    function()
                        local icon = require('nvim-web-devicons').get_icon('git')
                        local git = require("neogit.lib.git")
                        return icon .. ' ' .. git.repo.state.head.branch
                    end,
                },
                lualine_c = {
                    LualineUtil.root_dir(),
                    {
                        'diagnostics',
                    },
                    {
                        'filetype',
                        icon_only = true,
                        separator = '',
                        padding = { left = 1, right = 0 },
                    },
                    { LualineUtil.pretty_path() },
                },

                lualine_x = {
                    {
                        function()
                            return require('noice').api.status.command.get()
                        end,
                        cond = function()
                            return package.loaded['noice']
                                and require('noice').api.status.command.has()
                        end,
                        color = 'Statement',
                    },
                    { 'diff' },
                },
                lualine_y = {
                    {
                        'progress',
                        separator = ' ',
                        padding = { left = 1, right = 1 },
                    },
                },
                lualine_z = { 'location' },
            },
        })
    end,
}
