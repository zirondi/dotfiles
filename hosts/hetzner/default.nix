{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    ./disk-config.nix  # disko handles hardware/filesystem config
    (modulesPath + "/profiles/qemu-guest.nix") # CRITICAL: Loads VirtIO drivers for cloud VMs
  ];

  # ── Boot ──
  boot.loader.grub = {
    enable = true;
    # disko will handle the device automatically via efiSupport or BIOS
    efiSupport = true;
    efiInstallAsRemovable = true;  # Safe for cloud VPS without NVRAM
  };

  # ── Networking ──
  networking.hostName = "hetzner";

  # IMPORTANT: Enable DHCP so you don't lose connectivity after install
  networking.useDHCP = lib.mkDefault true;

  # Headless VPS: Disable audio server
  services.pipewire.enable = lib.mkForce false;

  # ── SSH Access (CRITICAL — lock yourself out without this!) ──
  services.openssh = {
    enable = true;
    ports = [ 42721 ];
    settings = {
      PermitRootLogin = lib.mkForce "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  # Your SSH public key — without this you CANNOT access the server after install!
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDLUEF3D+nMwdt087Dks62tm7ftrAPv4/pMJi073oLxt"
  ];

  # ── Your regular user ──
  users.users.zirondi = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
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
  ];

  # ── Firewall ──
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 2222 ];  # SSH only + CTF SSH (2222); add more as needed
  };

  # ── Security overrides (BSI Abuse Report fix) ──
  # Disable mDNS and its open firewall port on this public VPS to prevent DDoS reflection attacks.
  services.avahi.enable = lib.mkForce false;
  networking.firewall.allowedUDPPorts = lib.mkForce [ ];

  system.stateVersion = "26.05";
}