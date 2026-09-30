{ config, pkgs, ... }:

{
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
    sops
    age
    ssh-to-age

    # Development & System
    coreutils
    curl
    gcc
    git
    lazygit
    lazydocker
    neovim
    nodejs
    pyenv
    python314
    wget
    
    # Prompt
    starship

    # Other Utilities
    cloudflared
    slides
    stow # Still keeping it installed just in case

    # Nix Tools
    nil
    nixfmt
  ];
}
