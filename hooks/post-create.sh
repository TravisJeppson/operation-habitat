#!/usr/bin/env bash
# Post-creation hook for devenv container
# This runs after the container is created

set -euo pipefail

echo "🔧 Running post-create hooks..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Install Devbox if not present
if ! command -v devbox &> /dev/null; then
    echo "Installing Devbox..."
    curl -fsSL https://get.jetify.com/devbox | bash -s -- -f
    echo "  → Devbox installed"
fi

# Set up devbox shell environment in profile (with guards to prevent errors during init)
if [[ ! -f /etc/profile.d/devbox.sh ]]; then
    sudo tee /etc/profile.d/devbox.sh > /dev/null << 'DEVBOX_PROFILE'
# Devbox global shell environment
# Only run if devbox is installed and initialized
if command -v devbox &> /dev/null && [[ -d "$HOME/.local/share/devbox/global" ]]; then
    eval "$(devbox global shellenv 2>/dev/null)" || true
fi
DEVBOX_PROFILE
    echo "  → Added devbox to /etc/profile.d/"
fi

# Ensure nix/devbox paths are available
export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"

# Install devbox global packages (needed for npm)
echo "Installing devbox packages..."
if [[ -f "$SCRIPT_DIR/devbox.json" ]]; then
    cd "$SCRIPT_DIR"
    devbox install

    # Add packages globally
    PACKAGES=$(jq -r '.packages[]' devbox.json | tr '\n' ' ')
    devbox global add $PACKAGES
fi

# NOW source devbox environment (after global packages are installed)
if command -v devbox &> /dev/null && [[ -d "$HOME/.local/share/devbox/global/default" ]]; then
    eval "$(devbox global shellenv 2>/dev/null)" || true
fi

# Install Claude Code
echo "Installing Claude Code..."
if command -v npm &> /dev/null; then
    npm install -g @anthropic-ai/claude-code
    echo "  → Claude Code installed"
else
    echo "  ⚠ npm not found, skipping Claude Code installation"
fi

# Set fish as default shell for distrobox
FISH_PATH=$(which fish 2>/dev/null || echo "/usr/bin/fish")
if [[ -x "$FISH_PATH" ]]; then
    echo "Configuring fish as default shell..."
    
    # Add fish exec to bashrc for distrobox enter
    if [[ -f ~/.bashrc ]]; then
        if ! grep -q "exec fish" ~/.bashrc; then
            cat >> ~/.bashrc << 'EOF'

# Start fish shell if interactive and fish is available
if [[ $- == *i* ]] && command -v fish &>/dev/null && [[ -z "$FISH_ALREADY_EXEC" ]]; then
    export FISH_ALREADY_EXEC=1
    exec fish
fi
EOF
            echo "  → Configured bashrc to launch fish"
        fi
    fi
fi

# Link configurations
echo "Linking configurations..."

# Starship config
STARSHIP_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$STARSHIP_CONFIG_DIR"
if [[ -f "$SCRIPT_DIR/config/starship.toml" ]] && [[ ! -f "$STARSHIP_CONFIG_DIR/starship.toml" ]]; then
    ln -sf "$SCRIPT_DIR/config/starship.toml" "$STARSHIP_CONFIG_DIR/starship.toml"
    echo "  → Linked starship.toml"
fi

# Fish config
FISH_CONFIG_DIR="$STARSHIP_CONFIG_DIR/fish/conf.d"
mkdir -p "$FISH_CONFIG_DIR"
if [[ -f "$SCRIPT_DIR/config/fish/devbox.fish" ]]; then
    ln -sf "$SCRIPT_DIR/config/fish/devbox.fish" "$FISH_CONFIG_DIR/devbox.fish"
    echo "  → Linked fish devbox config"
fi

# Tmux config
TMUX_CONFIG_DIR="$STARSHIP_CONFIG_DIR/tmux"
mkdir -p "$TMUX_CONFIG_DIR"
if [[ -f "$SCRIPT_DIR/config/tmux.conf" ]] && [[ ! -f "$TMUX_CONFIG_DIR/tmux.conf" ]]; then
    ln -sf "$SCRIPT_DIR/config/tmux.conf" "$TMUX_CONFIG_DIR/tmux.conf"
    echo "  → Linked tmux.conf"
    # Also link to traditional location for compatibility
    if [[ ! -f ~/.tmux.conf ]]; then
        ln -sf "$SCRIPT_DIR/config/tmux.conf" ~/.tmux.conf
    fi
fi

# LazyVim - if not already configured, suggest setup
NVIM_CONFIG_DIR="$STARSHIP_CONFIG_DIR/nvim"
if [[ ! -d "$NVIM_CONFIG_DIR" ]]; then
    echo ""
    echo "📝 Neovim config not found. To install LazyVim:"
    echo "   git clone https://github.com/LazyVim/starter ~/.config/nvim"
    echo "   rm -rf ~/.config/nvim/.git"
fi

echo ""
echo "✅ Post-create hooks complete!"
echo ""
echo "Installed tools:"
echo "  → Claude Code: $(claude --version 2>/dev/null || echo 'run claude --help to verify')"
echo ""
echo "To enter the environment:"
echo "   distrobox enter devenv"