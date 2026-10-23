{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    ./disk-config.nix # disko handles hardware/filesystem config
    ./backup.nix # daily Restic backup to Google Drive
    (modulesPath + "/profiles/qemu-guest.nix") # CRITICAL: Loads VirtIO drivers for cloud VMs
  ];

  # ── Boot ──
  boot.loader.grub = {
    enable = true;
    # disko will handle the device automatically via efiSupport or BIOS
    efiSupport = true;
    efiInstallAsRemovable = true; # Safe for cloud VPS without NVRAM
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_unprivileged_port_start" = 25;
  };

  # ── Swap ──
  # 4 GB of RAM shared by n8n, Stalwart, Nextcloud and the rest: a swap file
  # turns a memory spike into slowness instead of the OOM killer.
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 2048;
    }
  ];

  # ── Networking ──
  networking.hostName = "hetzner";

  # IMPORTANT: Enable DHCP so you don't lose connectivity after install
  networking.useDHCP = lib.mkDefault true;

  # IPv6 configuration for Hetzner Cloud (Dual-Stack)
  networking.interfaces.enp1s0.ipv6.addresses = [
    {
      address = "2a01:4f9:c013:8f37::1";
      prefixLength = 64;
    }
  ];
  networking.defaultGateway6 = {
    address = "fe80::1";
    interface = "enp1s0";
  };

  # Headless VPS: Disable audio server
  services.pipewire.enable = lib.mkForce false;

  # ── SSH Access (CRITICAL — lock yourself out without this!) ──
  services.openssh = {
    enable = true;
    ports = [ 42721 ];
  };

  # Root SSH login is disabled (modules/nixos/common.nix); deploys go through
  # `zirondi` + passwordless sudo.

  # ── Your regular user ──
  users.users.zirondi = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDLUEF3D+nMwdt087Dks62tm7ftrAPv4/pMJi073oLxt"
    ];
  };

  # Allow wheel group to sudo without password (since it's an SSH-key-only VPS)
  security.sudo.wheelNeedsPassword = false;

  # Keep user services (rootless Podman) running after SSH logout
  users.users.zirondi.linger = true;

  # ── Basic packages ──
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    tmux
    openssl
    rclone
  ];

  # ── Firewall ──
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      2222 # CTF SSH (admin SSH port is opened by services.openssh)
      25 # SMTP (Inbound/Outbound direto para outros servidores de e-mail)
      465 # SMTPS (envio autenticado dos clientes, TLS implícito)
      993 # IMAPS (Acesso seguro à caixa de entrada)
      4190 # ManageSieve (Filtros de e-mail)
    ];
  };

  # ── Secrets (sops-nix) ──
  # Decrypted at activation with the host SSH key into /run/secrets.
  # Edit with `sops hosts/hetzner/secrets.sops.yaml`.
  sops.defaultSopsFile = ./secrets.sops.yaml;

  # ── Security overrides (BSI Abuse Report fix) ──
  # Disable mDNS and its open firewall port on this public VPS to prevent DDoS reflection attacks.
  services.avahi.enable = lib.mkForce false;
  networking.firewall.allowedUDPPorts = lib.mkForce [ ];

  system.stateVersion = "26.05";
}
