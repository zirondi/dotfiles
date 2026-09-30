{ config, pkgs, lib, ... }:

{
  # --- Nix Settings ---
  nix.settings = {
    trusted-users = [ "root" "zirondi" ];
    experimental-features = [ "nix-command" "flakes" ];
    download-buffer-size = 256 * 1024 * 1024;
  };

  # --- Garbage Collection ---
  nix.gc = {
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
