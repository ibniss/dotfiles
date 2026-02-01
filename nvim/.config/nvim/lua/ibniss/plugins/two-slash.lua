return {
  {
    "marilari88/twoslash-queries.nvim",
    event = "VeryLazy",
    config = function()
      local twoslash = require "twoslash-queries"

      twoslash.setup {
        multi_line = true,
        is_enabled = false,
        highlight = "Comment",
      }

      vim.keymap.set("n", "<leader>ts", function()
        if twoslash.config.is_enabled then
          vim.cmd "TwoslashQueriesDisable"
        else
          vim.cmd "TwoslashQueriesEnable"
        end
      end)
    end,
  },
}
