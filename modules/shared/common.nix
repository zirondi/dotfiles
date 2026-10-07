{ config, pkgs, lib, ... }:

{
  # --- Nix Settings ---
  nix.settings = {
    trusted-users = [ "root" "zirondi" ];
    experimental-features = [ "nix-command" "flakes" ];
    download-buffer-size = 256 * 1024 * 1024;
  };

  # --- Garbage Collection ---
  # Skipped where nix-darwin does not manage the daemon (nix.enable = false)
  nix.gc = lib.mkIf config.nix.enable {
    automatic = true;
    options = "--delete-older-than 30d";
  };

  # --- Shell ---
  programs.zsh.enable = true;

  # --- Disable Bash History (security preference) ---
  programs.bash.interactiveShellInit = ''
    unset HISTFILE
    export HISTSIZE=0
    export HISTFILESIZE=0
  '';
}
