{ config, pkgs, ... }:

{
  # XERJ asks agents to send a field report (a GitHub PR) after each use; never send it
  environment.variables.XERJ_DISABLE_FEEDBACK = "true";

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
      # Two-way repo sync between workstations (scripts/sync-dotfiles.sh).
      # Both ends MUST run the same unison version: the protocol and archive
      # format change between releases. Keep it here, from the shared nixpkgs
      # pin, and never override or pin it on a single host.
      unison
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
      google-cloud-sdk # gcloud: Google Cloud projects behind the Drive OAuth clients
      oci-cli # Oracle Cloud API (scripts/oci-launch.sh)
      rclone # Google Drive remote for the backups
      restic # Inspect and restore the backups (modules/nixos/backup.nix)
      stow # Still keeping it installed just in case

      # Repo Tooling (see Justfile)
      just
      shellcheck
      trivy # `just scan`: CVEs in the images the stacks run

      # Nix Tools
      nil
      nixfmt

      # Reference coding: index and search open-source peers before writing code
      (callPackage ../../pkgs/xerj/package.nix { })

      # Password menu (scripts/rbw-menu): unofficial Bitwarden/Vaultwarden CLI
      rbw
      # Master-password prompt in a terminal; on the Mac, for unlocking over SSH
      pinentry-curses
    ]
    # Master-password prompt and clipboard backends used by rbw-menu
    ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pinentry_mac ]
    ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ xclip ];
}
