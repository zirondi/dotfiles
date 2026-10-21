{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Design tokens (configs/design/THEME.md) from their one macOS definition
  # place, configs/sketchybar/colors.sh: every `export NAME=<0xAARRGGBB or
  # integer>` line. Read at build time, so a change there reaches JankyBorders
  # with `just switch`.
  tokens = lib.listToAttrs (
    lib.concatMap (
      line:
      let
        m = builtins.match "export ([A-Z0-9_]+)=(0x[0-9a-fA-F]{8}|[0-9]+)([ #].*)?" line;
      in
      lib.optional (m != null) (lib.nameValuePair (builtins.elemAt m 0) (builtins.elemAt m 1))
    ) (lib.splitString "\n" (builtins.readFile ../../configs/sketchybar/colors.sh))
  );
in
{
  # --- macOS desktop (twin of modules/nixos/desktop.nix) ---
  # Dock on the right, like the eww dock on Linux (configs/eww)
  system.defaults.dock.orientation = "right";

  # Cmd+Ctrl+drag moves a window from anywhere on it, like $mod+drag on i3
  # (configs/design/WINDOWS.md). Apps pick it up when they next start.
  system.defaults.NSGlobalDomain.NSWindowShouldDragOnGesture = true;

  # --- Window borders: JankyBorders (configs/design/WINDOWS.md) ---
  # AeroSpace draws no borders; JankyBorders gives macOS the same focused and
  # unfocused border as i3 (configs/design/decisions/0002-jankyborders-on-macos.md).
  # Corners follow each window's own radius (style=round). No urgent color:
  # macOS has no urgency data (configs/design/CAPABILITIES.md).
  services.jankyborders = {
    enable = true;
    width = 0.0 + lib.toInt tokens.BORDER_WINDOW;
    active_color = tokens.BORDER_ACTIVE;
    inactive_color = tokens.BORDER_INACTIVE;
    style = "round";
  };

  # Calendar sync (modules/shared/calendar.nix) every 15 minutes, like the
  # systemd timer on Linux
  launchd.user.agents.vdirsyncer = {
    path = [ config.environment.systemPath ];
    serviceConfig = {
      # Only once the calendars were set up (`vdirsyncer discover`), like the
      # ConditionPathExists of the systemd unit on Linux
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "test -d \"$HOME/.local/share/vdirsyncer/status\" || exit 0; exec ${pkgs.vdirsyncer}/bin/vdirsyncer sync"
      ];
      StartInterval = 900;
      RunAtLoad = true;
      StandardErrorPath = "/tmp/vdirsyncer.err.log";
    };
  };
}
