{
  config,
  pkgs,
  lib,
  ...
}:

{
  # --- Linux desktop, independent of the window manager ---
  # GUI apps, fonts and session helpers any Linux workstation needs, whatever
  # runs the windows (i3 today, see modules/nixos/i3.nix). The macOS side gets
  # the same apps from Homebrew (modules/darwin/homebrew.nix).

  environment.systemPackages = with pkgs; [
    kitty # Terminal; config in configs/kitty, linked by modules/shared/home.nix
    networkmanagerapplet # nm-applet (tray) and nm-connection-editor
    pavucontrol # Sound settings and per-app volume
    pulseaudio # pactl (PipeWire's pulse server has no client tools of its own)
    nemo # File manager
    polkit_gnome # Graphical authentication agent (below)
    google-chrome # Streaming (DRM) and Google sign-in; unfree, allowed in hosts/nitro5
    (callPackage ../../pkgs/helium/package.nix { }) # Browser; AppImage wrapped in pkgs/helium
  ];

  # Kitty's font (configs/kitty/kitty.conf); macOS gets it from Homebrew
  fonts.packages = [ pkgs.cascadia-code ];

  # GTK and many apps keep their settings in dconf; without it they reset
  programs.dconf.enable = true;

  # --- Look: dark everywhere, same cursor as macOS (configs/design/THEME.md) ---
  home-manager.users.zirondi =
    { pkgs, ... }:
    {
      gtk = {
        enable = true;
        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };
        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
        gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
        gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
        # GTK4/libadwaita apps follow color-scheme (below), not a theme name
        gtk4.theme = null;
      };
      # libadwaita / GTK4 apps and portals read this instead of the theme name
      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

      # Qt and KDE apps follow the GTK theme
      qt = {
        enable = true;
        platformTheme.name = "gtk3";
        style.name = "adwaita-dark";
      };

      # Bibata Modern Classic, also used on macOS (Mousecape)
      home.pointerCursor = {
        enable = true;
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        size = 24;
        x11.enable = true;
        gtk.enable = true;
      };
    };

  # --- Calendar sync (modules/shared/calendar.nix) every 15 minutes ---
  systemd.user.services.vdirsyncer = {
    description = "vdirsyncer: sync Nextcloud calendars (configs/vdirsyncer)";
    # Only once the calendars were set up (`vdirsyncer discover`), so an
    # unconfigured machine does not fail every 15 minutes
    unitConfig.ConditionPathExists = "%h/.local/share/vdirsyncer/status";
    path = [ pkgs.rbw ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.vdirsyncer}/bin/vdirsyncer sync";
    };
  };
  systemd.user.timers.vdirsyncer = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "15min";
    };
  };

  # --- Keep awake with the lid closed (configs/eww/scripts/lid.sh) ---
  # A root service holds logind's handle-lid-switch inhibitor, so closing the
  # lid neither suspends nor drops SSH. The user may start/stop this one unit
  # without a password (polkit rule below), from the eww menu or over SSH. A
  # process started by eww itself does not survive (eww kills its commands).
  systemd.services.lid-awake = {
    description = "Keep running with the lid closed (reachable over SSH)";
    serviceConfig.ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=handle-lid-switch --who=lid-awake --why=\"Lid closed, kept reachable over SSH\" --mode=block ${pkgs.coreutils}/bin/sleep infinity";
  };
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "lid-awake.service" &&
          (action.lookup("verb") == "start" || action.lookup("verb") == "stop") &&
          subject.user == "zirondi") {
        return polkit.Result.YES;
      }
    });
  '';

  # --- Polkit authentication agent ---
  # Without a desktop environment nothing answers polkit prompts (mounting a
  # disk, NetworkManager, systemctl from the system menu)
  security.polkit.enable = true;
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
}
