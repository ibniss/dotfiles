# selects correct tokyonight version based on macOS theme
# automatically detects theme changes on each prompt render
if test (uname) = "Darwin"
    function _macos_get_theme
        set -l style (defaults read -g AppleInterfaceStyle 2>/dev/null)
        test "$style" = "Dark" && echo "Dark" || echo "Light"
    end

    function _macos_apply_theme
        if test "$_macos_current_theme" = "Dark"
            fish_config theme choose "TokyoNightMoon"
        else
            fish_config theme choose "TokyoNightDay"
        end
    end

    function macos_theme
        set -gx _macos_current_theme (_macos_get_theme)
        _macos_apply_theme
    end

    function _macos_theme_check --on-event fish_prompt
        set -l detected (_macos_get_theme)
        if test "$detected" != "$_macos_current_theme"
            set -gx _macos_current_theme $detected
            _macos_apply_theme
        end
    end

    # initial theme setup
    macos_theme
end
