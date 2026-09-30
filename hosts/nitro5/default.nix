# -------------------------------------------------------------------
# systems/nixos/nitro5/default.nix — Acer Nitro 5 Host Configuration
# -------------------------------------------------------------------
# TODO: Merge your existing NixOS configuration.nix for the Nitro 5
#       into this file. This is the host-specific module that gets
#       imported by flake.nix.
#
# The shared settings (CLI tools, common config, Home Manager) are
# imported separately in flake.nix, so this file should only contain
# things SPECIFIC to the Nitro 5 hardware and setup.
#
# NVIDIA config lives in nvidia.nix (also imported by flake.nix,
# but ONLY for the real hardware target, not the VM target).
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

  # --- Locale ---
  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";

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

  # --- Shell ---
  programs.zsh.enable = true;

  # --- User ---
  users.users.zirondi = {
    isNormalUser = true;
    description = "Zirondi";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "video" "docker" ];
    initialPassword = "change_me";

    openssh.authorizedKeys.keys = [
      # TODO: Add your SSH public key
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDLUEF3D+nMwdt087Dks62tm7ftrAPv4/pMJi073oLxt"
    ];
  };

  # --- SSH ---
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;  # TODO: Set to false after verifying SSH keys work
    settings.PermitRootLogin = "no";
    extraConfig = ''
      Match Address 10.0.0.0/24
        PermitRootLogin prohibit-password
    '';
  };

  # --- Tailscale ---
  services.tailscale.enable = true;
  # After first boot: sudo tailscale up

  # --- Nix Settings ---
  nix.settings = {
    auto-optimise-store = true;
    trusted-users = [ "root" "zirondi" ];
    experimental-features = [ "nix-command" "flakes" ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # --- Firewall ---
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
  };

  # --- Disable Bash History ---
  programs.bash.interactiveShellInit = ''
    unset HISTFILE
    export HISTSIZE=0
    export HISTFILESIZE=0
  '';

  system.stateVersion = "26.05";  # Do not change
}
