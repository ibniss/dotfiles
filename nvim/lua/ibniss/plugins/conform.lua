return {
    {
        'stevearc/conform.nvim',
        dependencies = {
            'neovim/nvim-lspconfig',
        },
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
                desc = '[F]ormat buffer',
            },
        },
        opts = {
            -- Define your formatters
            formatters_by_ft = {
                lua = { 'stylua' },
                python = function(bufnr)
                    if
                        require('conform').get_formatter_info('ruff_format', bufnr).available
                        and require('conform').get_formatter_info('ruff_organize_imports', bufnr).available
                    then
                        return { 'ruff_organize_imports', 'ruff_format' }
                    else
                        return { 'isort', 'blue' }
                    end
                end,
                javascript = { 'prettier' },
                typescript = { 'prettier' },
                javascriptreact = { 'prettier' },
                typescriptreact = { 'prettier' },
                json = { 'prettier' },
                ocaml = { 'ocamlformat' },
                ocaml_mlx = { 'ocamlformat_mlx' },
            },
            -- Customize formatters
            formatters = {
                shfmt = {
                    prepend_args = { '-i', '2' },
                },
                -- use dune tools exec ... for ocamlformat
                ocamlformat = {
                    command = 'dune',
                    prepend_args = { 'tools', 'exec', 'ocamlformat', '--' },
                },
                ocamlformat_mlx = {
                    command = 'dune',
                    prepend_args = { 'tools', 'exec', 'ocamlformat_mlx', '--' },
                },
            },
        },
        init = function()
            -- If you want the formatexpr, here is the place to set it
            vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
        end,
    },
}
