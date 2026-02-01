---@module 'neogit'
return {
    'NeogitOrg/neogit',
    dependencies = {
        'nvim-lua/plenary.nvim', -- required
        'sindrets/diffview.nvim', -- optional - Diff integration
        'nvim-telescope/telescope.nvim',
    },
    ---@type NeogitConfig
    opts = {
        commit_editor = {
            kind = 'tab',
            show_staged_diff = true,
            staged_diff_split_kind = 'vsplit',
            spell_check = true,
        },
        integrations = {
            telescope = true,
            diffview = true,
        },
    },
    keys = {
        { '<leader>gs', '<cmd>Neogit<cr>', desc = 'Neogit' },
    },
}
