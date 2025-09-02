return {
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        config = function()
            require('nvim-treesitter.configs').setup({
                -- A list of parser names, or "all" (the five listed parsers should always be installed)
                ensure_installed = {
                    'diff',
                    'javascript',
                    'typescript',
                    'tsx',
                    'python',
                    'rust',
                    'c',
                    'css',
                    'html',
                    'lua',
                    'vim',
                    'vimdoc',
                    'query',
                    'regex',
                    'bash',
                    'markdown',
                    'markdown_inline',
                },
                ignore_install = {},
                modules = {},
                filetype_to_parsername = {
                    mdx = 'markdown',
                },

                -- Install parsers synchronously (only applied to `ensure_installed`)
                sync_install = false,

                -- Automatically install missing parsers when entering buffer
                -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
                auto_install = true,
                indent = {
                    enable = false,
                },

                highlight = {
                    enable = true,

                    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
                    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
                    -- Using this option may slow down your editor, and you may see some duplicate highlights.
                    -- Instead of true it can also be a list of languages
                    additional_vim_regex_highlighting = false,
                },
                textobjects = {
                    select = {
                        enable = true,
                        keymaps = {
                            ['af'] = '@function.outer',
                            ['if'] = '@function.inner',
                            ['ac'] = '@class.outer',
                            ['ic'] = '@class.inner',
                        },
                    },
                },
            })
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter-context',
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        config = function()
            local tsc = require('treesitter-context')

            tsc.setup({
                enable = true,
                max_lines = 1,
                trim_scope = 'inner',
            })
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter-textobjects',
    },
}
