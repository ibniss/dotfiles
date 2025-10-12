set -l os (uname)
if test "$os" = "Darwin"
    set -l theme (defaults read -g AppleInterfaceStyle)
    # if test "$theme" = "Dark"
    #     fish_config theme save "TokyoNight Moon"
    # else
    #     fish_config theme save "TokyoNight Day"
    # end
end
