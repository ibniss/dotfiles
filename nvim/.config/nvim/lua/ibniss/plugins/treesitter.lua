return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    branch = "main",
    build = ":TSUpdate",
    config = function()
      local parsers = {
        "diff",
        "javascript",
        "typescript",
        "tsx",
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
        "yaml",
      }

      -- Install parsers using native API
      require("nvim-treesitter").install(parsers)

      local filetype_map = {}
      for _, parser in ipairs(parsers) do
        for _, filetype in ipairs(vim.treesitter.language.get_filetypes(parser)) do
          filetype_map[filetype] = true
        end
      end

      -- Enable highlighting via native API
      vim.api.nvim_create_autocmd("FileType", {
        pattern = vim.tbl_keys(filetype_map),
        callback = function(args) vim.treesitter.start(args.buf) end,
      })

      -- Handle mdx -> markdown parser
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "mdx",
        callback = function(args) vim.treesitter.start(args.buf, "markdown") end,
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
