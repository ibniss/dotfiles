require("ibniss.remap")
require("ibniss.set")

--- Bootstrap Lazy if not pulled already
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    change_detection = { notify = false },
    -- TODO: split plugins into separate files
    spec = "ibniss.plugins"
})
