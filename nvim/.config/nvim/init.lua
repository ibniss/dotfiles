-- Prepend mise shims to PATH
vim.env.PATH = vim.env.HOME .. "/.local/share/mise/shims:" .. vim.env.PATH

require "ibniss"

--- autocmd - remove trailing whitespace
local group = vim.api.nvim_create_namespace "ibniss"
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  group = group,
  pattern = "*",
  command = [[%s/\s\+$//e]],
})
