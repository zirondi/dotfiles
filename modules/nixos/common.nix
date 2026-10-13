{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./podman.nix
  ];

  # NixOS-specific GC dates (Darwin uses interval array)
  nix.gc.dates = "weekly";

  # Auto-optimise store is a daemon config in NixOS
  nix.settings.auto-optimise-store = true;

  # --- Locale ---
  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  # --- Audio (PipeWire) ---
  security.rtkit.enable = lib.mkDefault true;
  services.pipewire = {
    enable = lib.mkDefault true;
    alsa.enable = lib.mkDefault true;
    alsa.support32Bit = lib.mkDefault true;
    pulse.enable = lib.mkDefault true;
  };

  # --- Hardware & System Diagnostics ---
  environment.systemPackages = with pkgs; [
    cryptsetup
    parted
    pciutils
  ];

  # NixOS doesn't create /etc/timezone by default, but our docker-compose files mount it.
  environment.etc."timezone".text = "${config.time.timeZone}\n";

  # --- SSH ---
  # Key-only everywhere. LAN hosts that allow root from 10.0.0.0/24 add
  # their own Match block; public hosts must not.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # --- Firewall ---
  networking.firewall.enable = true;

  # --- Tailscale ---
  services.tailscale.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # --- mDNS (Avahi) ---
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };
  networking.firewall.allowedUDPPorts = [ 5353 ]; # mDNS
}
