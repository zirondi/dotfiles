# --- macOS Specific Aliases ---
alias update-mac="nix flake update --flake ~/dotfiles && sudo darwin-rebuild switch --flake ~/dotfiles#macmini"

# --- Podman / Docker Compat ---
alias docker="podman"
alias docker-compose="podman-compose"
