# --- macOS Specific Aliases ---
alias update-mac="nix flake update --flake ~/dotfiles && sudo darwin-rebuild switch --flake ~/dotfiles#macmini"
alias update-brew="brew update && brew upgrade" # darwin-rebuild no longer upgrades Homebrew

# --- Podman / Docker Compat ---
alias docker="podman"
alias docker-compose="podman-compose"
