return {
  {
    "linux-cultist/venv-selector.nvim",
    dependencies = {
      { "nvim-telescope/telescope.nvim", version = "*", dependencies = { "nvim-lua/plenary.nvim" } },
    },
    ft = "python",
    opts = {
      options = {
        -- Don't override vim.notify - noice.nvim handles it
        override_notify = false,
        statusline_func = {
          lualine = function()
            local venv_path = require("venv-selector").venv()
            if not venv_path or venv_path == "" then return "" end

            local venv_name = vim.fn.fnamemodify(venv_path, ":t")
            if not venv_name then return "" end

            local output = " " .. venv_name .. " " -- Changes only the icon but you can change colors or use powerline symbols here.
            return output
          end,
        },
      },
    },
  },
}
