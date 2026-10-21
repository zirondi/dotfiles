{
  config,
  pkgs,
  lib,
  ...
}:

{
  # --- Calendars from Nextcloud on every workstation (macmini, nitro5) ---
  # vdirsyncer keeps a local copy over CalDAV, khal reads it for the bar
  # calendars (SketchyBar and eww). Configs in configs/vdirsyncer and
  # configs/khal; the periodic sync is OS-specific (modules/darwin/desktop.nix,
  # modules/nixos/desktop.nix). Credentials: the vault, through rbw.
  environment.systemPackages = with pkgs; [
    vdirsyncer
    khal
  ];

  home-manager.users.zirondi =
    { config, ... }:
    {
      home.file.".config/vdirsyncer/config".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/configs/vdirsyncer/config";
      home.file.".config/khal/config".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/configs/khal/config";
    };
}
