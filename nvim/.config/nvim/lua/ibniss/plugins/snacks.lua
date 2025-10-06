return {
    'folke/snacks.nvim',
    opts = {
        -- files >1.5MB disable LSP/treesitter
        bigfile = {
            enabled = true,
        },
        -- better vim.ui.input
        input = {},
    },
    config = function()
        local Snacks = require('snacks')

        Snacks.setup({
            bigfile = {
                enabled = true,
            },
        })

        -- singleton terminal
        local win = nil

        vim.keymap.set('n', '<leader>tt', function()
            if win == nil then
                win = Snacks.terminal.toggle(nil, {
                    win = {
                        height = 0.3,
                        position = 'right',
                    },
                })
            else
                win:toggle()
            end

            if win:valid() then vim.cmd('stopinsert') end
        end)
    end,
}
