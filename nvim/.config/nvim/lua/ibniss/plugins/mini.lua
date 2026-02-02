return { -- Collection of various small independent plugins/modules
  "nvim-mini/mini.nvim",
  config = function()
    -- Better Around/Inside textobjects
    --
    -- Examples:
    --  - va)  - [V]isually select [A]round [)]paren
    --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
    --  - ci'  - [C]hange [I]nside [']quote
    local gen_spec = require("mini.ai").gen_spec
    require("mini.ai").setup {
      n_lines = 500,
      custom_textobjects = {
        -- Tweak function call to not detect dot in function name
        f = gen_spec.function_call { name_pattern = "[%w_]" },
        -- NOTE: those are using queries coming from nvim-treesitter-textobjects
        F = gen_spec.treesitter { a = "@function.outer", i = "@function.inner" },
        c = gen_spec.treesitter { a = "@class.outer", i = "@class.inner" },
      },
    }

    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require("mini.surround").setup {}
  end,
}
