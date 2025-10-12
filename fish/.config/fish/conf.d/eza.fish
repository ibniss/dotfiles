if command -q eza then
    alias ls="eza"
    alias ll="eza -l"
    alias la="eza -a"
    alias l="eza"
else
    alias ls='ls --color=auto'
    alias ll="ls -la"
    alias la="ls -A"
    alias l="ls -CF"
end
