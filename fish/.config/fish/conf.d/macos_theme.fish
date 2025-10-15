# selects correct tokyonight version based on macOS theme
set -l os (uname)
if test "$os" = "Darwin"
    function macos_theme
        set -l os (uname)
        if test "$os" = "Darwin"
            set -l theme (defaults read -g AppleInterfaceStyle 2> /dev/null)
            if test "$theme" = "Dark"
                fish_config theme choose "TokyoNightMoon"
            else
                fish_config theme choose "TokyoNightDay"
            end
        end
    end

    macos_theme
end
