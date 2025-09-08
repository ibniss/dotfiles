-- Pull in the wezterm API
local wezterm = require('wezterm') --[[@as Wezterm]]

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
    local f = io.open(path, 'r')

    if f then
        f:close()
        return true
    end

    return false
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
local os_type = get_os()

config.keys = {
    -- todo: maybe fix for linux
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
    -- C-A D -> debug
    {
        key = 'd',
        mods = 'LEADER',
        action = wezterm.action.ShowDebugOverlay,
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

-- render file:line number strings as links
-- matches e.g. foo.ex:12, src/main.js:42, lib/some-deep/path/file_name-123.rb:999
config.hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(config.hyperlink_rules, {
    regex = [[([\w\./\-_]+:\d+)]],
    format = 'file://$0',
})

--- Resolve a path to a file
--- @param nvim_pane Pane
--- @param clicked_pane Pane
--- @param path string
local function resolve_path(nvim_pane, clicked_pane, path)
    local cwd_uri = clicked_pane:get_current_working_dir() --[[@as Url]]
    local cwd = cwd_uri.path

    local nvim_cwd_uri = nvim_pane:get_current_working_dir() --[[@as Url]]
    local nvim_cwd = nvim_cwd_uri.path

    -- candidate 1: relative to the emitter's cwd
    local cand1 = cwd .. '/' .. path

    if path_exists(cand1) then return cand1 end

    -- candidate 2: relative to the nvim's cwd (nvim root, repo root)
    local cand2 = nvim_cwd .. '/' .. path
    if path_exists(cand2) then return cand2 end

    -- fallback: as-is
    return path
end

-- hijack the open-uri event for hyperlinks in the file:// scheme (as above)
-- This looks for the first pane with a nvim instance and opens the file:line in it
wezterm.on('open-uri', function(window, clicked_pane, uri)
    local path, line = string.match(uri, 'file://(.*):(%d+)$')
    if path and line then
        local tabs = window:mux_window():tabs_with_info()
        for _, tab_with_info in ipairs(tabs) do
            local panes = tab_with_info.tab:panes_with_info()
            for _, pane_with_info in ipairs(panes) do
                local pane = pane_with_info.pane
                local process_name = pane:get_foreground_process_name()
                local is_nvim = process_name:match('nvim$')
                if is_nvim then
                    local abs_path = path

                    if not path:match('^/') then
                        abs_path = resolve_path(pane, clicked_pane, path)
                    end

                    -- send keys -> Escape ":e $file" C-m "${line}G"
                    window:perform_action({
                        SendKey = { key = 'Escape' },
                    }, pane)
                    pane:send_text(string.format(':e %s', abs_path))
                    window:perform_action({
                        SendKey = { key = 'Enter' },
                    }, pane)
                    pane:send_text(string.format('%sG', line))
                    -- focus the pane
                    pane:activate()

                    break
                end
            end
        end

        -- prevent default
        return false
    end
end)

config.window_padding = {
    top = '0.5cell',
    bottom = '0.0cell',
    left = '0.0cell',
    right = '0.0cell',
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

-- zsh/.zshrc

-- keys
config.send_composed_key_when_left_alt_is_pressed = true
config.use_ime = false

return config
