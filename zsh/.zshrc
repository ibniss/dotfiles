# =============================================================================
# Unified ZSH Configuration with Starship
# =============================================================================

# -----------------------------------------------------------------------------
# History and Basic ZSH Settings
# -----------------------------------------------------------------------------
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
bindkey -e

# Completion system
autoload -Uz compinit
compinit

# Load zsh plugins
if [[ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
else
    echo "zsh-autosuggestions not found"
fi


# -----------------------------------------------------------------------------
# Platform Detection and Specific Configurations
# -----------------------------------------------------------------------------
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS specific configurations
    # BREW
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
    export HOMEBREW_PREFIX="/opt/homebrew"
    export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
    export HOMEBREW_REPOSITORY="/opt/homebrew"
    export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:"
    export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
    # BREW END

    # TODO: zsh-syntax-highlighting location with 'brew install zsh-syntax-highlighting'

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux specific configurations
    export PATH="$PATH:/opt/nvim/"
    export PATH="$PATH:/opt/kmonad/"
    export PATH="$PATH:/home/ibniss/.opencode/bin"

    # Key bindings
    typeset -g -A key
    key[Delete]="${terminfo[kdch1]}"
    [[ -n "${key[Delete]}" ]] && bindkey -- "${key[Delete]}" delete-char
    bindkey "^?" backward-delete-char

    # ZSH syntax highlighting location with 'apt install zsh-syntax-highlighting'
    if [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
        source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    fi
fi

# -----------------------------------------------------------------------------
# Common PATH Exports
# -----------------------------------------------------------------------------
export PATH="$HOME/bin:/usr/local/bin:$PATH"
export PATH="/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:$PATH"
export PATH="~/.cargo/bin:$PATH"
export PATH="~/.npm-global/bin:$PATH"

# -----------------------------------------------------------------------------
# XDG and Environment Variables
# -----------------------------------------------------------------------------
export XDG_CONFIG_HOME="$HOME/.config"
export GIT_EDITOR="nvim"
export VIM="nvim"

# -----------------------------------------------------------------------------
# Tool Initialization
# -----------------------------------------------------------------------------

# Cargo environment
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Dune environment
[[ -f "$HOME/.local/share/dune/env/env.zsh" ]] && \
    source "$HOME/.local/share/dune/env/env.zsh"

# Mise (tool version manager)
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
elif [[ -f "$HOME/.local/bin/mise" ]]; then
    eval "$($HOME/.local/bin/mise activate zsh)"
fi

# FZF key bindings and fuzzy completion
# First check if we have a local checkout in ~/.fzf
if [[ -d ~/.fzf ]]; then
    export PATH="$PATH:$HOME/.fzf/bin"
fi

if command -v fzf >/dev/null 2>&1; then
    source <(fzf --zsh)
fi

# TODO: required
# Starship prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
else
    echo "!!! Starship not found"
fi

# TODO: consolidate on .config location, make sure it's consistent with our makefile
# WezTerm integration
if [[ "$OSTYPE" == "darwin"* ]]; then
    [[ -f ~/wezterm.sh ]] && source ~/wezterm.sh
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    [[ -f ~/.config/wezterm/wezterm.sh ]] && source ~/.config/wezterm/wezterm.sh
fi

# -----------------------------------------------------------------------------
# Aliases
# -----------------------------------------------------------------------------
alias vim="nvim"
alias vi="nvim"

alias ll="ls -la"
alias la="ls -A"
alias l="ls -CF"

alias zshconfig="nvim ~/.zshrc"

# -----------------------------------------------------------------------------
# Secure Environment Variable Loading
# -----------------------------------------------------------------------------

# Load local environment variables (gitignored)
[[ -f "$HOME/.env.local" ]] && source "$HOME/.env.local"

# Load project-specific environment variables
[[ -f ".env.local" ]] && source ".env.local"

# -----------------------------------------------------------------------------
# Additional Configurations
# -----------------------------------------------------------------------------

# Enable command auto-correction if available
setopt CORRECT

# Enable extended globbing
setopt EXTENDED_GLOB

# Don't beep on errors
setopt NO_BEEP

# -----------------------------------------------------------------------------
# Plugin Management (Manual)
# -----------------------------------------------------------------------------

# Note: Removed oh-my-zsh in favor of starship + manual plugin loading
# Add any additional zsh plugins here as needed

# Example for adding more plugins:
# [[ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
#     source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
