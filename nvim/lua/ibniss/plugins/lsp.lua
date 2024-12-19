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
                -- formatting = lsp_zero.cmp_format({ details = false }),
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
        },
        config = function()
            -- local util to extend lspconfig
            local extend = function(name, key, values)
                local mod = require(string.format('lspconfig.configs.%s', name))
                local default = mod.default_config
                local keys = vim.split(key, '.', { plain = true })
                while #keys > 0 do
                    local item = table.remove(keys, 1)
                    default = default[item]
                end

                if vim.islist(default) then
                    for _, value in ipairs(default) do
                        table.insert(values, value)
                    end
                else
                    for item, value in pairs(default) do
                        if not vim.tbl_contains(values, item) then
                            values[item] = value
                        end
                    end
                end
                return values
            end

            local lspconfig = require('lspconfig')

            -- server configurations
            -- true means default configuration
            local servers = {
                lua_ls = true,
                ts_ls = {
                    root_dir = require('lspconfig').util.root_pattern(
                        'package.json'
                    ),
                    single_file = false,
                    server_capabilities = {
                        documentFormattingProvider = false,
                    },
                },
                rust_analyzer = true,
                basedpyright = true,
                eslint = true,
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

                    local opts = { buffer = bufnr, remap = false }
                    vim.keymap.set(
                        'n',
                        'gd',
                        require('telescope.builtin').lsp_definitions,
                        opts
                    )
                    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
                    vim.keymap.set(
                        'n',
                        'gr',
                        require('telescope.builtin').lsp_references,
                        opts
                    )
                    vim.keymap.set(
                        'n',
                        'gI',
                        require('telescope.builtin').lsp_implementations,
                        opts
                    )
                    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
                    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)

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
                    vim.keymap.set(
                        'n',
                        '<leader>vrr',
                        vim.lsp.buf.references,
                        opts
                    )
                    vim.keymap.set(
                        'n',
                        '<leader>vrn',
                        function()
                            return ':IncRename ' .. vim.fn.expand('<cword>')
                        end,
                        { expr = true }
                    )

                    --- Insert mode - C-H to show signature
                    vim.keymap.set(
                        'i',
                        '<C-h>',
                        vim.lsp.buf.signature_help,
                        opts
                    )

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
}
