# Homebrew installs its own Fish activation hook. Keep this configuration as
# the single source of truth instead of initializing Mise a second time.
set -gx MISE_FISH_AUTO_ACTIVATE 0

set -l mise_bin
if command -q mise
    set mise_bin (command --search mise)
else if test -x "$HOME/.local/bin/mise"
    set mise_bin "$HOME/.local/bin/mise"
end

if test -n "$mise_bin"
    set -l cache_home "$HOME/.cache"
    if test -n "$XDG_CACHE_HOME"
        set cache_home "$XDG_CACHE_HOME"
    end

    set -l mise_cache_dir "$cache_home/fish"
    set -l mise_cache "$mise_cache_dir/mise-activate.fish"
    set -l mise_executable (path resolve "$mise_bin")
    set -l mise_cache_header "# mise executable: $mise_executable"
    set -l mise_cache_current false

    if test -s "$mise_cache"
        read -l mise_cached_header < "$mise_cache"
        if test "$mise_cached_header" = "$mise_cache_header"
            if not test "$mise_executable" -nt "$mise_cache"
                set mise_cache_current true
            end
        end
    end

    if test "$mise_cache_current" = false
        command mkdir -p "$mise_cache_dir"
        set -l mise_cache_tmp "$mise_cache.$fish_pid"

        # Generate from a clean activation context so the cached script does
        # not capture PATH changes inherited from a parent Mise shell.
        begin
            echo "$mise_cache_header"
            command env -u MISE_SHELL -u __MISE_DIFF -u __MISE_SESSION \
                -u __MISE_ORIG_PATH "$mise_executable" activate fish
        end > "$mise_cache_tmp"
        set -l mise_generate_status $status

        if test $mise_generate_status -eq 0; and command mv "$mise_cache_tmp" "$mise_cache"
            set mise_cache_current true
        else
            command rm -f "$mise_cache_tmp"
        end
    end

    if test "$mise_cache_current" = true
        source "$mise_cache"
    else
        "$mise_executable" activate fish | source
    end
end
