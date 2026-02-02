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
        -- (Default) Only show the documentation popup when manually triggered (C-Space)
        auto_show = false,
        window = { border = "rounded" },
      },
      menu = { border = "rounded" },
    },

    sources = {
      default = { "lazydev", "lsp", "path", "buffer" },
      -- TEST: don't complete until 2 chars typed
      min_keyword_length = 2,
      --  register lazydev completions
      providers = {
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          -- make lazydev completions top priority (see `:h blink.cmp`)
          score_offset = 100,
        },
      },
    },

    -- Use Rust fuzzy matcher for better performance
    fuzzy = { implementation = "prefer_rust" },

    -- Show signature help while typing function arguments
    signature = { enabled = true },
  },
}
