# macOS specific configurations
set -l os (uname)
if test "$os" = "Darwin"
    if test -d "/opt/homebrew/opt/llvm"
        if test ! -e "$HOME/.local/bin/clang-format"
            ln -s "/opt/homebrew/opt/llvm/bin/clang-format" "$HOME/.local/bin/clang-format"
        end
        if test ! -e "$HOME/.local/bin/clang-tidy"
            ln -s "/opt/homebrew/opt/llvm/bin/clang-tidy" "$HOME/.local/bin/clang-tidy"
        end
    end
end
