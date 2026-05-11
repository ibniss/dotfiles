return {
  {
    "pmizio/typescript-tools.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "neovim/nvim-lspconfig",
      "marilari88/twoslash-queries.nvim",
    },
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    config = function()
      local function file_exists(path)
        local stat = vim.uv.fs_stat(path)
        return stat and stat.type == "file"
      end

      local function resolve_tsserver_path()
        local bufname = vim.api.nvim_buf_get_name(0)
        if bufname == "" then return nil end

        -- typescript-tools.nvim expects a real `typescript/lib/tsserver.js`.
        -- Some pnpm workspaces alias `typescript` to a compat shim package
        -- such as `@typescript/typescript6`; that shim exposes the JS API but
        -- keeps the actual tsserver in its own nested `typescript` dependency.
        local package_json = vim.fs.find("node_modules/typescript/package.json", {
          upward = true,
          path = vim.fs.dirname(vim.fs.normalize(bufname)),
        })[1]
        if not package_json then return nil end

        local package_dir = vim.fs.dirname(package_json)
        local direct_tsserver = package_dir .. "/lib/tsserver.js"
        if file_exists(direct_tsserver) then return direct_tsserver end
        if vim.fn.executable "node" ~= 1 then return nil end

        -- Resolve from the real pnpm store path so Node can see the shim's
        -- dependency graph. Resolving from the workspace symlink misses it.
        local script = [[
const fs = require("node:fs");
const path = require("node:path");

const packageDir = fs.realpathSync(process.argv[1]);
const direct = path.join(packageDir, "lib", "tsserver.js");
if (fs.existsSync(direct)) {
  console.log(direct);
  process.exit(0);
}

try {
  console.log(require.resolve("typescript/lib/tsserver.js", { paths: [packageDir] }));
} catch {
  process.exit(1);
}
]]

        local result = vim.fn.systemlist { "node", "-e", script, package_dir }
        if vim.v.shell_error ~= 0 or not result[1] or result[1] == "" then return nil end

        local resolved_tsserver = result[1]
        if file_exists(resolved_tsserver) then return resolved_tsserver end

        return nil
      end

      require("typescript-tools").setup {
        on_attach = function(client, buffer_number) require("twoslash-queries").attach(client, buffer_number) end,
        settings = {
          tsserver_path = resolve_tsserver_path(),
          -- Performance: separate diagnostic server for large projects
          separate_diagnostic_server = true,
          -- When to publish diagnostics
          publish_diagnostic_on = "insert_leave",
          -- JSX auto-closing tags
          jsx_close_tag = {
            enable = true,
            filetypes = { "javascriptreact", "typescriptreact" },
          },
          tsserver_file_preferences = {
            includeInlayParameterNameHints = "all",
            includeInlayParameterNameHintsWhenArgumentMatchesName = true,
            includeInlayVariableTypeHints = true,
            includeInlayVariableTypeHintsWhenTypeMatchesName = true,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayEnumMemberValueHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            -- Enable auto imports
            includeCompletionsForModuleExports = true,
            includeCompletionsForImportStatements = true,
          },

          tsserver_format_options = {
            insertSpaceAfterOpeningAndBeforeClosingEmptyBraces = true,
            semicolons = "insert",
          },
          complete_function_calls = true,
          include_completions_with_insert_text = true,
          code_lens = "off",
          disable_member_code_lens = true,
          tsserver_max_memory = 12288,
        },
      }
    end,
  },
}
