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

--- Create a split-nav keybinding
---@param resize_or_move 'resize' | 'move' Resize or move the pane
---@param key 'h'|'j'|'k'|'l' HJKL key
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

local home = wezterm.home_dir
local base_project_path = home .. '/code'

-- build up a list of projects to select from
local projects_table = {
    -- special case for dotfiles which are not in code
    { id = '~/dotfiles', label = 'dotfiles' },
}

-- get all folders within home/code folder
-- split the string into a table
local projects = io.popen('ls -d ' .. base_project_path .. '/*'):read('*a')
for project in string.gmatch(projects, '([^\n]+)') do
    -- remove the base path
    local project_name = string.gsub(project, base_project_path .. '/', '')
    -- add to table
    table.insert(projects_table, { id = project, label = project_name })
end

--- stuff
config.animation_fps = 180 -- match hz
config.max_fps = 180

-- This is where you actually apply your config choices

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
        action = wezterm.action.SplitHorizontal({
            domain = 'CurrentPaneDomain',
        }),
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
    -- fuzzy find workspaces per project or create new
    {
        key = 'f',
        mods = 'LEADER',
        action = wezterm.action_callback(function(window, pane)
            window:perform_action(
                wezterm.action.InputSelector({
                    action = wezterm.action_callback(
                        function(inner_window, inner_pane, id, label)
                            if not id and not label then
                                wezterm.log_info('No project selected')
                            else
                                wezterm.log_info('Selected project: ' .. id)
                                inner_window:perform_action(
                                    wezterm.action.SwitchToWorkspace({
                                        name = label,
                                        spawn = {
                                            label = 'Workspace: ' .. label,
                                            cwd = id,
                                        },
                                    }),
                                    inner_pane
                                )
                            end
                        end
                    ),
                    title = 'Choose Project',
                    choices = projects_table,
                    fuzzy = true,
                    fuzzy_description = 'Fuzzy find and/or make a workspace for a project: ',
                }),
                pane
            )
        end),
    },
}

-- leader+number to switch tabs
for i = 1, 9 do
    table.insert(config.keys, {
        key = tostring(i),
        mods = 'LEADER',
        action = wezterm.action.ActivateTab(i - 1),
    })
end

-- VISUAL
--
local function get_appearance()
    if wezterm.gui then return wezterm.gui.get_appearance() end
    return 'Dark'
end

local function scheme_for_appearance(appearance)
    if appearance:find('Dark') then return 'rose-pine-moon' end

    return 'rose-pine-dawn'
end

config.audible_bell = 'Disabled'
config.color_scheme = 'rose-pine-moon'
config.window_decorations = 'RESIZE'

local rose_moon_colors = {
    base = '#232136',
    text = '#e0def4',
    highlight_low = '#2a283e',
    highlight_med = '#44415a',
    highlight_high = '#56526e',
}

local rose_dawn_colors = {
    base = '#faf4ed',
    text = '#575279',
    highlight_low = '#f4e3d9',
    highlight_med = '#dfdad9',
    highlight_high = '#cecacd',
}

local function get_tab_colors(is_dark)
    local theme_colors = is_dark and rose_moon_colors or rose_dawn_colors

    return {
        background = theme_colors.base,
        active_tab = {
            bg_color = theme_colors.highlight_high,
            fg_color = theme_colors.text,
            intensity = 'Bold',
        },
        inactive_tab = {
            bg_color = theme_colors.highlight_low,
            fg_color = theme_colors.text,
        },
        inactive_tab_hover = {
            bg_color = theme_colors.highlight_med,
            fg_color = theme_colors.text,
            italic = true,
        },
        new_tab = {
            bg_color = theme_colors.highlight_low,
            fg_color = theme_colors.text,
        },
        new_tab_hover = {
            bg_color = theme_colors.highlight_med,
            fg_color = theme_colors.text,
            italic = true,
        },
    }
end

-- keep status bar up to date (polls every few seconds)
wezterm.on('update-right-status', function(window, pane)
    local appearance = get_appearance()

    local overrides = window:get_config_overrides() or {}
    overrides.color_scheme = scheme_for_appearance(appearance)
    overrides.colors = {
        tab_bar = get_tab_colors(appearance:find('Dark')),
    }
    window:set_config_overrides(overrides)

    local theme_colors = appearance:find('Dark') and rose_moon_colors
        or rose_dawn_colors

    window:set_right_status(wezterm.format({
        { Attribute = { Intensity = 'Bold' } },
        { Background = { Color = theme_colors.base } },
        { Foreground = { Color = theme_colors.text } },
        { Text = '󰉖 ' .. window:active_workspace() },
    }))
end)

config.window_padding = {
    top = '0.5cell',
    bottom = '0.0cell',
}

-- setup stuff to behave like tmux
config.enable_tab_bar = true
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false -- look like native

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
