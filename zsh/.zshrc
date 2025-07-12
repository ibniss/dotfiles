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

# Antidote plugin manager
# Clone antidote if it doesn't exist
if [[ ! -d ~/.antidote ]]; then
    git clone --depth=1 https://github.com/mattmc3/antidote.git ~/.antidote
fi

# Initialize antidote
source ~/.antidote/antidote.zsh

# Load plugins from .zsh_plugins.txt
antidote load ${ZDOTDIR:-$HOME}/.zsh_plugins.txt


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

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux specific configurations
    export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
    export PATH="$PATH:/opt/kmonad/"
    export PATH="$PATH:/home/ibniss/.opencode/bin"

    # Key bindings
    typeset -g -A key
    key[Delete]="${terminfo[kdch1]}"
    [[ -n "${key[Delete]}" ]] && bindkey -- "${key[Delete]}" delete-char
    bindkey "^?" backward-delete-char
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
    # FZF colors to match your theme
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
fi

# Starship prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
else
    echo "!!! Starship not found"
fi

# WezTerm integration
[[ -f ~/.config/wezterm/wezterm.sh ]] && source ~/.config/wezterm/wezterm.sh

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# -----------------------------------------------------------------------------
# Aliases
# -----------------------------------------------------------------------------
alias vim="nvim"
alias vi="nvim"
alias v="nvim"
export EDITOR=nvim
export VISUAL=nvim


alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# Replacement tools
if command -v bat >/dev/null 2>&1; then
    alias cat="bat"
    alias less="bat"
elif command -v batcat >/dev/null 2>&1; then
    alias cat="batcat"
    alias less="batcat"
fi

if command -v eza >/dev/null 2>&1; then
    alias ls="eza"
    alias ll="eza -l"
    alias la="eza -a"
    alias l="eza -C"
else
    alias ls='ls --color=auto'
    alias ll="ls -la"
    alias la="ls -A"
    alias l="ls -CF"
fi


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
# Plugin Configuration
# -----------------------------------------------------------------------------

# Configure zsh-autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "/$HOME/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "/$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "/$HOME/google-cloud-sdk/completion.zsh.inc"; fi

