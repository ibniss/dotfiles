---@module 'snacks'
return {
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = {
    -- files >1.5MB disable LSP/treesitter
    bigfile = {
      enabled = true,
    },
    -- better vim.ui.input
    input = {},
    -- disable notifier - using noice.nvim + nvim-notify instead
    notifier = { enabled = false },
  },
  config = function(_, opts)
    local Snacks = require "snacks"

    Snacks.setup(opts)

    -- singleton terminal
    local win = nil

    vim.keymap.set("n", "<leader>tt", function()
      if win == nil then
        win = Snacks.terminal.toggle(nil, {
          win = {
            height = 0.3,
            position = "right",
          },
        })
      else
        win:toggle()
      end

      if win:valid() then vim.cmd "stopinsert" end
    end)
  end,
}
