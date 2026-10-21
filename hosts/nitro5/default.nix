# -------------------------------------------------------------------
# hosts/nitro5/default.nix — Acer Nitro 5 Host Configuration
# -------------------------------------------------------------------
# Only things SPECIFIC to the Nitro 5 live here. Shared settings (Nix,
# locale, SSH, Tailscale, firewall, CLI tools, Home Manager) come from
# modules/ via flake.nix.
#
# NVIDIA config lives in nvidia.nix (imported by flake.nix ONLY for the
# real hardware target, not the VM target).
# -------------------------------------------------------------------
{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/keyd.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/i3.nix
    ../../modules/nixos/xremap.nix
    ./hdmi-1080p.nix # HDMI fallback for monitors without EDID (Displays menu)
  ];

  # --- Bootloader ---
  boot.loader.systemd-boot.enable = true;
  # Only the newest generations in the boot menu (older ones stay on disk
  # until a garbage collection); with 20+ entries the one to pick got lost
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- Networking ---
  networking.hostName = "nitro5";
  networking.networkmanager.enable = true;

  # TODO: Set a static IP if you want consistent LAN access
  # networking.interfaces.enp3s0.ipv4.addresses = [ {
  #   address = "10.0.0.80";
  #   prefixLength = 24;
  # } ];
  # networking.defaultGateway = "10.0.0.1";
  # networking.nameservers = [ "10.0.0.10" ];  # Pi-hole

  # --- Display Server & Window Manager ---
  # i3, xremap and keyd come from modules/nixos/ (imports above); keys in
  # configs/design/KEYMAP.md.

  # --- Console & Keyboard Layout (ABNT2) ---
  console.keyMap = "br-abnt2";
  # Load the ABNT2 keymap in the initrd too: the LUKS passphrase is typed there
  console.earlySetup = true;
  # Compressed swap in RAM (20 GB); no swap partition on the LUKS disk
  zramSwap.enable = true;
  services.xserver.xkb = {
    layout = "br";
    variant = "nodeadkeys";
  };

  # --- Keyboard (X11) Timings ---
  # Matches macOS KeyRepeat = 2 / InitialKeyRepeat = 15 for fast key repeat.
  # Essential for fluid Vim navigation (holding h/j/k/l).
  # autoRepeatDelay: ms before key starts repeating (lower = less wait)
  # autoRepeatInterval: ms between each repeat (lower = faster)
  services.xserver.autoRepeatDelay = 225;
  services.xserver.autoRepeatInterval = 33;

  # --- 1Password (CLI & GUI) ---
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "zirondi" ];
  };

  # --- Desktop applications ---
  # WM-independent GUI apps, fonts and the polkit agent come from
  # modules/nixos/desktop.nix; this host only adds its own picks
  environment.systemPackages = with pkgs; [
    ferdium # Cliente do ferdium-server (ferdium.rpi3)
  ];

  # Steam (also turns on 32-bit graphics libraries). Games run on the AMD iGPU
  # by default; put `nvidia-offload %command%` in a game's launch options to
  # use the NVIDIA card (PRIME offload, hosts/nitro5/nvidia.nix)
  programs.steam.enable = true;

  # Allow unfree packages for Nitro 5
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    let
      name = lib.getName pkg;
    in
    builtins.elem name [
      "1password"
      "1password-gui"
      "1password-cli"
      "google-chrome"
    ]
    || lib.hasPrefix "nvidia" name
    || lib.hasPrefix "steam" name;

  # --- User ---
  users.users.zirondi = {
    isNormalUser = true;
    description = "Zirondi";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDLUEF3D+nMwdt087Dks62tm7ftrAPv4/pMJi073oLxt"
    ];
  };

  # --- SSH ---
  # Root may log in with keys from the LAN and from the macmini over the
  # tailnet (100.125.15.85), so deploys work away from home and when the LAN
  # path to the Wi-Fi card fails. First boot: set the user's password with
  # `ssh root@<ip> passwd zirondi`.
  users.users.root.openssh.authorizedKeys.keys =
    config.users.users.zirondi.openssh.authorizedKeys.keys;
  services.openssh.extraConfig = ''
    Match Address 10.0.0.0/24,100.125.15.85
      PermitRootLogin prohibit-password
  '';

  # After first boot: sudo tailscale up

  system.stateVersion = "26.05"; # Do not change
}
