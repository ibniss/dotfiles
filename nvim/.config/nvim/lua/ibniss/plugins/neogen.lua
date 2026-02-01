return {
  "danymat/neogen",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "L3MON4D3/LuaSnip",
  },
  config = function()
    local neogen = require "neogen"

    neogen.setup {
      snippet_engine = "luasnip",
      languages = {
        python = {
          template = {
            annotation_convention = "reST",
          },
        },
      },
    }

    vim.keymap.set("n", "<leader>nf", function() neogen.generate() end)
  end,
}
