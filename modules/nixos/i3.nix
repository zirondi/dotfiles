{
  config,
  pkgs,
  lib,
  ...
}:

let
  # picom v13 config (see services.picom below)
  picomConf = pkgs.writeText "picom.conf" ''
    # dual_kawase blur needs an OpenGL backend (the AMD iGPU drives the panel)
    backend = "glx";
    vsync = true;

    # `shadow`: black at 45%, blur 24 px, offset 0 x / 8 y. picom draws the
    # shadow image at the offset, so -radius centers it and -radius + 8 drops it.
    shadow-radius = 24;
    shadow-opacity = 0.45;
    shadow-offset-x = -24;
    shadow-offset-y = -16;

    # `blur` (radius 30 on macOS); strength 0-20, tuned by eye on nitro5
    blur: { method = "dual_kawase"; strength = 8; };

    rules = (
      # Managed windows (i3 frames, border included): `radius-outer` and
      # `shadow`. Override-redirect windows (app menus, tooltips) are left as
      # their apps draw them.
      { match = "!override_redirect"; corner-radius = 10; shadow = true; },
      # Translucent Kitty (background_opacity 0.65); rbw-menu is a Kitty too
      { match = "class_g = 'kitty' || class_g = 'rbw-menu'"; blur-background = true; },
      # Surfaces that draw their own shape (eww bar, dock, popups, tooltips;
      # rofi; dunst): `blur` and `shadow` come from picom, since none draws a
      # shadow of its own, clipped at the same 10 px they are drawn with, so
      # nothing is rounded a second time.
      { match = "class_g = 'Eww' || class_g = 'Rofi' || class_g = 'Dunst'";
        corner-radius = 10; shadow = true; blur-background = true; },
      # The lock screen is left alone
      { match = "class_g = 'i3lock'"; corner-radius = 0; shadow = false; blur-background = false; },
      # Fullscreen: no rounding, no shadow
      { match = "fullscreen"; corner-radius = 0; shadow = false; }
    );
  '';
in
{
  # --- i3 (X11) — Linux twin of AeroSpace on macOS ---
  # Keys: configs/design/KEYMAP.md. The config itself is configs/i3/config, linked out
  # of the store so edits apply with $mod+Shift+C (no rebuild).

  services.xserver.enable = true;
  # ly: TUI display manager on the console (keymap from console.keyMap)
  services.displayManager.ly.enable = true;
  services.xserver.windowManager.i3 = {
    enable = true;
    extraPackages = with pkgs; [
      feh # Wallpaper (configs/design/THEME.md)
      eww # Status bar, dock and popups (configs/eww; twin of SketchyBar)
      dunst # Notifications; pausing it is the Focus toggle, configs/dunst
      libnotify # notify-send, so scripts and tests can post to dunst
      playerctl # Now playing in the eww bar (MPRIS)
      arandr # Displays… in the system menu
      maim # Screenshots (Cmd+Shift+3/4 chords, configs/design/KEYMAP.md)
      xclip # Screenshots to the clipboard
      flameshot # Capture tool (Cmd+Shift+5)
      xss-lock # Locks on suspend and `loginctl lock-session`
      dex # Runs XDG autostart entries
      brightnessctl # Brightness keys
      (rofi.override { plugins = [ rofi-emoji ]; }) # Launcher, window switcher, emoji picker
    ];
  };

  # Compositor (picom v13): rounded corners, the shadow and the blur of
  # configs/design/ (THEME.md Depth, WINDOWS.md), no tearing.
  services.picom.enable = true;
  # Per-window behavior uses v13 `rules`, a libconfig list of groups. The
  # module's `settings` writes every Nix list as an array (`[ ]`), which
  # libconfig only allows for scalars, and always adds the old *-exclude /
  # opacity-rule / wintypes options that `rules` replaces; so picom gets this
  # file instead of the module's.
  systemd.user.services.picom.serviceConfig.ExecStart =
    lib.mkForce "${lib.getExe config.services.picom.package} --config ${picomConf}";

  # Bluetooth item in the eww bar (blueman-manager on right click)
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Screen locker with the theme (configs/i3/lock.sh; $mod+Q, and before
  # suspend via xss-lock). The module sets up the PAM service the locker
  # needs to check the password; without it no password ever unlocks.
  programs.i3lock = {
    enable = true;
    package = pkgs.i3lock-color;
  };

  # brightnessctl writes to /sys/class/backlight
  users.users.zirondi.extraGroups = [ "video" ];

  home-manager.users.zirondi =
    { config, ... }:
    {
      # XDG autostart entries dex must skip: picom would start a second,
      # config-less copy next to services.picom; nm-applet would duplicate the
      # bar's network item
      xdg.configFile = lib.genAttrs [ "picom" "nm-applet" ] (name: {
        target = "autostart/${name}.desktop";
        text = ''
          [Desktop Entry]
          Type=Application
          Name=${name}
          Hidden=true
        '';
      });

      # blueman-applet still starts: it is BlueZ's pairing agent (the "confirm
      # this code" step, and it stores the link key). Without it pairing a
      # phone ends in br-connection-key-missing. Its requests come as dialogs
      # with Confirm / Deny buttons (notification-daemon = false): as dunst
      # bubbles the buttons were unreachable and the pairing timed out. Off:
      # the tray icon (the bar has its own Bluetooth item) and the
      # connected/disconnected notices, which would now be dialogs too.
      dconf.settings."org/blueman/general" = {
        plugin-list = [
          "!StatusIcon"
          "!ConnectionNotifier"
        ];
        notification-daemon = false;
      };

      home.file.".config/i3/config".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/configs/i3/config";
      home.file.".config/dunst/dunstrc".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/configs/dunst/dunstrc";
      home.file.".config/eww".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/configs/eww";
      home.file.".config/rofi".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/configs/rofi";
    };
}
