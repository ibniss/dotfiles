if command -q mise then
    mise activate fish --shims | source
    if status is-interactive
        mise activate fish | source
    end
else if test -d "$HOME/.local/bin/mise"; then
    $HOME/.local/bin/mise activate fish | source
end
