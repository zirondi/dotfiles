# HDMI fallback for monitors that send no EDID (a splitter, some adapters):
# the port then notices the cable but reports "disconnected", so X never sees
# the monitor. Starting hdmi-1080p.service loads a generic 1920x1080 60 Hz
# EDID on the port (driver debugfs) and forces it connected; stopping it puts
# normal detection back. "Force 1080p on HDMI" in Displays
# (configs/eww/scripts/displays.sh) toggles it, without a password.
#
# Not on all the time on purpose: a forced port is a phantom monitor when
# nothing is plugged, and a monitor with its own EDID would be treated as
# 1080p. Tested by hand on 2026-10-21 (TODO.md, "HDMI do nitro5").
{ config, pkgs, ... }:

let
  # The HDMI port of the AMD APU (the NVIDIA card has no outputs here)
  connector = "HDMI-A-1";
  edid = "${config.hardware.display.edid.packages}/lib/firmware/edid/generic1080.bin";
  # Every DRM card exposes its connectors as cardN-<connector>. debugfs lists
  # each card twice (PCI address and minor number), so take the first match
  find = ''
    status="" dbg=""
    for f in /sys/class/drm/card*-${connector}/status; do [ -e "$f" ] && status="$f" && break; done
    for d in /sys/kernel/debug/dri/*/${connector}; do [ -d "$d" ] && dbg="$d" && break; done
    if [ -z "$status" ] || [ -z "$dbg" ]; then
      echo "hdmi-1080p: ${connector} not found" >&2
      exit 1
    fi
  '';
in
{
  # CEA-861 1920x1080 at 60 Hz (148.5 MHz); the name is at most 12 characters
  hardware.display.edid.modelines.generic1080 =
    "148.50 1920 2008 2052 2200 1080 1084 1089 1125 +hsync +vsync";

  systemd.services.hdmi-1080p = {
    description = "Force a generic 1080p EDID on ${connector} (monitors without EDID)";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # printf, not echo: the driver rejects the trailing newline
      ExecStart = pkgs.writeShellScript "hdmi-1080p-on" ''
        ${find}
        cat ${edid} > "$dbg/edid_override"
        printf on > "$status"
      '';
      ExecStop = pkgs.writeShellScript "hdmi-1080p-off" ''
        ${find}
        printf reset > "$dbg/edid_override"
        printf detect > "$status"
        printf 1 > "$dbg/trigger_hotplug"
      '';
    };
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "hdmi-1080p.service" &&
          (action.lookup("verb") == "start" || action.lookup("verb") == "stop") &&
          subject.user == "zirondi") {
        return polkit.Result.YES;
      }
    });
  '';
}
