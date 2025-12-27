#!/usr/bin/env bash
# Post-creation hook for devenv container
# This runs after the container is created

set -euo pipefail

echo "🔧 Running post-create hooks..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ----------------------------
# Package Installation
# ----------------------------

# Official repo packages (pacman)
PACMAN_PACKAGES=(
    # Shell & Terminal
    fish
    tmux
    starship
    zoxide
    direnv
    fzf

    # Editors & Tools
    neovim
    git
    git-delta
    ripgrep
    fd
    bat
    eza
    jq
    httpie

    # Security
    age
    sops

    # Development
    nodejs
    npm

    # Kubernetes (official)
    kubectl
)

# AUR packages (yay)
AUR_PACKAGES=(
    # Kubernetes & Cloud
    kubectx
    helm
    kustomize
    k9s
    argocd
    stern
    kubeconform
    krew-bin

    # Infrastructure
    opentofu-bin

    # Git & GitHub
    github-cli
    lazygit

    # Data tools
    yq
    mongosh-bin
    pgcli

    # Cloud providers
    google-cloud-cli

    # Security
    bitwarden-cli

    # Container tools
    dive
    trivy
)

echo "Installing packages from official repos..."
sudo pacman -Sy --noconfirm --needed "${PACMAN_PACKAGES[@]}" || true

echo "Installing packages from AUR..."
if command -v yay &> /dev/null; then
    yay -S --noconfirm --needed "${AUR_PACKAGES[@]}" || true
else
    echo "  ⚠ yay not found, skipping AUR packages"
fi

# ----------------------------
# Claude Code Installation
# ----------------------------

echo "Installing Claude Code..."
if command -v npm &> /dev/null; then
    npm install -g @anthropic-ai/claude-code
    echo "  → Claude Code installed"
else
    echo "  ⚠ npm not found, skipping Claude Code installation"
fi

# ----------------------------
# Shell Configuration
# ----------------------------

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

# ----------------------------
# Configuration Links
# ----------------------------

echo "Linking configurations..."

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$CONFIG_DIR"

# Starship config
if [[ -f "$SCRIPT_DIR/config/starship.toml" ]] && [[ ! -f "$CONFIG_DIR/starship.toml" ]]; then
    ln -sf "$SCRIPT_DIR/config/starship.toml" "$CONFIG_DIR/starship.toml"
    echo "  → Linked starship.toml"
fi

# Fish config
FISH_CONFIG_DIR="$CONFIG_DIR/fish/conf.d"
mkdir -p "$FISH_CONFIG_DIR"
if [[ -f "$SCRIPT_DIR/config/fish/devbox.fish" ]]; then
    ln -sf "$SCRIPT_DIR/config/fish/devbox.fish" "$FISH_CONFIG_DIR/devbox.fish"
    echo "  → Linked fish config"
fi

# Tmux config
if [[ -f "$SCRIPT_DIR/config/tmux.conf" ]]; then
    if [[ ! -f "$CONFIG_DIR/tmux/tmux.conf" ]]; then
        mkdir -p "$CONFIG_DIR/tmux"
        ln -sf "$SCRIPT_DIR/config/tmux.conf" "$CONFIG_DIR/tmux/tmux.conf"
    fi
    if [[ ! -f ~/.tmux.conf ]]; then
        ln -sf "$SCRIPT_DIR/config/tmux.conf" ~/.tmux.conf
    fi
    echo "  → Linked tmux.conf"
fi

# LazyVim suggestion
if [[ ! -d "$CONFIG_DIR/nvim" ]]; then
    echo ""
    echo "📝 Neovim config not found. To install LazyVim:"
    echo "   git clone https://github.com/LazyVim/starter ~/.config/nvim"
    echo "   rm -rf ~/.config/nvim/.git"
fi

# ----------------------------
# Done
# ----------------------------

echo ""
echo "✅ Post-create hooks complete!"
echo ""
echo "Installed tools:"
command -v claude &>/dev/null && echo "  → Claude Code: $(claude --version 2>/dev/null || echo 'installed')"
command -v starship &>/dev/null && echo "  → Starship prompt"
command -v kubectl &>/dev/null && echo "  → kubectl"
command -v k9s &>/dev/null && echo "  → k9s"
command -v nvim &>/dev/null && echo "  → Neovim"
echo ""
echo "To enter the environment:"
echo "   distrobox enter devenv"
