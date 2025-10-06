#!/usr/bin/env bash
set -e

echo "🏠 Bootstrapping dotfiles..."
echo ""

# Check if we're in the right directory
if [ ! -f "justfile" ] || [ ! -f ".dotfiles.json" ]; then
    echo "❌ Error: Run this script from the dotfiles directory"
    exit 1
fi

DOTFILES_DIR="$(pwd)"
HOME_DIR="$HOME"
CONFIG_FILE=".dotfiles.json"

# First, install jq if needed (we need it to read the config)
if ! command -v jq >/dev/null 2>&1; then
    echo "📦 Installing jq (needed to read config)..."
    brew install jq
fi

# Read bootstrap dependencies from config
echo "📦 Installing required tools..."
while IFS= read -r tool; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "  Installing $tool..."
        brew install "$tool"
    else
        echo "  ✅ $tool already installed"
    fi
done < <(jq -r '.dependencies.bootstrap[]' "$CONFIG_FILE")

echo ""
echo "🧹 Cleaning up old broken symlinks..."

# Remove old broken symlinks from config (all package paths)
while IFS= read -r path; do
    # Skip absolute paths (like /etc/keyd)
    if [[ "$path" == /* ]]; then
        continue
    fi
    full_path="$HOME_DIR/$path"
    # Only remove if it's a symlink (or broken symlink)
    if [ -L "$full_path" ]; then
        rm -f "$full_path"
        echo "  Removed symlink: $path"
    elif [ -e "$full_path" ]; then
        echo "  Skipped (not a symlink): $path"
    fi
done < <(jq -r '.packages[].paths[]' "$CONFIG_FILE")

echo "✅ Cleaned up old symlinks"
echo ""

# Use just to install everything
echo "📦 Installing dotfiles with stow..."
just install

echo ""
echo "✅ Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. Restart your shell or run: source ~/.zshrc"
echo "  2. Run: mise install    (to install tools from mise config)"
echo "  3. Run: just check-deps (to verify everything is installed)"
