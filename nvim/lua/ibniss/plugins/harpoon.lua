return {
    'theprimeagen/harpoon',
    config = function()
        local mark = require('harpoon.mark')
        local ui = require('harpoon.ui')

        ---  add file
        vim.keymap.set('n', '<leader>a', mark.add_file)
        vim.keymap.set('n', '<C-e>', ui.toggle_quick_menu)

        --- Files 1-2-3-4 -> space - h - 1/2/3/4
        vim.keymap.set('n', '<leader>h1', function()
            ui.nav_file(1)
        end)
        vim.keymap.set('n', '<leader>h2', function()
            ui.nav_file(2)
        end)
        vim.keymap.set('n', '<leader>h3', function()
            ui.nav_file(3)
        end)
        vim.keymap.set('n', '<leader>h4', function()
            ui.nav_file(4)
        end)
    end,
}