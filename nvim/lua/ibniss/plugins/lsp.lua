return {
    -- Autocompletion
    {
        'hrsh7th/nvim-cmp',
        event = 'InsertEnter',
        dependencies = {
            { 'hrsh7th/cmp-buffer' }, -- Optional
            { 'hrsh7th/cmp-path' }, -- Optional
            { 'hrsh7th/cmp-cmdline' }, -- Cmdline completions
            { 'hrsh7th/cmp-nvim-lua' }, -- Optional
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'hrsh7th/cmp-nvim-lsp-signature-help' },
            -- icons for completion items
            { 'onsails/lspkind.nvim' },
        },
        config = function()
            -- And you can configure cmp even more, if you want to.
            local cmp = require('cmp')
            local cmp_select = { behavior = cmp.SelectBehavior.Select }

            vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }

            local lspkind = require('lspkind')

            cmp.setup({
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
                formatting = {
                    expandable_indicator = true,
                    fields = {
                        'kind',
                        'abbr',
                        'menu',
                    },
                    format = lspkind.cmp_format({
                        mode = 'symbol',
                        ellipsis_char = '...',
                        show_labelDetails = true,
                        preset = 'codicons', -- uses vscode codicons
                    }),
                },
                mapping = cmp.mapping.preset.insert({
                    ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                    ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
                    ['<C-y>'] = cmp.mapping.confirm({ select = true }),
                    ['<C-Space>'] = cmp.mapping.complete(),
                }),
                -- add border to the completion window
                window = {
                    documentation = cmp.config.window.bordered(),
                    completion = cmp.config.window.bordered(),
                },
            })

            -- Cmdline
            cmp.setup.cmdline('/', {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = 'buffer' },
                },
            })
            cmp.setup.cmdline(':', {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                    { name = 'path' },
                }, {
                    {
                        name = 'cmdline',
                        option = {
                            ignore_cmds = { 'Man', '!' },
                        },
                    },
                }),
            })
        end,
    },
    -- LSP
    {
        'neovim/nvim-lspconfig',
        cmd = { 'LspInfo', 'LspInstall', 'LspStart' },
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = {
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },
            { 'WhoIsSethDaniel/mason-tool-installer.nvim' },
            {
                -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
                -- used for completion, annotations and signatures of Neovim apis
                'folke/lazydev.nvim',
                ft = 'lua',
                opts = {
                    library = {
                        -- Load luvit types when the `vim.uv` word is found
                        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
                    },
                },
            },
            { 'Bilal2453/luvit-meta', lazy = true },

            -- cmp for completions
            { 'hrsh7th/cmp-nvim-lsp' },

            -- conform needs to be setup first
            { 'stevearc/conform.nvim' },
        },
        config = function()
            local lspconfig = require('lspconfig')

            -- server configurations
            -- true means default configuration
            local servers = {
                lua_ls = true,
                ts_ls = {
                    root_dir = require('lspconfig').util.root_pattern('package.json'),
                    single_file = false,
                    server_capabilities = {
                        documentFormattingProvider = false,
                    },
                },
                rust_analyzer = true,
                basedpyright = true,
                eslint = true,
                jsonls = true,
                ocamllsp = {
                    manual_install = true,
                    cmd = { 'dune', 'tools', 'exec', 'ocamllsp' },
                    -- cmd = { "dune", "exec", "ocamllsp" },
                    settings = {
                        codelens = { enable = true },
                        inlayHints = { enable = true },
                        syntaxDocumentation = { enable = true },
                    },

                    server_capabilities = { semanticTokensProvider = false },
                },
            }

            -- setup ocaml
            require('ocaml').setup()

            -- filter out servers with manual_install
            local servers_to_install = vim.tbl_filter(function(key)
                local t = servers[key]
                if type(t) == 'table' then
                    return not t.manual_install
                else
                    return t
                end
            end, vim.tbl_keys(servers))

            require('mason').setup()

            -- which servers should be autoinstalled by mason
            local ensure_installed = {
                'ts_ls',
                'lua_ls',
                'rust_analyzer',
                'basedpyright',
                'eslint',
            }

            -- run the mason installer
            vim.list_extend(ensure_installed, servers_to_install)
            require('mason-tool-installer').setup({
                ensure_installed = ensure_installed,
            })

            local capabilities = require('cmp_nvim_lsp').default_capabilities()

            -- run lspconfig.setup() for each server
            for name, config in pairs(servers) do
                -- if config is true, then use default configuration
                if config == true then config = {} end

                -- use cmp capabilities
                config = vim.tbl_deep_extend('force', {}, {
                    capabilities = capabilities,
                }, config)

                lspconfig[name].setup(config)
            end

            -- run lsp setup when LSP is attached to buffer
            vim.api.nvim_create_autocmd('LspAttach', {
                callback = function(args)
                    local bufnr = args.buf
                    local client = assert(
                        vim.lsp.get_client_by_id(args.data.client_id),
                        'must have valid client'
                    )

                    local settings = servers[client.name]
                    if type(settings) ~= 'table' then settings = {} end

                    --- helper function to set keymaps
                    --- @param keys string
                    --- @param func function | string
                    --- @param desc string
                    --- @param mode string|string[]?
                    local map = function(keys, func, desc, mode)
                        mode = mode or 'n'
                        vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = 'LSP: ' .. desc })
                    end

                    map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
                    map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
                    map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
                    map(
                        'gI',
                        require('telescope.builtin').lsp_implementations,
                        '[G]oto [I]mplementations'
                    )
                    map('[d', function()
                        vim.diagnostic.goto_prev()
                        vim.api.nvim_feedkeys('zz', 'n', false)
                    end, '[G]oto [P]rev and center')
                    map(']d', function()
                        vim.diagnostic.goto_next()
                        vim.api.nvim_feedkeys('zz', 'n', false)
                    end, '[G]oto [N]ext and center')

                    vim.keymap.set('n', ']e', function()
                        vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
                        vim.api.nvim_feedkeys('zz', 'n', false)
                    end, { desc = 'Go to next error diagnostic and center' })

                    vim.keymap.set('n', '[e', function()
                        vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
                        vim.api.nvim_feedkeys('zz', 'n', false)
                    end, { desc = 'Go to previous error diagnostic and center' })

                    map(
                        '<leader>ds',
                        require('telescope.builtin').lsp_document_symbols,
                        '[D]ocument [S]ymbols'
                    )

                    map(
                        '<leader>ws',
                        require('telescope.builtin').lsp_dynamic_workspace_symbols,
                        '[W]orkspace [S]ymbols'
                    )

                    map(
                        '<leader>e',
                        vim.diagnostic.open_float,
                        'Open float window with diagnostics'
                    )
                    map('<leader>q', vim.diagnostic.setloclist, 'Add buffer diagnostics to loclist')
                    map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })

                    vim.keymap.set(
                        'n',
                        '<leader>rn',
                        function() return ':IncRename ' .. vim.fn.expand('<cword>') end,
                        { expr = true }
                    )

                    --- Insert mode - C-K to show signature
                    vim.keymap.set(
                        'i',
                        '<C-K>',
                        vim.lsp.buf.signature_help,
                        { buffer = bufnr, desc = '[C-K] Signature Help' }
                    )

                    if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
                        map(
                            '<leader>th',
                            function()
                                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({
                                    bufnr = bufnr,
                                }))
                            end,
                            '[T]oggle Inlay [H]ints'
                        )
                    end

                    -- Override server capabilities
                    if settings.server_capabilities then
                        for k, v in pairs(settings.server_capabilities) do
                            if v == vim.NIL then
                                ---@diagnostic disable-next-line: cast-local-type
                                v = nil
                            end

                            client.server_capabilities[k] = v
                        end
                    end
                end,
            })

            vim.diagnostic.config({
                virtual_text = true,
                underline = true,
                severity_sort = true,
                float = {
                    style = 'minimal',
                    border = 'rounded',
                    source = true,
                    header = '',
                    prefix = '',
                    focusable = false,
                },
            })
        end,
    },
    -- {
    --     'hinell/lsp-timeout.nvim',
    --     dependencies = { 'neovim/nvim-lspconfig' },
    -- },
}
