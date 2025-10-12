# disables fish greeting
set fish_greeting

# -----------------------------------------------------------------------------
# Common PATH Exports
# -----------------------------------------------------------------------------
set -gx PATH "$HOME/bin:/usr/local/bin:$PATH"
set -gx PATH "/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:$PATH"
set -gx PATH "~/.npm-global/bin:$PATH"

# -----------------------------------------------------------------------------
# XDG and Environment Variables
# -----------------------------------------------------------------------------
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx GIT_EDITOR "nvim"
set -gx EDITOR "nvim"
set -gx VISUAL "nvim"

# Set neovim as the program to open manpages
set -gx MANPAGER 'nvim +Man!'
