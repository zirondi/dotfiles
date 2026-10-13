{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    "${builtins.fetchTarball "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz"}/raspberry-pi/3"
  ];

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Essential Memory Management for Pi 3B+
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 2048;
    }
  ];

  zramSwap = {
    enable = true;
    priority = 100;
  };

  # Prevent Nix from OOMing during local bootstrap
  nix.settings = {
    max-jobs = 1;
    cores = 1;
    trusted-users = [
      "root"
      "zirondi"
    ];
  };

  networking.hostName = "rpi3";
  networking.networkmanager.enable = true;

  # Jump to static IP immediately upon bootstrap
  networking.interfaces.enu1u1.ipv4.addresses = [
    {
      address = "10.0.0.10";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "10.0.0.1";
  networking.nameservers = [ "1.1.1.1" ];

  # Disable Bash History globally
  programs.bash.interactiveShellInit = ''
    unset HISTFILE
    export HISTSIZE=0
    export HISTFILESIZE=0
  '';

  # Root Configuration (For remote deployments)
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDLUEF3D+nMwdt087Dks62tm7ftrAPv4/pMJi073oLxt"
  ];

  # User Configuration
  users.users.zirondi = {
    isNormalUser = true;
    description = "Zirondi";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];

    # Temporary password for first SSH login
    initialPassword = "change_me";

    # ADD YOUR MAC'S PUBLIC SSH KEY HERE
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDLUEF3D+nMwdt087Dks62tm7ftrAPv4/pMJi073oLxt"
    ];
  };

  # Enable SSH permanently
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;

    # Deny root login globally by default
    settings.PermitRootLogin = "no";

    # Only allow root login (via SSH keys) from your local network
    extraConfig = ''
      Match Address 10.0.0.0/24
        PermitRootLogin prohibit-password
    '';
  };

  system.stateVersion = "26.05";
}
