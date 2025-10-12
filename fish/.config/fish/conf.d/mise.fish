if command -q mise then
    mise activate fish | source
else if test -d "$HOME/.local/bin/mise"; then
    $HOME/.local/bin/mise activate fish | source
end
