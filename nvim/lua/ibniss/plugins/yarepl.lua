local keymap = vim.api.nvim_set_keymap

return {
    'milanglacier/yarepl.nvim',
    event = 'VeryLazy',
    config = function()
        local aider = require('yarepl.extensions.aider')
        aider.setup({
            aider_args = {
                '--watch-files',
                '--sonnet',
                '--no-auto-commits',
            },
        })
        require('yarepl').setup({
            metas = {
                aider = aider.create_aider_meta(),
            },
        })

        keymap('n', '<leader>as', '<Plug>(REPLStart-aider)', {
            desc = 'Start REPL with aider',
        })
        keymap('n', '<leader>aa', '<Plug>(REPLHideOrFocus-aider)', {
            desc = 'Hide or focus REPL with aider',
        })
        keymap('v', '<leader>ar', '<Plug>(REPLSendVisual-aider)', {
            desc = 'Send visual selection to REPL with aider',
        })

        require('telescope').load_extension('REPLShow')
        keymap('n', '<leader>at', '<cmd>Telescope REPLShow<cr>', {
            desc = 'Show list of REPLs in telescope',
        })
    end,
}
