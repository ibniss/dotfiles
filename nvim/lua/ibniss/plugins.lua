return {
    --- theme
    {
        'rose-pine/neovim',
        name = 'rose-pine',
        lazy = false, --- main theme, always load
        priority = 1000,
    },
    --- status line
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
    },
    --- mux/split navigation
    {
        'mrjones2014/smart-splits.nvim',
        lazy = false,
    },
    -- netrw replacement
    {
        'stevearc/oil.nvim',
        opts = {},
        -- Optional dependencies
        dependencies = { 'nvim-tree/nvim-web-devicons' },
    },
    -- telescope
    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.5',
        dependencies = { 'nvim-lua/plenary.nvim' },
    },
    --- treesitter
    { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' },
    { 'nvim-treesitter/nvim-treesitter-context' },
    --- harpoon
    { 'theprimeagen/harpoon' },
    --- undo tree
    { 'mbbill/undotree' },
    --- fugitive
    { 'tpope/vim-fugitive' },

    --- LSP Setup
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v1.x',
        dependencies = {
            -- LSP Support
            { 'neovim/nvim-lspconfig' }, -- Required
            { 'williamboman/mason.nvim' }, -- Optional
            { 'williamboman/mason-lspconfig.nvim' }, -- Optional

            -- Autocompletion
            { 'hrsh7th/nvim-cmp' }, -- Required
            { 'hrsh7th/cmp-nvim-lsp' }, -- Required
            { 'hrsh7th/cmp-buffer' }, -- Optional
            { 'hrsh7th/cmp-path' }, -- Optional
            { 'saadparwaiz1/cmp_luasnip' }, -- Optional
            { 'hrsh7th/cmp-nvim-lua' }, -- Optional

            -- Snippets
            { 'L3MON4D3/LuaSnip' }, -- Required
        },
    },

    --- Venv selector
    {
        'linux-cultist/venv-selector.nvim',
        dependencies = {
            'neovim/nvim-lspconfig',
            'nvim-telescope/telescope.nvim',
            'mfussenegger/nvim-dap-python',
        },
        opts = {
            -- Your options go here
            name = '.venv',
            -- auto_refresh = false
        },
        event = 'VeryLazy', -- Optional: needed only if you want to type `:VenvSelect` without a keymapping
    },
    --- Formatter
    {
        'stevearc/conform.nvim',
        event = { 'BufWritePre' },
        cmd = { 'ConformInfo' },
        keys = {
            {
                -- Format buffer
                '<leader>f',
                function()
                    require('conform').format({
                        async = true,
                        lsp_fallback = true,
                    })
                end,
                mode = '',
                desc = 'Format buffer',
            },
        },
        opts = {
            -- Define your formatters
            formatters_by_ft = {
                lua = { 'stylua' },
                python = { 'isort', 'blue' },
                javascript = { 'prettier' },
                typescript = { 'prettier' },
                javascriptreact = { 'prettier' },
                typescriptreact = { 'prettier' },
                json = { 'prettier' },
            },
            -- Set up format-on-save
            format_on_save = { timeout_ms = 500, lsp_fallback = true },
            -- Customize formatters
            formatters = {
                shfmt = {
                    prepend_args = { '-i', '2' },
                },
            },
        },
        init = function()
            -- If you want the formatexpr, here is the place to set it
            vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
        end,
    },
    --- Tab width adapter
    { 'tpope/vim-sleuth' },
    --- copilot
    { 'github/copilot.vim' },
}
