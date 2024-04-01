return {
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        lazy = true,
        config = false,
        init = function()
            -- Disable automatic setup, we are doing it manually
            vim.g.lsp_zero_extend_cmp = 0
            vim.g.lsp_zero_extend_lspconfig = 0
        end,
    },
    {
        'williamboman/mason.nvim',
        lazy = false,
        config = true,
    },
    -- Autocompletion
    {
        'hrsh7th/nvim-cmp',
        event = 'InsertEnter',
        dependencies = {
            {
                'L3MON4D3/LuaSnip',
                build = (function()
                    -- Build Step is needed for regex support in snippets
                    -- This step is not supported in many windows environments
                    -- Remove the below condition to re-enable on windows
                    if
                        vim.fn.has('win32') == 1
                        or vim.fn.executable('make') == 0
                    then
                        return
                    end
                    return 'make install_jsregexp'
                end)(),
            },
            { 'hrsh7th/cmp-buffer' }, -- Optional
            { 'hrsh7th/cmp-path' }, -- Optional
            { 'saadparwaiz1/cmp_luasnip' }, -- Optional
            { 'hrsh7th/cmp-nvim-lua' }, -- Optional
        },
        config = function()
            -- Here is where you configure the autocompletion settings.
            local lsp_zero = require('lsp-zero')
            local luasnip = require('luasnip')
            lsp_zero.extend_cmp()

            -- And you can configure cmp even more, if you want to.
            local cmp = require('cmp')
            local cmp_select = { behavior = cmp.SelectBehavior.Select }

            vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }

            cmp.setup({
                snippet = {
                    expand = function(args) luasnip.lsp_expand(args.body) end,
                },
                preselect = 'item', -- Automatically select the first item
                completion = {
                    completeopt = 'menu,menuone,noinsert',
                },
                sources = {
                    { name = 'path' },
                    { name = 'nvim_lsp' },
                    { name = 'nvim_lua' },
                    { name = 'buffer', keyword_length = 3 },
                },
                formatting = lsp_zero.cmp_format({ details = false }),
                mapping = cmp.mapping.preset.insert({
                    ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                    ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
                    ['<C-y>'] = cmp.mapping.confirm({ select = true }),
                    ['<C-e>'] = lsp_zero.cmp_action().toggle_completion(),
                    ['<C-Space>'] = cmp.mapping.complete(),
                    -- <c-l> will move you to the right of each of the expansion locations.
                    -- <c-h> is similar, except moving you backwards.
                    ['<C-l>'] = cmp.mapping(function()
                        if luasnip.expand_or_locally_jumpable() then
                            luasnip.expand_or_jump()
                        end
                    end, { 'i', 's' }),
                    ['<C-h>'] = cmp.mapping(function()
                        if luasnip.locally_jumpable(-1) then
                            luasnip.jump(-1)
                        end
                    end, { 'i', 's' }),
                }),
                -- add border to the completion window
                window = {
                    documentation = cmp.config.window.bordered(),
                    completion = cmp.config.window.bordered(),
                },
            })
        end,
    },
    -- LSP
    {
        'neovim/nvim-lspconfig',
        cmd = { 'LspInfo', 'LspInstall', 'LspStart' },
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = {
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'williamboman/mason-lspconfig.nvim' },
            { 'folke/neodev.nvim', opts = {} },
        },
        config = function()
            -- This is where all the LSP shenanigans will live
            local lsp_zero = require('lsp-zero')
            lsp_zero.extend_lspconfig()

            --- if you want to know more about lsp-zero and mason.nvim
            --- read this: https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/guides/integrate-with-mason-nvim.md
            lsp_zero.on_attach(function(client, bufnr)
                -- see :help lsp-zero-keybindings
                -- to learn the available actions
                local opts = { buffer = bufnr, remap = false }
                vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
                vim.keymap.set('n', '[d', vim.diagnostic.goto_next, opts)
                vim.keymap.set('n', ']d', vim.diagnostic.goto_prev, opts)

                vim.keymap.set(
                    'n',
                    '<leader>e',
                    vim.diagnostic.open_float,
                    opts
                )
                vim.keymap.set(
                    'n',
                    '<leader>q',
                    vim.diagnostic.setloclist,
                    opts
                )
                vim.keymap.set(
                    'n',
                    '<leader>vca',
                    vim.lsp.buf.code_action,
                    opts
                )
                vim.keymap.set('n', '<leader>vrr', vim.lsp.buf.references, opts)
                -- vim.keymap.set('n', '<leader>vrn', vim.lsp.buf.rename, opts)
                vim.keymap.set(
                    'n',
                    '<leader>vrn',
                    function() return ':IncRename ' .. vim.fn.expand('<cword>') end,
                    { expr = true }
                )

                --- Insert mode - C-H to show signature
                vim.keymap.set('i', '<C-h>', vim.lsp.buf.signature_help, opts)
            end)

            require('mason-lspconfig').setup({
                ensure_installed = {
                    'tsserver',
                    'lua_ls',
                    'rust_analyzer',
                    'pyright',
                    'eslint',
                },
                handlers = {
                    lsp_zero.default_setup,
                    lua_ls = function()
                        -- (Optional) Configure lua language server for neovim
                        local lua_opts = lsp_zero.nvim_lua_ls()
                        require('lspconfig').lua_ls.setup(lua_opts)
                    end,
                },
            })

            lsp_zero.set_sign_icons({
                error = '✘',
                warn = '▲',
                hint = '⚑',
                info = '',
            })

            vim.diagnostic.config({
                virtual_text = true,
                underline = true,
                severity_sort = true,
                float = {
                    style = 'minimal',
                    border = 'rounded',
                    source = 'always',
                    header = '',
                    prefix = '',
                    focusable = false,
                },
            })
        end,
    },
}
