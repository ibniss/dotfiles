return {
  "mbbill/undotree",
  config = function()
    --- \u becomes undo
    vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
  end,
}
