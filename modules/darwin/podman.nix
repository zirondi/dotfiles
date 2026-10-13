{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Containers of the mac-remote-access stack (Guacamole), by container_name.
  # Wetty is left out on purpose: the tailnet already has direct SSH.
  startRemoteAccess = pkgs.writeShellScript "start-mac-remote-access" ''
    podman=/opt/homebrew/bin/podman
    # The machine is started by the podman-machine agent; wait for its API
    for _ in $(/usr/bin/seq 1 60); do
      "$podman" info >/dev/null 2>&1 && break
      /bin/sleep 5
    done
    exec "$podman" start mac-ra-guacd mac-ra-guacamole
  '';
in
{
  # --- Podman Machine Auto-Start ---
  # Automatically starts the Podman Linux VM on macOS login.
  # This avoids having to manually type `podman machine start` after every reboot.

  launchd.user.agents.podman-machine = {
    serviceConfig = {
      Label = "com.zirondi.podman-machine";
      ProgramArguments = [
        "/opt/homebrew/bin/podman"
        "machine"
        "start"
      ];
      RunAtLoad = true;
      # Note: We intentionally do NOT set KeepAlive = true.
      # This is a one-shot command that exits after the machine is started.
      # Without this, launchd kills the VM (vfkit, gvproxy) as soon as the
      # command exits, because they share its process group.
      AbandonProcessGroup = true;
      StandardOutPath = "/tmp/podman-machine.log";
      StandardErrorPath = "/tmp/podman-machine.err.log";
    };
  };

  # --- Remote Access (Guacamole) Auto-Start ---
  # Containers do not come back by themselves when the machine boots.
  launchd.user.agents.mac-remote-access = {
    serviceConfig = {
      Label = "com.zirondi.mac-remote-access";
      ProgramArguments = [ "${startRemoteAccess}" ];
      RunAtLoad = true;
      StandardOutPath = "/tmp/mac-remote-access.log";
      StandardErrorPath = "/tmp/mac-remote-access.err.log";
    };
  };
}
