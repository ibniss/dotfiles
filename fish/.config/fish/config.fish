# disables fish greeting
set fish_greeting

# login-only (ZSH equivalent of ~/.zprofile)
if status is-login
    fish_add_path "$HOME/.local/bin"
end

# -----------------------------------------------------------------------------
# Common PATH Exports
# -----------------------------------------------------------------------------
fish_add_path "$HOME/bin" "/usr/local/bin" "/usr/bin" "/bin"
fish_add_path "/usr/local/sbin" "/usr/sbin" "/sbin"
fish_add_path "~/.npm-global/bin:$PATH"

# -----------------------------------------------------------------------------
# XDG and Environment Variables
# -----------------------------------------------------------------------------
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx GIT_EDITOR "nvim"
set -gx EDITOR "nvim"
set -gx VISUAL "nvim"

# Set neovim as the program to open manpages
set -gx MANPAGER 'nvim +Man!'
