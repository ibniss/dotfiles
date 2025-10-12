# macOS specific configurations
set -l os (uname)
if test "$os" = "Darwin"
    set -gx PATH "/opt/homebrew/bin:/opt/homebrew/sbin" $PATH
    set -gx HOMEBREW_PREFIX "/opt/homebrew"
    set -gx HOMEBREW_CELLAR "/opt/homebrew/Cellar"
    set -gx HOMEBREW_REPOSITORY "/opt/homebrew"

    if set -q MANPATH
        set -gx MANPATH "/opt/homebrew/share/man" $MANPATH
    else
        set -gx MANPATH "/opt/homebrew/share/man"
    end

    if set -q INFOPATH
        set -gx INFOPATH "/opt/homebrew/share/info" $INFOPATH
    else
        set -gx INFOPATH "/opt/homebrew/share/info"
    end
end
