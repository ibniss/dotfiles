-- Pull in the wezterm API
local wezterm = require('wezterm')

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Platform detection
local function get_os()
    local target = wezterm.target_triple
    if target:find('apple') then
        return 'macos'
    elseif target:find('linux') then
        return 'linux'
    elseif target:find('windows') then
        return 'windows'
    else
        return 'unknown'
    end
end

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

--- Create a split-nav resize keybinding
---@param key 'Left'|'Right'|'Up'|'Down' arrow key
local function split_nav_resize(key)
    local adjusted_key = key .. 'Arrow'

    return {
        -- resize with arrows
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
                win:perform_action({ AdjustPaneSize = { key, 3 } }, pane)
            end
        end),
    }
end

--- Create a split-nav move keybinding
---@param key 'h'|'j'|'k'|'l' HJKL key
local function split_nav_move(key)
    return {
        -- move with HJKL
        key = key,
        mods = 'CTRL',
        action = wezterm.action_callback(function(win, pane)
            if is_vim(pane) then
                -- pass the keys through to vim/nvim, have to do it separately
                win:perform_action({
                    SendKey = { key = key, mods = 'CTRL' },
                }, pane)
            else
                win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
            end
        end),
    }
end

local home = wezterm.home_dir

local function get_base_project_path() return home .. '/code' end

local function path_exists(path)
    local ret = os.execute('ls ' .. path)
    return ret == 0 or ret == true
end

local base_project_path = get_base_project_path()

-- build up a list of projects to select from
local projects_table = {}

-- add ~/dotfiles if exists
if path_exists(home .. '/dotfiles') then
    table.insert(projects_table, { id = '~/dotfiles', label = 'dotfiles' })
end

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

--- tells nvim and others about the terminal capabilities
config.term = 'wezterm'

-- Make Ctrl+A the leader key
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }

-- Platform-specific keybindings
local word_nav_keys = {}
local os_type = get_os()
if os_type == 'macos' then
    -- macOS uses Option key for word navigation
    word_nav_keys = {
        {
            key = 'LeftArrow',
            mods = 'OPT',
            action = wezterm.action.SendKey({
                key = 'b',
                mods = 'ALT',
            }),
        },
        {
            key = 'RightArrow',
            mods = 'OPT',
            action = wezterm.action.SendKey({ key = 'f', mods = 'ALT' }),
        },
    }
else
    -- Linux/Windows use Ctrl for word navigation
    word_nav_keys = {
        {
            key = 'LeftArrow',
            mods = 'CTRL',
            action = wezterm.action.SendKey({
                key = 'b',
                mods = 'ALT',
            }),
        },
        {
            key = 'RightArrow',
            mods = 'CTRL',
            action = wezterm.action.SendKey({ key = 'f', mods = 'ALT' }),
        },
    }
end

config.keys = {
    -- Platform-specific word navigation
    table.unpack(word_nav_keys),
    {
        mods = 'LEADER | SHIFT',
        key = '"',
        action = wezterm.action.SplitVertical({ domain = 'CurrentPaneDomain' }),
    },
    {
        mods = 'LEADER | SHIFT',
        key = '%',
        action = wezterm.action.SplitHorizontal({
            domain = 'CurrentPaneDomain',
        }),
    },

    -- move between split panes
    split_nav_move('h'),
    split_nav_move('j'),
    split_nav_move('k'),
    split_nav_move('l'),

    -- resize panes
    split_nav_resize('Left'),
    split_nav_resize('Right'),
    split_nav_resize('Up'),
    split_nav_resize('Down'),

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
                    action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
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
                    end),
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

local dark_theme = 'tokyonight_moon'
local light_theme = 'tokyonight_day'

local function scheme_for_appearance(appearance)
    if appearance:find('Dark') then return dark_theme end

    return light_theme
end

config.audible_bell = 'Disabled'
config.color_scheme = scheme_for_appearance(get_appearance())
config.window_decorations = 'RESIZE'

-- Platform-specific window settings
if os_type == 'macos' then config.native_macos_fullscreen_mode = true end

-- keep status bar up to date (polls every few seconds)
wezterm.on('update-right-status', function(window, pane)
    local appearance = get_appearance()

    local overrides = window:get_config_overrides() or {}
    overrides.color_scheme = scheme_for_appearance(appearance)
    window:set_config_overrides(overrides)

    local theme_colors =
        wezterm.get_builtin_color_schemes()[appearance:find('Dark') and dark_theme or light_theme]
    local date = wezterm.strftime('%H:%M')

    window:set_right_status(wezterm.format({
        { Attribute = { Intensity = 'Bold' } },
        { Background = { Color = theme_colors.background } },
        { Foreground = { Color = theme_colors.foreground } },
        { Text = date .. '  ' },
        { Text = '󰉖 ' .. ' ' .. window:active_workspace() },
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

-- Platform-specific configuration
if os_type == 'macos' then
    config.font_size = 18
    config.line_height = 1.25
elseif os_type == 'linux' then
    config.font_size = 14
    config.line_height = 1
end

-- keys
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

return config
