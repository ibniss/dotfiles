return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    branch = "main",
    build = ":TSUpdate",
    config = function()
      local filetypes = {
        "diff",
        "javascript",
        "typescript",
        "tsx",
        "typescriptreact",
        "javascriptreact",
        "python",
        "rust",
        "c",
        "css",
        "html",
        "lua",
        "luadoc",
        "vim",
        "vimdoc",
        "query",
        "regex",
        "bash",
        "markdown",
        "markdown_inline",
      }

      -- Install parsers using native API
      require("nvim-treesitter").install(filetypes)

      -- Enable highlighting via native API
      vim.api.nvim_create_autocmd("FileType", {
        pattern = filetypes,
        callback = function() vim.treesitter.start() end,
      })

      -- Handle mdx -> markdown parser
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "mdx",
        callback = function() vim.treesitter.start(0, "markdown") end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      enable = true,
      max_lines = 1,
      trim_scope = "inner",
    },
  },
  -- NOTE: using textobjects just for their built-in queries, actual bindings are used by mini.ai
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    config = function()
      local select = require "nvim-treesitter-textobjects.select"

      require("nvim-treesitter-textobjects").setup {
        select = {
          lookahead = true,
        },
      }
    end,
  },
}
