return {
  -- LSP
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- Mason must be loaded before dependents, opts = {} ensures setup() is called
      { "mason-org/mason.nvim", opts = {} },
      { "WhoIsSethDaniel/mason-tool-installer.nvim" },
      {
        -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
        -- used for completion, annotations and signatures of Neovim apis
        "folke/lazydev.nvim",
        ft = "lua",
        dependencies = {
          { "gonstoll/wezterm-types", lazy = true },
        },
        opts = {
          library = {
            -- Load luvit types when the `vim.uv` word is found
            { path = "luvit-meta/library", words = { "vim%.uv" } },
            -- Load wezterm types
            { path = "wezterm-types", mods = { "wezterm" } },
          },
        },
      },
      { "Bilal2453/luvit-meta", lazy = true },

      -- blink.cmp for completions
      { "saghen/blink.cmp" },

      -- conform needs to be setup first
      { "stevearc/conform.nvim" },
    },
    config = function()
      local vtsls_inlay_hints = {
        enumMemberValues = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        functionParameterTypes = { enabled = true },
        parameterNames = { enabled = "all" },
        parameterNameWhenArgumentMatchesNames = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        variableTypes = { enabled = true },
        variableTypeWhenTypeMatchesNames = { enabled = true },
      }

      -- Server configurations
      -- true means default configuration (uses nvim-lspconfig's lsp/ directory)
      -- table means custom overrides merged with nvim-lspconfig defaults
      local servers = {
        lua_ls = true,
        vtsls = {
          settings = {
            complete_function_calls = true,
            vtsls = {
              autoUseWorkspaceTsdk = true,
              experimental = {
                completion = {
                  enableServerSideFuzzyMatch = true,
                },
              },
            },
            typescript = {
              updateImportOnFileMove = { enabled = "always" },
              suggest = {
                completeFunctionCalls = true,
              },
              tsserver = {
                maxTsServerMemory = 9216,
              },
              inlayHints = vtsls_inlay_hints,
            },
            javascript = {
              inlayHints = vtsls_inlay_hints,
            },
          },
        },
        gopls = {
          settings = {
            gopls = {
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
            },
          },
        },
        clangd = true,
        rust_analyzer = true,
        basedpyright = true,
        eslint = true,
        jsonls = true,
        ocamllsp = {
          manual_install = true,
          cmd = { "dune", "tools", "exec", "ocamllsp" },
          settings = {
            codelens = { enable = true },
            inlayHints = { enable = true },
            syntaxDocumentation = { enable = true },
          },
          -- Disable semantic tokens for ocamllsp
          on_attach = function(client) client.server_capabilities.semanticTokensProvider = nil end,
        },
      }

      -- setup ocaml
      require("ocaml").setup()

      -- Mason package names (differ from LSP server names)
      local ensure_installed = {
        "lua-language-server",
        "rust-analyzer",
        "basedpyright",
        "eslint-lsp",
        -- "gopls",
        "vtsls",
        "clangd",
        "json-lsp",
      }

      require("mason-tool-installer").setup {
        ensure_installed = ensure_installed,
      }

      local capabilities = require("blink.cmp").get_lsp_capabilities()

      -- Configure and enable LSP servers using nvim 0.11 native API
      for name, config in pairs(servers) do
        if config == true then config = {} end

        -- Merge blink.cmp capabilities
        config.capabilities = vim.tbl_deep_extend("force", {}, capabilities, config.capabilities or {})

        -- vim.lsp.config() defines/extends the configuration
        -- nvim-lspconfig provides base configs in its lsp/ directory
        vim.lsp.config(name, config)
        vim.lsp.enable(name)
      end

      -- LspAttach autocmd for keymaps and per-buffer setup
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("ibniss-lsp-attach", { clear = true }),
        callback = function(event)
          local bufnr = event.buf
          local client = assert(vim.lsp.get_client_by_id(event.data.client_id), "must have valid client")

          --- Helper function to set keymaps
          --- @param keys string
          --- @param func function | string
          --- @param desc string
          --- @param mode string|string[]?
          local map = function(keys, func, desc, mode)
            mode = mode or "n"
            vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
          end

          -- Navigation keymaps
          map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
          map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
          map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
          map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementations")

          -- Diagnostic navigation with centering
          map("[d", function()
            vim.diagnostic.goto_prev()
            vim.api.nvim_feedkeys("zz", "n", false)
          end, "Prev diagnostic and center")
          map("]d", function()
            vim.diagnostic.goto_next()
            vim.api.nvim_feedkeys("zz", "n", false)
          end, "Next diagnostic and center")
          map("[e", function()
            vim.diagnostic.goto_prev { severity = vim.diagnostic.severity.ERROR }
            vim.api.nvim_feedkeys("zz", "n", false)
          end, "Prev error and center")
          map("]e", function()
            vim.diagnostic.goto_next { severity = vim.diagnostic.severity.ERROR }
            vim.api.nvim_feedkeys("zz", "n", false)
          end, "Next error and center")

          -- Symbol search
          map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
          map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

          -- Diagnostics
          map("<leader>e", vim.diagnostic.open_float, "Open diagnostic float")
          map("<leader>q", vim.diagnostic.setloclist, "Add diagnostics to loclist")

          -- Actions
          map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })
          vim.keymap.set(
            "n",
            "<leader>rn",
            function() return ":IncRename " .. vim.fn.expand "<cword>" end,
            { expr = true, desc = "LSP: Rename" }
          )

          -- Signature help in insert mode
          vim.keymap.set("i", "<C-K>", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "Signature Help" })

          -- Inlay hints toggle
          if client:supports_method("textDocument/inlayHint", bufnr) then
            map(
              "<leader>th",
              function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }) end,
              "[T]oggle Inlay [H]ints"
            )
          end

          -- Server-specific on_attach: twoslash-queries for vtsls
          if client.name == "vtsls" then require("twoslash-queries").attach(client, bufnr) end
        end,
      })

      vim.diagnostic.config {
        severity_sort = true,
        float = {
          style = "minimal",
          border = "rounded",
          source = true,
          header = "",
          prefix = "",
          focusable = false,
        },

        -- auto open float window when jumping with [d ]d etc
        jump = { float = true },

        -- don't update diagnostics until out of insert mode
        update_in_insert = false,

        -- only underline errors
        underline = { severity = vim.diagnostic.severity.ERROR },

        virtual_text = true,
        virtual_lines = false,
      }
    end,
  },
  -- {
  --     'hinell/lsp-timeout.nvim',
  --     dependencies = { 'neovim/nvim-lspconfig' },
  -- },
}
