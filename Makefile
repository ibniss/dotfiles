# =============================================================================
# Dotfiles Management Makefile
# =============================================================================

# -----------------------------------------------------------------------------
# OLD MAKEFILE (for reference)
# -----------------------------------------------------------------------------
# link-nvim:
# 	rm -rf ~/.config/nvim
# 	ln -s $(PWD)/nvim ~/.config/nvim
# 
# link-wezterm:
# 	rm -f ~/.wezterm.lua
# 	ln -s $(PWD)/wezterm ~/.config/wezterm
# 	rm -f ~/wezterm.sh
# 	ln -s $(PWD)/wezterm/wezterm.sh ~/wezterm.sh
# 
# link-zsh:
# 	rm -f ~/.zshrc
# 	ln -s $(PWD)/zsh/.zshrc ~/.zshrc
# 	rm -f ~/.zprofile
# 	ln -s $(PWD)/zsh/.zsh_profile ~/.zprofile
# 
# link-mise:
# 	rm -f ~/.config/mise/config.toml
# 	mkdir -p ~/.config/mise
# 	ln -s $(PWD)/mise/config.toml ~/.config/mise/config.toml
# 
# link-keyd:
# 	sudo cp $(PWD)/keyd/default.conf  /etc/keyd/default.conf

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
NC := \033[0m # No Color

# Platform detection
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    PLATFORM := macos
else ifeq ($(UNAME_S),Linux)
    PLATFORM := linux
else
    PLATFORM := unknown
endif

# Directories
DOTFILES_DIR := $(PWD)
CONFIG_DIR := $(HOME)/.config
BACKUP_DIR := $(HOME)/.dotfiles-backup-$(shell date +%Y%m%d-%H%M%S)

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------
define print_header
	@echo -e "$(CYAN)━━━ $(1) ━━━$(NC)"
endef

define print_success
	@echo -e "$(GREEN)✓$(NC) $(1)"
endef

define print_warning
	@echo -e "$(YELLOW)⚠$(NC) $(1)"
endef

define print_error
	@echo -e "$(RED)✗$(NC) $(1)"
endef

define print_info
	@echo -e "$(BLUE)ℹ$(NC) $(1)"
endef

define backup_if_exists
	@if [ -e "$(1)" ] || [ -L "$(1)" ]; then \
		mkdir -p "$(BACKUP_DIR)"; \
		echo -e "$(YELLOW)⚠$(NC) Backing up existing $(1) to $(BACKUP_DIR)"; \
		mv "$(1)" "$(BACKUP_DIR)/$(notdir $(1))"; \
	fi
endef

define create_symlink
	@$(call print_info,Linking $(1) -> $(2))
	@mkdir -p "$(dir $(2))"
	@ln -sf "$(1)" "$(2)"
	@$(call print_success,Created symlink: $(2))
endef

# -----------------------------------------------------------------------------
# Help Target
# -----------------------------------------------------------------------------
.PHONY: help
help: ## Show this help message
	@echo -e "$(CYAN)Dotfiles Management$(NC)"
	@echo -e "$(CYAN)==================$(NC)"
	@echo ""
	@echo -e "$(BLUE)Platform:$(NC) $(PLATFORM)"
	@echo -e "$(BLUE)Dotfiles:$(NC) $(DOTFILES_DIR)"
	@echo ""
	@echo -e "$(PURPLE)Available targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(CYAN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo -e "$(PURPLE)Installation targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^install-[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo -e "$(PURPLE)Removal targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^uninstall-[a-zA-Z_-]+:.*?## / {printf "  $(RED)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# -----------------------------------------------------------------------------
# Main Installation Targets
# -----------------------------------------------------------------------------
.PHONY: install
install: ## Install all dotfiles
	$(call print_header,Installing all dotfiles)
	@$(MAKE) install-nvim
	@$(MAKE) install-wezterm
	@$(MAKE) install-zsh
	@$(MAKE) install-mise
	@$(MAKE) install-starship
ifeq ($(PLATFORM),linux)
	@$(MAKE) install-keyd
endif
	@echo ""
	$(call print_success,All dotfiles installed successfully!)
	$(call print_info,Restart your shell or run: source ~/.zshrc)

.PHONY: install-minimal
install-minimal: ## Install minimal set (nvim, zsh, starship)
	$(call print_header,Installing minimal dotfiles)
	@$(MAKE) install-nvim
	@$(MAKE) install-zsh
	@$(MAKE) install-starship
	@echo ""
	$(call print_success,Minimal dotfiles installed!)

# -----------------------------------------------------------------------------
# Individual Installation Targets
# -----------------------------------------------------------------------------
.PHONY: install-nvim
install-nvim: ## Install Neovim configuration
	$(call print_header,Installing Neovim configuration)
	@$(call backup_if_exists,$(CONFIG_DIR)/nvim)
	@$(call create_symlink,$(DOTFILES_DIR)/nvim,$(CONFIG_DIR)/nvim)

.PHONY: install-wezterm
install-wezterm: ## Install WezTerm configuration
	$(call print_header,Installing WezTerm configuration)
	@$(call backup_if_exists,$(CONFIG_DIR)/wezterm)
	@$(call create_symlink,$(DOTFILES_DIR)/wezterm,$(CONFIG_DIR)/wezterm)
ifeq ($(PLATFORM),macos)
	@$(call backup_if_exists,$(HOME)/wezterm.sh)
	@$(call create_symlink,$(DOTFILES_DIR)/wezterm/wezterm.sh,$(HOME)/wezterm.sh)
endif

.PHONY: install-zsh
install-zsh: ## Install Zsh configuration
	$(call print_header,Installing Zsh configuration)
	@$(call backup_if_exists,$(HOME)/.zshrc)
	@$(call create_symlink,$(DOTFILES_DIR)/zsh/.zshrc,$(HOME)/.zshrc)
	@$(call print_warning,Remember to create ~/.env.local for your API keys)
	@$(call print_info,Template available at: $(DOTFILES_DIR)/.env.local.example)

.PHONY: install-mise
install-mise: ## Install mise configuration
	$(call print_header,Installing mise configuration)
	@$(call backup_if_exists,$(CONFIG_DIR)/mise/config.toml)
	@mkdir -p "$(CONFIG_DIR)/mise"
	@$(call create_symlink,$(DOTFILES_DIR)/mise/config.toml,$(CONFIG_DIR)/mise/config.toml)

.PHONY: install-starship
install-starship: ## Install Starship configuration
	$(call print_header,Installing Starship configuration)
	@$(call backup_if_exists,$(CONFIG_DIR)/starship.toml)
	@$(call create_symlink,$(DOTFILES_DIR)/starship/starship.toml,$(CONFIG_DIR)/starship.toml)

.PHONY: install-keyd
install-keyd: ## Install keyd configuration (Linux only, requires sudo)
ifeq ($(PLATFORM),linux)
	$(call print_header,Installing keyd configuration)
	@$(call print_warning,This requires sudo privileges)
	@sudo mkdir -p /etc/keyd
	@sudo cp "$(DOTFILES_DIR)/keyd/default.conf" /etc/keyd/default.conf
	@$(call print_success,keyd configuration installed)
	@$(call print_info,Restart keyd service: sudo systemctl restart keyd)
else
	@$(call print_warning,keyd is only available on Linux)
endif

# -----------------------------------------------------------------------------
# Uninstallation Targets
# -----------------------------------------------------------------------------
.PHONY: uninstall
uninstall: ## Uninstall all dotfiles (removes symlinks)
	$(call print_header,Uninstalling all dotfiles)
	@$(MAKE) uninstall-nvim
	@$(MAKE) uninstall-wezterm
	@$(MAKE) uninstall-zsh
	@$(MAKE) uninstall-mise
	@$(MAKE) uninstall-starship
	@echo ""
	$(call print_success,All dotfiles uninstalled)

.PHONY: uninstall-nvim
uninstall-nvim: ## Uninstall Neovim configuration
	@$(call print_info,Removing Neovim symlink)
	@rm -f "$(CONFIG_DIR)/nvim"

.PHONY: uninstall-wezterm
uninstall-wezterm: ## Uninstall WezTerm configuration
	@$(call print_info,Removing WezTerm symlinks)
	@rm -f "$(CONFIG_DIR)/wezterm"
ifeq ($(PLATFORM),macos)
	@rm -f "$(HOME)/wezterm.sh"
endif

.PHONY: uninstall-zsh
uninstall-zsh: ## Uninstall Zsh configuration
	@$(call print_info,Removing Zsh symlink)
	@rm -f "$(HOME)/.zshrc"

.PHONY: uninstall-mise
uninstall-mise: ## Uninstall mise configuration
	@$(call print_info,Removing mise symlink)
	@rm -f "$(CONFIG_DIR)/mise/config.toml"

.PHONY: uninstall-starship
uninstall-starship: ## Uninstall Starship configuration
	@$(call print_info,Removing Starship symlink)
	@rm -f "$(CONFIG_DIR)/starship.toml"

# -----------------------------------------------------------------------------
# Utility Targets
# -----------------------------------------------------------------------------
.PHONY: status
status: ## Show installation status of all dotfiles
	$(call print_header,Dotfiles Status)
	@echo -e "$(BLUE)Platform:$(NC) $(PLATFORM)"
	@echo ""
	@echo -e "$(PURPLE)Configuration Status:$(NC)"
	@printf "  %-15s " "nvim:"
	@if [ -L "$(CONFIG_DIR)/nvim" ]; then echo -e "$(GREEN)✓ installed$(NC)"; else echo -e "$(RED)✗ not installed$(NC)"; fi
	@printf "  %-15s " "wezterm:"
	@if [ -L "$(CONFIG_DIR)/wezterm" ]; then echo -e "$(GREEN)✓ installed$(NC)"; else echo -e "$(RED)✗ not installed$(NC)"; fi
	@printf "  %-15s " "zsh:"
	@if [ -L "$(HOME)/.zshrc" ]; then echo -e "$(GREEN)✓ installed$(NC)"; else echo -e "$(RED)✗ not installed$(NC)"; fi
	@printf "  %-15s " "mise:"
	@if [ -L "$(CONFIG_DIR)/mise/config.toml" ]; then echo -e "$(GREEN)✓ installed$(NC)"; else echo -e "$(RED)✗ not installed$(NC)"; fi
	@printf "  %-15s " "starship:"
	@if [ -L "$(CONFIG_DIR)/starship.toml" ]; then echo -e "$(GREEN)✓ installed$(NC)"; else echo -e "$(RED)✗ not installed$(NC)"; fi
ifeq ($(PLATFORM),linux)
	@printf "  %-15s " "keyd:"
	@if [ -f "/etc/keyd/default.conf" ]; then echo -e "$(GREEN)✓ installed$(NC)"; else echo -e "$(RED)✗ not installed$(NC)"; fi
endif

.PHONY: check-deps
check-deps: ## Check if required dependencies are installed
	$(call print_header,Checking Dependencies)
	@echo -e "$(PURPLE)Required tools:$(NC)"
	@printf "  %-15s " "git:"
	@if command -v git >/dev/null 2>&1; then echo -e "$(GREEN)✓ installed$(NC)"; else echo -e "$(RED)✗ missing$(NC)"; fi
	@printf "  %-15s " "nvim:"
	@if command -v nvim >/dev/null 2>&1; then echo -e "$(GREEN)✓ installed$(NC)"; else echo -e "$(YELLOW)⚠ missing$(NC)"; fi
	@printf "  %-15s " "starship:"
	@if command -v starship >/dev/null 2>&1; then echo -e "$(GREEN)✓ installed$(NC)"; else echo -e "$(YELLOW)⚠ missing$(NC)"; fi
	@printf "  %-15s " "mise:"
	@if command -v mise >/dev/null 2>&1; then echo -e "$(GREEN)✓ installed$(NC)"; else echo -e "$(YELLOW)⚠ missing$(NC)"; fi
	@printf "  %-15s " "fzf:"
	@if command -v fzf >/dev/null 2>&1; then echo -e "$(GREEN)✓ installed$(NC)"; else echo -e "$(YELLOW)⚠ missing$(NC)"; fi

.PHONY: backup-restore
backup-restore: ## Show how to restore from backup
	@echo -e "$(CYAN)Backup Restoration$(NC)"
	@echo -e "$(CYAN)==================$(NC)"
	@echo ""
	@echo -e "$(BLUE)Backup directory:$(NC) $(BACKUP_DIR)"
	@echo ""
	@echo -e "$(PURPLE)To restore from backup:$(NC)"
	@echo "  1. Uninstall current dotfiles: make uninstall"
	@echo "  2. Restore from backup directory"
	@echo "  3. Example: cp $(BACKUP_DIR)/.zshrc ~/.zshrc"

.PHONY: clean
clean: ## Remove broken symlinks in home directory
	$(call print_header,Cleaning broken symlinks)
	@find $(HOME) -maxdepth 1 -type l ! -exec test -e {} \; -print -delete 2>/dev/null || true
	@find $(CONFIG_DIR) -maxdepth 2 -type l ! -exec test -e {} \; -print -delete 2>/dev/null || true
	@$(call print_success,Cleaned broken symlinks)

# -----------------------------------------------------------------------------
# Default Target
# -----------------------------------------------------------------------------
.DEFAULT_GOAL := help