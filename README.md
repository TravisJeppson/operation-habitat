# Personal Development Environment

A portable, reproducible development environment using distrobox + Devbox.

## Philosophy

This environment separates concerns into layers:

|Layer    |Tool            |Purpose                             |
|———|-—————|————————————|
|Host     |Any Linux / WSL2|Just needs podman/docker + distrobox|
|Container|Arch Linux      |System packages, stable base        |
|Dev Tools|Devbox (Nix)    |Reproducible, declarative toolchain |

## Quick Start

```bash
# Clone to your preferred location
git clone <this-repo> ~/.config/devenv
cd ~/.config/devenv

# Build and enter the environment
./bootstrap.sh
```

## What’s Included

### Kubernetes & Infrastructure

- kubectl, kubectx, kubens
- k9s (TUI for k8s)
- helm, kustomize
- opentofu, terragrunt
- argocd (GitOps CD)
- kargo (progressive delivery)
- stern (multi-pod log tailing)
- kubeconform (manifest validation)
- krew (kubectl plugin manager)

### Cloud & Databases

- google-cloud-sdk (gcloud CLI)
- mongosh (MongoDB shell)
- pgcli (PostgreSQL with autocomplete)

### Security & Secrets

- sops (encrypted secrets)
- age (encryption)
- bitwarden-cli (password manager)
- trivy (vulnerability scanner)

### Development

- neovim (bring your own config, e.g., LazyVim)
- claude (Claude Code CLI)
- git, gh (GitHub CLI)
- lazygit (TUI for git)
- delta (better git diffs)
- ripgrep, fd, fzf, bat, eza
- jq, yq
- httpie (modern curl)
- dive (docker image explorer)
- nodejs (for Claude Code and npm tools)

### Shell

- fish shell (default)
- starship prompt (Monokai Pro themed)
- tmux (Monokai Pro themed)
- zoxide (smart cd)
- direnv (per-directory env)

## Theme

All configs use the **Monokai Pro** color palette:

|Color |Hex      |Usage                 |
|——|———|-———————|
|Red   |`#ff6188`|Errors, deletions     |
|Orange|`#fc9867`|Warnings, Rust        |
|Yellow|`#ffd866`|Modified, Python      |
|Green |`#a9dc76`|Success, additions    |
|Blue  |`#78dce8`|Info, k8s, directories|
|Purple|`#ab9df2`|Git branch, Terraform |

## Directory Structure

```
.
├── Containerfile            # Arch base image
├── distrobox-assemble.yaml  # Container configuration
├── devbox.json              # Development tools (Nix packages)
├── bootstrap.sh             # One-liner setup
├── config/
│   ├── starship.toml        # Starship prompt (Monokai Pro)
│   ├── tmux.conf            # Tmux config (Monokai Pro)
│   └── fish/
│       └── devbox.fish      # Fish shell integration
└── hooks/
    └── post-create.sh       # Runs after container creation
```

## Customization

### Adding tools

Edit `devbox.json` and add packages. Search for available packages:

```bash
devbox search <package>
```

Then add to the packages list and run:

```bash
devbox install
```

### Adding system packages

If you need something that must be in the base image (rare), edit `Containerfile` and rebuild:

```bash
./bootstrap.sh —rebuild
```

### Shell configuration

Your dotfiles are mounted from `$HOME`, so your existing configs just work. The container shares your home directory.

## How It Works

1. **distrobox-assemble** reads `distrobox-assemble.yaml` and creates a container
1. The container uses a custom Arch image built from `Containerfile`
1. On first entry, `devbox install` runs to set up the Nix-based tools
1. Your `$HOME` is mounted, so dotfiles, SSH keys, and configs are available

## Requirements

### Host system needs:

- podman (recommended) or docker
- distrobox

### Install on common distros:

```bash
# Fedora/RHEL
sudo dnf install podman distrobox

# Arch
sudo pacman -S podman distrobox

# Ubuntu/Debian
sudo apt install podman distrobox

# WSL2 (Ubuntu)
sudo apt install podman
curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sudo sh
```

## Tips

### Key Aliases

|Alias      |Command         |Category|
|————|-—————|———|
|`k`        |kubectl         |k8s     |
|`kx` / `kn`|kubectx / kubens|k8s     |
|`kgp`      |kubectl get pods|k8s     |
|`klog`     |kubectl logs -f |k8s     |
|`argo`     |argocd          |GitOps  |
|`tf`       |tofu            |IaC     |
|`tg`       |terragrunt      |IaC     |
|`v` / `vim`|nvim            |Dev     |
|`lg`       |lazygit         |Git     |
|`cc`       |claude          |Dev     |
|`ll`       |eza -la –git    |Files   |
|`lt`       |eza –tree       |Files   |

### Fish Functions

|Function            |Description         |
|———————|———————|
|`ksh <pod>`         |Shell into pod      |
|`kbash <pod>`       |Bash into pod       |
|`kwatch <resource>` |Watch k8s resources |
|`klogs <selector>`  |Stern multi-pod logs|
|`ksecret <name>`    |Decode k8s secret   |
|`argolist`          |List ArgoCD apps    |
|`dockerdive <image>`|Analyze docker image|

### Entering the environment

```bash
distrobox enter devenv
```

### Tmux Key Bindings

Prefix is `Ctrl-a` (not default `Ctrl-b`):

|Key               |Action          |
|——————|-—————|
|`Ctrl-a |`        |Split vertical  |
|`Ctrl-a -`        |Split horizontal|
|`Ctrl-a h/j/k/l`  |Navigate panes  |
|`Ctrl-a H/J/K/L`  |Resize panes    |
|`Alt-1` to `Alt-9`|Switch windows  |
|`Ctrl-a r`        |Reload config   |
|`Ctrl-a S`        |New session     |

### Exporting apps to host

```bash
# Make k9s available on host
distrobox-export —app k9s

# Export a binary
distrobox-export —bin /usr/bin/kubectl —export-path ~/.local/bin
```

### VSCode/Cursor Integration

The container works with VSCode Remote - Containers. Open a folder, then attach to the running distrobox container.

## Updating

```bash
# Update Devbox packages
devbox update

# Update base container
./bootstrap.sh —rebuild
```