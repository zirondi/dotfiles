{
  config,
  pkgs,
  lib,
  ...
}:

{
  # --- Podman (OCI Container Runtime) ---
  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # Alias `docker` → `podman`
    defaultNetwork.settings.dns_enabled = true;
  };

  # --- Podman Compose ---
  environment.systemPackages = with pkgs; [
    podman-compose
  ];
}
