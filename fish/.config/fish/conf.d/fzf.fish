if test -d ~/.fzf
    set -gx PATH "$HOME/.fzf" $PATH
end

if command -q fzf then
    fzf --fish | source
    set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border"
end
