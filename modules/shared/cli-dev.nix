{ config, pkgs, ... }:

{
  # Development toolchains for workstations (macmini, nitro5).
  # Kept off the servers: the rpi3 has 1GB of RAM and the VPS only runs containers.
  environment.systemPackages =
    with pkgs;
    [
      # Languages & Build
      gcc
      nodejs
      pyenv
      python314

      # Git & Presentations
      gh
      git-filter-repo
      lazygit
      presenterm
      qrencode # QR codes in the terminal (lesson slides)
      slides

      # Documents (Markdown -> HTML -> PDF)
      pandoc
      python3Packages.weasyprint

      # Other Utilities
      cloudflared
      stow # Still keeping it installed just in case

      # Repo Tooling (see Justfile)
      just
      shellcheck

      # Nix Tools
      nil
      nixfmt

      # Password menu (scripts/rbw-menu): unofficial Bitwarden/Vaultwarden CLI
      rbw
    ]
    # Master-password prompt and clipboard backends used by rbw-menu
    ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pinentry_mac ]
    ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      pinentry-curses
      xclip
    ];
}
