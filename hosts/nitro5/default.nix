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
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/keyd.nix
  ];

  # --- Bootloader ---
  boot.loader.systemd-boot.enable = true;
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

  # --- Display Server & Window Manager (i3) ---
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.windowManager.i3 = {
    enable = true;
    extraPackages = with pkgs; [
      dmenu       # Application launcher (Super+d)
      i3status    # Status bar
      i3lock      # Screen locker
    ];
  };

  # --- Console & Keyboard Layout (ABNT2) ---
  console.keyMap = "br-abnt2";
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

  # --- Desktop Applications & i3 Helpers ---
  environment.systemPackages = with pkgs; [
    networkmanagerapplet  # nm-applet para bandeja do i3
    pavucontrol           # Controle de volume GUI
    nemo                  # Gerenciador de arquivos gráfico
    polkit_gnome          # Agente gráfico de autenticação para i3
  ];

  # --- Polkit Authentication Agent (GUI auth prompt for i3) ---
  security.polkit.enable = true;
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # Allow unfree packages for Nitro 5
  nixpkgs.config.allowUnfreePredicate = pkg:
    let name = lib.getName pkg; in
    builtins.elem name [
      "1password"
      "1password-gui"
      "1password-cli"
    ] || lib.hasPrefix "nvidia" name;

  # --- User ---
  users.users.zirondi = {
    isNormalUser = true;
    description = "Zirondi";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "video" ];
    initialPassword = "change_me";

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDLUEF3D+nMwdt087Dks62tm7ftrAPv4/pMJi073oLxt"
    ];
  };

  # --- SSH ---
  # Root may log in with keys from the LAN only
  services.openssh.extraConfig = ''
    Match Address 10.0.0.0/24
      PermitRootLogin prohibit-password
  '';

  # After first boot: sudo tailscale up

  system.stateVersion = "26.05";  # Do not change
}
