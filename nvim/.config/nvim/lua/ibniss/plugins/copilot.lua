return {
  -- 'zbirenbaum/copilot.lua',
  -- cmd = 'Copilot',
  -- event = 'InsertEnter',
  -- config = function()
  --     require('copilot').setup({
  --         suggestion = {
  --             auto_trigger = true,
  --             keymap = {
  --                 accept = '<Tab>',
  --             },
  --         },
  --     })
  --
  --     -- Override Tab to accept suggestions if visible but otherwise insert a tab
  --     vim.keymap.set('i', '<Tab>', function()
  --         if require('copilot.suggestion').is_visible() then
  --             require('copilot.suggestion').accept()
  --         else
  --             vim.api.nvim_feedkeys(
  --                 vim.api.nvim_replace_termcodes('<Tab>', true, false, true),
  --                 'n',
  --                 false
  --             )
  --         end
  --     end, { desc = 'Super Tab' })
  -- end,

  "supermaven-inc/supermaven-nvim",
  config = function()
    require("supermaven-nvim").setup {
      disable_keymaps = true,
    }
    local completion_preview = require "supermaven-nvim.completion_preview"
    vim.keymap.set("i", "<Tab>", completion_preview.on_accept_suggestion, { noremap = true, silent = true })
  end,
}
