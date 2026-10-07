# --- Common Aliases ---
alias n="nvim"
alias c="code-insiders"
alias zshconfig="n ~/.zshrc"
alias zshreload="source ~/.zshrc"

alias dotfiles="cd ~/dotfiles"
alias repos="cd ~/repos"

alias d="docker"
alias dc="docker compose"
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dcl="docker compose logs -f"
alias dps="docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
alias prune="podman stop -a && podman rm -a"

alias ls='eza --icons=always'
alias lc='eza -lA --icons=always --git'
alias cat="bat"
alias cd="z" # zoxide: behaves like cd for real paths, jumps by frecency otherwise

# --- Smart Remote Function ---
# Replaces 'alias remote="kitten ssh"'.
# Probes the remote host to determine if it is Linux and missing .zshrc before copying dotfiles.
function remote() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: remote <host> [args...]"
        return 1
    fi
    local host="${@: -1}" # last argument is typically the host
    
    # 1. Probe the remote OS and existence of ~/.zshrc
    # Using ConnectTimeout to fail fast if unreachable. BatchMode prevents password prompts during the probe.
    local probe_output=$(ssh -o ConnectTimeout=5 -o BatchMode=yes -o PasswordAuthentication=no "$host" "uname -s && [ -f ~/.zshrc ] && echo 'exists' || echo 'missing'" 2>/dev/null)
    
    local os=$(echo "$probe_output" | sed -n '1p')
    local zshrc_status=$(echo "$probe_output" | sed -n '2p')
    
    # 2. Decide SSH config
    if [[ -z "$os" ]]; then
        # Probe failed (maybe requires password or connection timed out). Fallback to safe default.
        kitten ssh "$@"
    elif [[ "$os" == "Darwin" ]]; then
        # Darwin hosts are assumed to have dotfiles configured natively.
        kitten ssh "$@"
    else
        # Linux hosts
        if [[ "$zshrc_status" == "exists" ]]; then
            echo -e "\033[1;33mWarning: Remote host ($host) already has a ~/.zshrc.\033[0m"
            echo -e "\033[1;33mPlease ensure the dotfiles git repo is updated on the server to avoid conflicts.\033[0m"
            echo -e "\033[1;33mSkipping automatic kitty config copy.\033[0m"
            kitten ssh "$@"
        else
            echo "Target is Linux and missing ~/.zshrc. Copying dotfiles via Kitty..."
            # Launch kitten ssh with the copy-enabled configuration
            kitten ssh --kitten include=ssh_copy.conf "$@"
        fi
    fi
}

# Smart man: Try tldr first, fallback to real man page
man() {
    if command -v tldr >/dev/null; then
        tldr "$@" || command man "$@"
    else
        command man "$@"
    fi
}

# Docker hints
export DOCKER_CLI_HINTS=false

# AI Agent Skills (skills.sh)
alias sync-skills="$HOME/dotfiles/scripts/sync-skills.sh"

