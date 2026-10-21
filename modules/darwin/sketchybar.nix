{
  config,
  pkgs,
  lib,
  ...
}:

{
  # --- SketchyBar: status bar replacing the macOS menu bar ---
  # Twin of the eww bar on Linux (configs/eww); layout and look in configs/design/THEME.md. The config
  # lives in configs/sketchybar/, linked out of the store.
  #
  # Installed from Homebrew, not nixpkgs: aliases of native menu bar icons
  # need Screen Recording, and the app menus need Accessibility. macOS ties
  # both permissions to the binary's path, which changes on every Nix update
  # but only on a deliberate `brew upgrade` here.

  homebrew.taps = [
    {
      name = "FelixKratz/formulae";
      trusted = true;
    }
  ];
  homebrew.brews = [
    "FelixKratz/formulae/sketchybar"
    "media-control" # Now playing; works around the macOS 15.4+ MediaRemote lock
    "ical-buddy" # Events for the clock popup, from the macOS Calendar database
  ];

  environment.systemPackages = [
    (pkgs.callPackage ../../pkgs/sketchybar-menus/package.nix { }) # Menus of the focused app
    (pkgs.callPackage ../../pkgs/sketchybar-privacy/package.nix { }) # Mic/camera in use
    pkgs.blueutil # Bluetooth item
    pkgs.switchaudio-osx # Output device list in the volume popup
    pkgs.macmon # System power draw on the macmini (battery item), no sudo
  ];

  launchd.user.agents.sketchybar = {
    path = [ config.environment.systemPath ];
    serviceConfig = {
      # Wait for Home Manager to link the config on the first switch, then
      # become sketchybar itself (exec) so the permissions attach to it
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "until [ -x \"$HOME/.config/sketchybar/sketchybarrc\" ]; do sleep 1; done; exec /opt/homebrew/bin/sketchybar"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      ProcessType = "Interactive";
      # launchd gives no locale; without one bash cuts strings by byte and
      # truncating an accented title produces invalid UTF-8 that SketchyBar
      # drops. English UI, Brazilian dates, like the rest of the system.
      EnvironmentVariables = {
        LANG = "en_US.UTF-8";
        LC_TIME = "pt_BR.UTF-8";
      };
      StandardErrorPath = "/tmp/sketchybar.err.log";
    };
  };

  # The native menu bar slides in only when the pointer reaches the top edge
  system.defaults.NSGlobalDomain._HIHideMenuBar = true;

  home-manager.users.zirondi =
    { config, ... }:
    {
      home.file.".config/sketchybar".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/configs/sketchybar";
    };
}
