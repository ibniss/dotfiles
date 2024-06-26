return {
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
}
