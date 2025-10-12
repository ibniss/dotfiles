# Linux specific configurations
set -l os (uname)
if test "$os" = "Linux"
    set -gx PATH "$PATH:/opt/nvim-linux-x86_64/bin"
    set -gx PATH "$PATH:/opt/kmonad/"
    set -gx PATH "$PATH:/home/ibniss/.opencode/bin"

    # Delete key
    bind \e\[3~ delete-char
    # Backspace key
    bind \x7f backward-delete-char
end

