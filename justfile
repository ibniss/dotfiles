# Dotfiles Management with Just
# ===============================

# Variables
dotfiles_dir := justfile_directory()
config_dir := env_var('HOME') / '.config'
backup_dir := env_var('HOME') / '.dotfiles-backup-' + `date +%Y%m%d-%H%M%S`

# Default recipe (shows help)
default:
    @just --list

# Install all dotfiles
install: install-nvim install-wezterm install-zsh install-mise install-starship install-keyd-if-linux
    @echo "✅ All dotfiles installed successfully!"
    @echo "ℹ️  Restart your shell or run: source ~/.zshrc"


# Install Neovim configuration
install-nvim:
    @echo "📝 Installing Neovim configuration..."
    @just backup-if-exists {{config_dir}}/nvim
    @just create-symlink {{dotfiles_dir}}/nvim {{config_dir}}/nvim

# Install WezTerm configuration
install-wezterm:
    @echo "🖥️  Installing WezTerm configuration..."
    @just backup-if-exists {{config_dir}}/wezterm
    @just create-symlink {{dotfiles_dir}}/wezterm {{config_dir}}/wezterm
    @just backup-if-exists {{env_var('HOME')}}/wezterm.sh; \
    @just create-symlink {{dotfiles_dir}}/wezterm/wezterm.sh {{config_dir}}/wezterm.sh; \

# Install Zsh configuration
install-zsh:
    @echo "🐚 Installing Zsh configuration..."
    @just backup-if-exists {{env_var('HOME')}}/.zshrc
    @just create-symlink {{dotfiles_dir}}/zsh/.zshrc {{env_var('HOME')}}/.zshrc
    @echo "⚠️  Remember to create ~/.env.local for your API keys"
    @echo "ℹ️  Template available at: {{dotfiles_dir}}/.env.local.example"

# Install mise configuration
install-mise:
    @echo "🔧 Installing mise configuration..."
    @just backup-if-exists {{config_dir}}/mise/config.toml
    @mkdir -p {{config_dir}}/mise
    @just create-symlink {{dotfiles_dir}}/mise/config.toml {{config_dir}}/mise/config.toml

# Install Starship configuration
install-starship:
    @echo "🚀 Installing Starship configuration..."
    @just backup-if-exists {{config_dir}}/starship.toml
    @just create-symlink {{dotfiles_dir}}/starship/starship.toml {{config_dir}}/starship.toml

# Install keyd configuration (Linux only)
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

# Install keyd only if on Linux (helper for install-all)
install-keyd-if-linux:
    @if [ "{{os()}}" = "linux" ]; then just install-keyd; fi

# Uninstall all dotfiles
uninstall: uninstall-nvim uninstall-wezterm uninstall-zsh uninstall-mise uninstall-starship
    @echo "✅ All dotfiles uninstalled"

# Uninstall individual components
uninstall-nvim:
    @echo "🗑️  Removing Neovim symlink..."
    @rm -f {{config_dir}}/nvim

uninstall-wezterm:
    @echo "🗑️  Removing WezTerm symlinks..."
    @rm -f {{config_dir}}/wezterm
    @if [ "{{os()}}" = "macos" ]; then rm -f {{env_var('HOME')}}/wezterm.sh; fi

uninstall-zsh:
    @echo "🗑️  Removing Zsh symlink..."
    @rm -f {{env_var('HOME')}}/.zshrc

uninstall-mise:
    @echo "🗑️  Removing mise symlink..."
    @rm -f {{config_dir}}/mise/config.toml

uninstall-starship:
    @echo "🗑️  Removing Starship symlink..."
    @rm -f {{config_dir}}/starship.toml

# Show installation status
status:
    @echo "📊 Dotfiles Status"
    @echo "=================="
    @echo "Platform: {{os()}}"
    @echo ""
    @echo "Configuration Status:"
    @printf "  %-15s " "nvim:"
    @if [ -L "{{config_dir}}/nvim" ]; then echo "✅ installed"; else echo "❌ not installed"; fi
    @printf "  %-15s " "wezterm:"
    @if [ -L "{{config_dir}}/wezterm" ]; then echo "✅ installed"; else echo "❌ not installed"; fi
    @printf "  %-15s " "zsh:"
    @if [ -L "{{env_var('HOME')}}/.zshrc" ]; then echo "✅ installed"; else echo "❌ not installed"; fi
    @printf "  %-15s " "mise:"
    @if [ -L "{{config_dir}}/mise/config.toml" ]; then echo "✅ installed"; else echo "❌ not installed"; fi
    @printf "  %-15s " "starship:"
    @if [ -L "{{config_dir}}/starship.toml" ]; then echo "✅ installed"; else echo "❌ not installed"; fi
    @if [ "{{os()}}" = "linux" ]; then \
        printf "  %-15s " "keyd:"; \
        if [ -f "/etc/keyd/default.conf" ]; then echo "✅ installed"; else echo "❌ not installed"; fi; \
    fi

# Check if required dependencies are installed
check-deps:
    @echo "🔍 Checking Dependencies"
    @echo "======================="
    @echo "Core tools:"
    @printf "  %-15s " "git:"
    @if command -v git >/dev/null 2>&1; then echo "✅ installed"; else echo "❌ missing"; fi
    @printf "  %-15s " "nvim:"
    @if command -v nvim >/dev/null 2>&1; then echo "✅ installed"; else echo "⚠️  missing"; fi
    @printf "  %-15s " "starship:"
    @if command -v starship >/dev/null 2>&1; then echo "✅ installed"; else echo "⚠️  missing"; fi
    @printf "  %-15s " "mise:"
    @if command -v mise >/dev/null 2>&1; then echo "✅ installed"; else echo "⚠️  missing"; fi
    @printf "  %-15s " "fzf:"
    @if command -v fzf >/dev/null 2>&1; then echo "✅ installed"; else echo "⚠️  missing"; fi
    @printf "  %-15s " "just:"
    @if command -v just >/dev/null 2>&1; then echo "✅ installed"; else echo "⚠️  missing"; fi
    @echo ""
    @echo "Development tools:"
    @printf "  %-15s " "cargo:"
    @if command -v cargo >/dev/null 2>&1; then echo "✅ installed"; else echo "⚠️  missing"; fi
    @printf "  %-15s " "dune:"
    @if command -v dune >/dev/null 2>&1; then echo "✅ installed"; else echo "⚠️  missing"; fi
    @echo ""
    @echo "Optional enhancements:"
    @printf "  %-15s " "zoxide:"
    @if command -v zoxide >/dev/null 2>&1; then echo "✅ installed"; else echo "⚠️  missing"; fi
    @printf "  %-15s " "bat:"
    @if command -v bat >/dev/null 2>&1; then echo "✅ installed"; elif command -v batcat >/dev/null 2>&1; then echo "✅ installed (batcat)"; else echo "⚠️  missing"; fi
    @printf "  %-15s " "eza:"
    @if command -v eza >/dev/null 2>&1; then echo "✅ installed"; else echo "⚠️  missing"; fi

# Remove broken symlinks
clean:
    @echo "🧹 Cleaning broken symlinks..."
    @find {{env_var('HOME')}} -maxdepth 1 -type l ! -exec test -e {} \; -print -delete 2>/dev/null || true
    @find {{config_dir}} -maxdepth 2 -type l ! -exec test -e {} \; -print -delete 2>/dev/null || true
    @echo "✅ Cleaned broken symlinks"

# Show backup restoration info
backup-info:
    @echo "💾 Backup Information"
    @echo "===================="
    @echo ""
    @echo "Backup directory: {{backup_dir}}"
    @echo ""
    @echo "To restore from backup:"
    @echo "  1. Uninstall current dotfiles: just uninstall"
    @echo "  2. Restore from backup directory"
    @echo "  3. Example: cp {{backup_dir}}/.zshrc ~/.zshrc"

# Helper: Create symlink with directory creation
create-symlink src dest:
    @echo "🔗 Linking {{src}} -> {{dest}}"
    @mkdir -p `dirname {{dest}}`
    @ln -sf {{src}} {{dest}}
    @echo "✅ Created symlink: {{dest}}"

# Helper: Backup file/directory if it exists
backup-if-exists path:
    @if [ -e "{{path}}" ] || [ -L "{{path}}" ]; then \
        mkdir -p {{backup_dir}}; \
        echo "💾 Backing up existing {{path}} to {{backup_dir}}"; \
        mv "{{path}}" "{{backup_dir}}/`basename {{path}}`"; \
    fi

# Show this help
help:
    @echo "🏠 Dotfiles Management"
    @echo "====================="
    @echo ""
    @echo "Platform: {{os()}}"
    @echo "Dotfiles: {{dotfiles_dir}}"
    @echo ""
    @echo "Main commands:"
    @echo "  just install         Install all dotfiles"
    @echo "  just uninstall       Remove all symlinks"
    @echo "  just status          Show installation status"
    @echo "  just check-deps      Check required dependencies"
    @echo "  just clean           Remove broken symlinks"
    @echo ""
    @echo "Individual installs:"
    @echo "  just install-nvim    Install Neovim config"
    @echo "  just install-zsh     Install Zsh config"
    @echo "  just install-wezterm Install WezTerm config"
    @echo "  just install-mise    Install mise config"
    @echo "  just install-starship Install Starship config"
    @echo "  just install-keyd    Install keyd config (Linux only)"
    @echo ""
    @echo "Run 'just --list' to see all available recipes"
