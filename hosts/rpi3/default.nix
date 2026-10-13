{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./services.nix
  ];

  # Bootloader setup for Raspberry Pi
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # The Pi 3B+ only has 1GB RAM. We need aggressive memory management.
  # 1. Traditional swap file
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 2048;
    }
  ];
  # 2. ZRAM (Compressed RAM Swap - much faster than SD card)
  zramSwap = {
    enable = true;
    priority = 100;
  };

  # Disable audio server to save RAM
  services.pipewire.enable = lib.mkForce false;
  # 3. Throttle Nix Builder to prevent it from eating all RAM
  nix.settings = {
    max-jobs = 1;
    cores = 1;
  };

  # Networking
  networking.hostName = "rpi3";
  networking.networkmanager.enable = true;

  # Static IP Configuration for Pi-hole DHCP Server
  networking.interfaces.enu1u1.ipv4.addresses = [
    {
      address = "10.0.0.10";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "10.0.0.1";
  networking.nameservers = [ "1.1.1.1" ]; # Allows Pi to resolve DNS if Pi-hole is restarting

  # Disable systemd-resolved so it doesn't conflict with Pi-hole on Port 53
  services.resolved.enable = false;

  # Root may log in with keys from the LAN only (for remote deployments)
  services.openssh.extraConfig = ''
    Match Address 10.0.0.0/24
      PermitRootLogin prohibit-password
  '';
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDLUEF3D+nMwdt087Dks62tm7ftrAPv4/pMJi073oLxt"
  ];

  # User Configuration
  users.users.zirondi = {
    isNormalUser = true;
    description = "Zirondi";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "podman"
    ];

    # ADD YOUR MAC'S PUBLIC SSH KEY HERE
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDLUEF3D+nMwdt087Dks62tm7ftrAPv4/pMJi073oLxt"
    ];
  };

  # Do not change this value, even if you upgrade NixOS later.
  system.stateVersion = "26.05";
}
