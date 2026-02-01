return {
  "saghen/blink.cmp",
  event = "VimEnter",
  version = "1.*",
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = {
      -- 'default' preset: C-y to accept, C-n/C-p to navigate, C-space for menu/docs
      preset = "default",
    },

    appearance = {
      -- 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      nerd_font_variant = "mono",
    },

    completion = {
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 250,
        window = { border = "rounded" },
      },
      menu = { border = "rounded" },
    },

    sources = {
      default = { "lsp", "path", "buffer" },
    },

    -- Use Rust fuzzy matcher for better performance
    fuzzy = { implementation = "prefer_rust" },

    -- Show signature help while typing function arguments
    signature = { enabled = true },
  },
}
