# Fish shell configuration for ophab container
# Source this from your ~/.config/fish/config.fish or place it in conf.d/

# Initialize starship prompt
if type -q starship
    starship init fish | source
end

# Initialize zoxide
if type -q zoxide
    zoxide init fish | source
end

# Initialize direnv
if type -q direnv
    direnv hook fish | source
end

# ----------------------------
# Aliases
# ----------------------------

# Kubernetes
alias k 'kubectl'
alias kx 'kubectx'
alias kn 'kubens'
alias kgp 'kubectl get pods'
alias kgs 'kubectl get svc'
alias kgd 'kubectl get deployments'
alias kga 'kubectl get all'
alias kaf 'kubectl apply -f'
alias kdel 'kubectl delete'
alias klog 'kubectl logs -f'
alias kexec 'kubectl exec -it'

# GitOps
alias argo 'argocd'
alias argoapp 'argocd app'
alias argosync 'argocd app sync'

# Infrastructure - OpenTofu
alias tf 'tofu'
alias tfi 'tofu init'
alias tfp 'tofu plan'
alias tfa 'tofu apply'

# Infrastructure - Terragrunt
alias tg 'terragrunt'
alias tga 'terragrunt run-all apply'
alias tgp 'terragrunt run-all plan'
alias tgi 'terragrunt run-all init'

# Cloud CLIs (az and gcloud are already the correct command names)

# Development
alias vim 'nvim'
alias v 'nvim'
alias lg 'lazygit'
alias cc 'claude'

# File navigation
alias ls 'eza'
alias ll 'eza -la --git'
alias la 'eza -a'
alias lt 'eza --tree --level=2'
alias cat 'bat --paging=never'

# Search
alias rg 'rg --smart-case'
alias f 'fd'

# Git
alias g 'git'
alias gs 'git status'
alias ga 'git add'
alias gc 'git commit'
alias gp 'git push'
alias gl 'git pull'
alias gco 'git checkout'
alias gb 'git branch'
alias gd 'git diff'
alias glog 'git log --oneline --graph'

# Docker/Podman
alias d 'docker'
alias dc 'docker compose'
alias p 'podman'
alias pc 'podman-compose'

# Databases
alias pg 'pgcli'

# Misc
alias http 'httpie'
alias h 'http'
alias please 'sudo'

# ----------------------------
# Completions
# ----------------------------

# kubectl completion
if type -q kubectl
    kubectl completion fish | source
end

# helm completion
if type -q helm
    helm completion fish | source
end

# argocd completion
if type -q argocd
    argocd completion fish | source
end

# opentofu completion
if type -q tofu
    tofu -install-autocomplete 2>/dev/null
end

# gh completion
if type -q gh
    gh completion -s fish | source
end

# Claude Code completion (only if logged in)
if type -q claude
    set -l claude_comp (claude completion fish 2>/dev/null)
    if test $status -eq 0; and not string match -q '*Invalid*' -- "$claude_comp"
        echo $claude_comp | source
    end
end

# terragrunt completion
if type -q terragrunt
    terragrunt --install-autocomplete 2>/dev/null
end

# azure-cli completion
if type -q az
    az completion --shell fish 2>/dev/null | source
end

# gcloud completion (handled by google-cloud-cli package)

# ----------------------------
# Environment
# ----------------------------

# Set default editor
set -gx EDITOR nvim
set -gx VISUAL nvim

# Use bat as man pager
set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"

# fzf configuration (Monokai Pro colors)
set -gx FZF_DEFAULT_OPTS "\
    --color=bg+:#403e41,bg:#2d2a2e,spinner:#ff6188,hl:#78dce8 \
    --color=fg:#fcfcfa,header:#78dce8,info:#a9dc76,pointer:#ff6188 \
    --color=marker:#ff6188,fg+:#fcfcfa,prompt:#a9dc76,hl+:#78dce8 \
    --border --margin=1 --padding=1"

# Use fd for fzf
set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'

# ----------------------------
# Functions
# ----------------------------

# Quick k8s pod exec
function ksh
    kubectl exec -it $argv[1] -- /bin/sh
end

# Quick k8s pod bash
function kbash
    kubectl exec -it $argv[1] -- /bin/bash
end

# Watch k8s resources
function kwatch
    watch -n 1 kubectl get $argv
end

# Port forward shortcut
function kpf
    kubectl port-forward $argv
end

# Get all resources in namespace
function kall
    kubectl get all -n $argv[1]
end

# Stern log following for multiple pods
function klogs
    stern $argv
end

# ArgoCD app list
function argolist
    argocd app list -o wide
end

# Quick dive into docker image
function dockerdive
    dive $argv[1]
end

# Decode k8s secret
function ksecret
    kubectl get secret $argv[1] -o jsonpath='{.data}' | jq -r 'to_entries[] | "\(.key): \(.value | @base64d)"'
end
