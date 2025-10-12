if command -q mise then
    if status is-login
        mise activate fish --shims | source
    end
    mise activate fish | source
else if test -d "$HOME/.local/bin/mise"; then
    $HOME/.local/bin/mise activate fish | source
end
