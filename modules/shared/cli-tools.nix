{ config, pkgs, ... }:

{
  # Base CLI toolset installed on EVERY host (workstations and servers).
  # Development toolchains live in cli-dev.nix (workstations only).
  environment.systemPackages = with pkgs; [
    # Modern Unix Tools
    bat
    btop
    eza
    fastfetch
    fd
    fzf
    htop
    lsof
    ripgrep
    tealdeer # tldr in rust (tlrc replacement)
    tree
    zoxide
    jq

    # Secrets
    sops
    age
    ssh-to-age

    # System
    coreutils
    curl
    git
    lazydocker
    neovim
    tmux # Detachable sessions for long rebuilds/deploys over SSH
    wget

    # Prompt
    starship
  ];
}
