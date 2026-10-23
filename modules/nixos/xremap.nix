{
  config,
  pkgs,
  lib,
  ...
}:

{
  # --- xremap: Cmd-style app shortcuts on Linux ---
  # Translates Super+key into Ctrl+key per application (terminals excluded), so
  # Super behaves like macOS Cmd. Mapping: configs/xremap/config.yml, documented
  # in configs/design/KEYMAP.md. Plan B if this breaks: Toshy (see TODO.md).
  #
  # Event chain: keyboard → keyd (Caps Lock Hyper key) → "keyd virtual keyboard"
  # → xremap → X11. xremap only grabs keyd's virtual device; the physical
  # keyboards are already grabbed by keyd.

  hardware.uinput.enable = true;
  users.users.zirondi.extraGroups = [
    "input"
    "uinput"
  ];

  home-manager.users.zirondi =
    { config, ... }:
    {
      home.file.".config/xremap/config.yml".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/configs/xremap/config.yml";
    };

  # Runs in the X session (needs DISPLAY to know the focused window's class)
  systemd.user.services.xremap = {
    description = "xremap (Cmd-style shortcuts, configs/xremap/config.yml)";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = ''${lib.getExe pkgs.xremap.x11} --watch=device,config --device "keyd virtual keyboard" %h/.config/xremap/config.yml'';
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  # --watch=config follows the original inode, so a config replaced by rename
  # (Unison, rsync without --inplace, editors that save atomically) goes
  # unnoticed. systemd watches the path itself, renames included, and
  # restarts xremap on any change.
  systemd.user.paths.xremap-config = {
    wantedBy = [ "graphical-session.target" ];
    pathConfig.PathChanged = "%h/dotfiles/configs/xremap/config.yml";
  };
  systemd.user.services.xremap-config = {
    description = "Restart xremap after configs/xremap/config.yml changes";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl --user try-restart xremap.service";
    };
  };
}
