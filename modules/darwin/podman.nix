{ config, lib, ... }:

{
  # --- Podman Machine Auto-Start ---
  # Automatically starts the Podman Linux VM on macOS login.
  # This avoids having to manually type `podman machine start` after every reboot.

  launchd.user.agents.podman-machine = {
    serviceConfig = {
      Label = "com.zirondi.podman-machine";
      ProgramArguments = [ "/opt/homebrew/bin/podman" "machine" "start" ];
      RunAtLoad = true;
      # Note: We intentionally do NOT set KeepAlive = true. 
      # This is a one-shot command that exits after the machine is started.
      StandardOutPath = "/tmp/podman-machine.log";
      StandardErrorPath = "/tmp/podman-machine.err.log";
    };
  };
}
