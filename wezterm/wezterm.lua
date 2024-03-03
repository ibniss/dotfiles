-- Pull in the wezterm API
local wezterm = require('wezterm')

-- This will hold the configuration.
local config = wezterm.config_builder()

local direction_keys = {
    h = 'Left',
    j = 'Down',
    k = 'Up',
    l = 'Right',
}

local function is_vim(pane)
    -- this is set by the plugin, and unset on ExitPre in Neovim
    return pane:get_user_vars().IS_NVIM == 'true'
end

local function split_nav(resize_or_move, key)
    local adjusted_key = resize_or_move == 'move' and key
        or direction_keys[key] .. 'Arrow'

    return {
        -- move with HJKL, resize with arrows
        key = adjusted_key,
        mods = 'LEADER',
        action = wezterm.action_callback(function(win, pane)
            if is_vim(pane) then
                -- pass the keys through to vim/nvim, have to do it separately
                win:perform_action({
                    SendKey = { key = 'a', mods = 'CTRL' },
                }, pane)
                win:perform_action({
                    SendKey = { key = adjusted_key },
                }, pane)
            else
                if resize_or_move == 'resize' then
                    win:perform_action(
                        { AdjustPaneSize = { direction_keys[key], 3 } },
                        pane
                    )
                else
                    win:perform_action(
                        { ActivatePaneDirection = direction_keys[key] },
                        pane
                    )
                end
            end
        end),
    }
end

--- stuff
config.animation_fps = 180 -- match hz
config.max_fps = 180

-- This is where you actually apply your config choices
config.audible_bell = 'Disabled'
config.color_scheme = 'rose-pine-moon'
config.window_decorations = 'RESIZE'

-- colors from rose-pine-moon
config.colors = {
    tab_bar = {
        background = '#232136',
        active_tab = {
            bg_color = '#56526e',
            fg_color = '#e0def4',
            intensity = 'Bold',
        },
        inactive_tab = {
            bg_color = '#2a283e',
            fg_color = '#e0def4',
        },
        inactive_tab_hover = {
            bg_color = '#44415a',
            fg_color = '#e0def4',
            italic = true,
        },
        new_tab = {
            bg_color = '#2a283e',
            fg_color = '#e0def4',
        },
        new_tab_hover = {
            bg_color = '#44415a',
            fg_color = '#e0def4',
            italic = true,
        },
    },
}

config.window_padding = {
    top = '0.5cell',
    bottom = '0.0cell',
}

-- setup stuff to behave like tmux
config.enable_tab_bar = true
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false -- look like native

-- Make Ctrl+A the leader key
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }

config.keys = {
    -- splitting
    {
        mods = 'LEADER',
        key = '"',
        action = wezterm.action.SplitVertical({ domain = 'CurrentPaneDomain' }),
    },
    {
        mods = 'LEADER',
        key = '%',
        action = wezterm.action.SplitHorizontal({ domain = 'CurrentPaneDomain' }),
    },

    -- move between split panes
    split_nav('move', 'h'),
    split_nav('move', 'j'),
    split_nav('move', 'k'),
    split_nav('move', 'l'),
    -- resize panes
    split_nav('resize', 'h'),
    split_nav('resize', 'j'),
    split_nav('resize', 'k'),
    split_nav('resize', 'l'),

    -- Creating a new tab (tmux window)
    {
        key = 'c',
        mods = 'LEADER',
        action = wezterm.action.SpawnTab('DefaultDomain'),
    },

    -- Moving between tabs N/P
    {
        key = 'n',
        mods = 'LEADER',
        action = wezterm.action.ActivateTabRelative(1),
    },
    {
        key = 'p',
        mods = 'LEADER',
        action = wezterm.action.ActivateTabRelative(-1),
    },

    -- Closing the current pane
    {
        key = 'x',
        mods = 'LEADER',
        action = wezterm.action.CloseCurrentPane({ confirm = true }),
    },

    -- Toggle pane zoom (maximize/restore pane size within its tab)
    { key = 'z', mods = 'LEADER', action = wezterm.action.TogglePaneZoomState },
    -- enter copy mode
    {
        key = 'Enter',
        mods = 'LEADER',
        action = wezterm.action.ActivateCopyMode,
    },
    -- send through C-A to vim
    {
        key = 'a',
        mods = 'LEADER|CTRL',
        action = wezterm.action.SendKey({ key = 'a', mods = 'CTRL' }),
    },
    -- workspaces (~sessions in tmux)
    {
        key = 's',
        mods = 'LEADER',
        action = wezterm.action.ShowLauncherArgs({
            flags = 'FUZZY|WORKSPACES',
            title = 'Workspaces',
        }),
    },
    {
        key = 'w',
        mods = 'LEADER',
        action = wezterm.action.ShowLauncherArgs({
            flags = 'FUZZY|TABS',
            title = 'Tabs',
        }),
    },
}

-- updates status bar to show current workspace
wezterm.on('update-right-status', function(window, pane)
    window:set_right_status('󰉖 ' .. window:active_workspace())
end)

-- leader+number to switch tabs
for i = 1, 9 do
    table.insert(config.keys, {
        key = tostring(i),
        mods = 'LEADER',
        action = wezterm.action.ActivateTab(i - 1),
    })
end

-- Font
config.font = wezterm.font({
    family = 'JetBrains Mono',
    harfbuzz_features = {
        'ss01',
        'ss02',
        'ss03',
        'ss04',
        'ss05',
        'ss06',
        'ss07',
        'ss08',
    },
})

config.font_size = 18

-- keys
config.send_composed_key_when_left_alt_is_pressed = true

return config
