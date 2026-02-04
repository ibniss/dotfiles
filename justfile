# Dotfiles Management with Stow
# ===============================

# Variables
dotfiles_dir := justfile_directory()
home_dir := env_var('HOME')
config_file := dotfiles_dir / ".dotfiles.json"

# Stow packages (read from config)
stow_packages := `jq -r '[.packages | to_entries[] | select(.value.type == "stow") | .key] | join(" ")' .dotfiles.json`

# Default recipe (shows help)
default:
    @just --list

# Install all dotfiles using stow
install: _install-all-stow _install-keyd-if-linux _install-aerospace-if-macos
    @echo "✅ All dotfiles installed successfully!"
    @echo "ℹ️  Restart your shell"

# Uninstall all dotfiles
uninstall: _uninstall-all-stow
    @echo "✅ All dotfiles uninstalled"

# Install or uninstall a specific package (usage: just pkg nvim install)
pkg package action:
    @just {{action}}-{{package}}

# Stow a package
[private]
_stow package:
    @echo "📦 Installing {{package}} with stow..."
    @stow -v -d {{dotfiles_dir}} -t {{home_dir}} {{package}}
    @echo "✅ {{package}} installed"

# Unstow a package
[private]
_unstow package:
    @echo "🗑️  Uninstalling {{package}} with stow..."
    @stow -v -D -d {{dotfiles_dir}} -t {{home_dir}} {{package}} || true
    @echo "✅ {{package}} uninstalled"

# Install all stow packages
[private]
_install-all-stow:
    @for pkg in {{stow_packages}}; do just _stow $pkg; done

# Uninstall all stow packages
[private]
_uninstall-all-stow:
    @for pkg in {{stow_packages}}; do just _unstow $pkg; done

# Install/uninstall recipes for each package
install-nvim: (_stow "nvim")
install-wezterm: (_stow "wezterm")
install-fish: (_stow "fish")
install-mise: (_stow "mise")
install-opencode: (_stow "opencode")
install-git: (_stow "git")

uninstall-nvim: (_unstow "nvim")
uninstall-wezterm: (_unstow "wezterm")
uninstall-fish: (_unstow "fish")
uninstall-mise: (_unstow "mise")
uninstall-opencode: (_unstow "opencode")
uninstall-git: (_unstow "git")

# Special: Install keyd (Linux only, uses cp not stow)
install-keyd:
    @if [ "{{os()}}" != "linux" ]; then \
        echo "⚠️  keyd is only available on Linux"; \
        exit 0; \
    fi
    @echo "⌨️  Installing keyd configuration..."
    @echo "⚠️  This requires sudo privileges"
    @sudo mkdir -p /etc/keyd
    @sudo cp {{dotfiles_dir}}/keyd/default.conf /etc/keyd/default.conf
    @echo "✅ keyd configuration installed"
    @echo "ℹ️  Restart keyd service: sudo systemctl restart keyd"

[private]
_install-keyd-if-linux:
    @if [ "{{os()}}" = "linux" ]; then just install-keyd; fi

# Special: Install aerospace (macOS only, tiling window manager)
install-aerospace:
    @if [ "{{os()}}" != "macos" ]; then \
        echo "⚠️  aerospace is only available on macOS"; \
        exit 0; \
    fi
    @just _stow aerospace

uninstall-aerospace:
    @if [ "{{os()}}" != "macos" ]; then \
        echo "⚠️  aerospace is only available on macOS"; \
        exit 0; \
    fi
    @just _unstow aerospace

[private]
_install-aerospace-if-macos:
    @if [ "{{os()}}" = "macos" ]; then just install-aerospace; fi

# Show installation status
status:
    @echo "📊 Dotfiles Status"
    @echo "=================="
    @echo "Platform: {{os()}}"
    @echo ""
    @echo "Stow packages:"
    @for pkg in {{stow_packages}}; do just _check-package $pkg; done
    @if [ "{{os()}}" = "linux" ]; then \
        echo ""; \
        echo "Special packages:"; \
        just _check-special keyd "/etc/keyd/default.conf" file; \
    fi

# Check if a stow package is installed
[private]
_check-package package:
    #!/usr/bin/env bash
    printf "  %-15s " "{{package}}:"
    # Get first path from config (most representative)
    path=$(jq -r --arg pkg "{{package}}" '.packages[$pkg].paths[0]' {{config_file}})
    if [ "$path" = "null" ] || [ -z "$path" ]; then
        echo "❓ unknown"
        exit 0
    fi
    # Handle absolute paths
    if [[ "$path" == /* ]]; then
        full_path="$path"
    else
        full_path="{{home_dir}}/$path"
    fi
    if [ -L "$full_path" ] || [ -e "$full_path" ]; then
        echo "✅ installed"
    else
        echo "❌ not installed"
    fi

# Check special packages (keyd)
[private]
_check-special name path type:
    #!/usr/bin/env bash
    printf "  %-15s " "{{name}}:"
    if [ "{{type}}" = "dir" ] && [ -d "{{path}}" ]; then
        echo "✅ installed"
    elif [ "{{type}}" = "file" ] && [ -f "{{path}}" ]; then
        echo "✅ installed"
    else
        echo "❌ not installed"
    fi

# Check if required dependencies are installed
check-deps:
    @echo "🔍 Checking Dependencies"
    @echo "======================="
    @echo "Core tools:"
    @just _check-cmd git "❌"
    @just _check-cmd stow "❌"
    @just _check-cmd nvim "⚠️"
    @just _check-cmd mise "⚠️"
    @just _check-cmd fzf "⚠️"
    @just _check-cmd just "⚠️"
    @echo ""
    @echo "Development:"
    @just _check-cmd dune "⚠️"
    @echo ""
    @echo "Optional:"
    @just _check-cmd zoxide "⚠️"
    @just _check-cmd-or bat batcat "⚠️"
    @just _check-cmd eza "⚠️"

# Check if a command exists
[private]
_check-cmd cmd missing_icon:
    #!/usr/bin/env bash
    printf "  %-15s " "{{cmd}}:"
    if command -v {{cmd}} >/dev/null 2>&1; then
        echo "✅"
    else
        echo "{{missing_icon}}"
    fi

# Check if either of two commands exists (e.g., bat/batcat)
[private]
_check-cmd-or cmd1 cmd2 missing_icon:
    #!/usr/bin/env bash
    printf "  %-15s " "{{cmd1}}:"
    if command -v {{cmd1}} >/dev/null 2>&1; then
        echo "✅"
    elif command -v {{cmd2}} >/dev/null 2>&1; then
        echo "✅ ({{cmd2}})"
    else
        echo "{{missing_icon}}"
    fi

# Remove broken symlinks
clean:
    @echo "🧹 Cleaning broken symlinks..."
    @find {{home_dir}} -maxdepth 1 -type l ! -exec test -e {} \; -print -delete 2>/dev/null || true
    @find {{home_dir}}/.config -maxdepth 2 -type l ! -exec test -e {} \; -print -delete 2>/dev/null || true
    @echo "✅ Cleaned broken symlinks"

# Restow all packages (useful after updating dotfiles repo)
restow:
    @echo "🔄 Restowing all packages..."
    @for pkg in {{stow_packages}}; do \
        echo "Restowing $pkg..."; \
        stow -R -v -d {{dotfiles_dir}} -t {{home_dir}} $pkg; \
    done
    @echo "✅ All packages restowed"

# Show this help
help:
    @echo "🏠 Dotfiles Management (Stow)"
    @echo "============================"
    @echo ""
    @echo "Platform: {{os()}}"
    @echo "Dotfiles: {{dotfiles_dir}}"
    @echo ""
    @echo "Main commands:"
    @echo "  just install         Install all dotfiles with stow"
    @echo "  just uninstall       Remove all stowed symlinks"
    @echo "  just restow          Restow all packages (after repo updates)"
    @echo "  just status          Show installation status"
    @echo "  just check-deps      Check required dependencies (including stow)"
    @echo "  just clean           Remove broken symlinks"
    @echo ""
    @echo "Individual installs:"
    @echo "  just install-nvim    Install Neovim config"
    @echo "  just install-fish     Install fish config"
    @echo "  just install-wezterm Install WezTerm config"
    @echo "  just install-mise    Install mise config"
    @echo "  just install-opencode Install opencode config"
    @echo "  just install-git     Install git config"
    @echo "  just install-keyd    Install keyd config (Linux only)"
    @echo "  just install-aerospace Install aerospace config (macOS only)"
    @echo ""
    @echo "Stow packages: {{stow_packages}}"
    @echo ""
    @echo "Run 'just --list' to see all available recipes"
