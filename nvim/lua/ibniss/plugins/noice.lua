return {
    'folke/noice.nvim',
    event = 'VeryLazy',
    dependencies = {
        -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
        'MunifTanjim/nui.nvim',
        -- OPTIONAL:
        --   `nvim-notify` is only needed, if you want to use the notification view.
        --   If not available, we use `mini` as the fallback
        {
            'rcarriga/nvim-notify',
            keys = {
                {
                    '<leader>un',
                    function()
                        require('notify').dismiss({
                            silent = true,
                            pending = true,
                        })
                    end,
                    desc = 'Dismiss all Notifications',
                },
            },
            config = function()
                local tokyonight = require('tokyonight.colors').setup()

                require('notify').setup({
                    timeout = 1500,
                    fps = 180,
                    stages = 'fade_in_slide_out',
                    max_height = function()
                        return math.floor(vim.o.lines * 0.75)
                    end,
                    max_width = function()
                        return math.floor(vim.o.columns * 0.75)
                    end,
                    on_open = function(win)
                        vim.api.nvim_win_set_config(win, { zindex = 100 })
                    end,
                    render = 'wrapped-compact',
                })

                vim.cmd([[ hi NotifyBackground guibg = ]] .. tokyonight.bg)
            end,
        },
    },
    opts = {
        lsp = {
            override = {
                ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
                ['vim.lsp.util.stylize_markdown'] = true,
                ['cmp.entry.get_documentation'] = true,
            },
        },
        routes = {
            {
                filter = {
                    event = 'msg_show',
                    any = {
                        { find = '%d+L, %d+B' },
                        { find = '; after #%d+' },
                        { find = '; before #%d+' },
                    },
                },
                view = 'mini',
            },
        },
        hover = {
            silent = true, -- don't notify when no hover info
        },
        presets = {
            bottom_search = false,
            command_palette = true,
            long_message_to_split = true,
            inc_rename = true,
            lsp_doc_border = true,
        },
        views = {
            mini = {
                win_options = {
                    winblend = 0,
                },
            },
            hover = {
                win_options = {
                    winblend = 0,
                },
            },
        },
        -- TODO: can customise markdown highlight to capture jsdoc/pydoc docstrings better
    },
    -- stylua: ignore
    keys = {
      { "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, mode = "c", desc = "Redirect Cmdline" },
      { "<c-f>", function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end, silent = true, expr = true, desc = "Scroll forward", mode = {"i", "n", "s"} },
      { "<c-b>", function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true, expr = true, desc = "Scroll backward", mode = {"i", "n", "s"}},
    },
}
