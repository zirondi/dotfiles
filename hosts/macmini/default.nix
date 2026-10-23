{
  config,
  pkgs,
  lib,
  ...
}:

{
  # --- Nix Daemon ---
  # This Mac runs Determinate Nix, which manages the daemon, nix.conf and
  # garbage collection itself. nix-darwin must not manage Nix alongside it.
  nix.enable = false;

  # --- System Packages (macOS system-level) ---
  environment.systemPackages = with pkgs; [
    # GUI Apps from Nix Packages
    (callPackage ../../pkgs/notproton/package.nix { }) # Proton for the Mac Steam client (CrossOver)
  ];

  # Ensure Homebrew is in PATH
  environment.systemPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];

  # Allow specific unfree packages
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (pkgs.lib.getName pkg) [
    ];

  # --- macOS System Preferences (via nix-darwin) ---
  # --- Power ---
  # Headless server duty: come back by itself after a power cut and never sleep.
  power.restartAfterPowerFailure = true;
  power.sleep.computer = "never";

  system.defaults = {
    # Dock
    dock.autohide = false;
    dock.mru-spaces = false;
    dock.show-recents = false;

    # Finder
    finder.AppleShowAllExtensions = true;
    finder._FXShowPosixPathInTitle = true;
    finder.FXEnableExtensionChangeWarning = false;

    # Keyboard
    NSGlobalDomain.ApplePressAndHoldEnabled = false;
    NSGlobalDomain.KeyRepeat = 2;
    NSGlobalDomain.InitialKeyRepeat = 15;

    # Trackpad
    trackpad.Clicking = true;

    # Screenshots
    screencapture.location = "~/Pictures/Screenshots";
  };

  # --- Security ---
  security.pam.services.sudo_local.touchIdAuth = true;

  # Used for backwards compatibility
  system.stateVersion = 5;
  system.primaryUser = "zirondi";

  users.users.zirondi = {
    name = "zirondi";
    home = "/Users/zirondi";
  };

  # --- Backup and tunnel (modules/darwin/backup.nix, cloudflared.nix) ---
  # Both stay off until ./secrets.sops.yaml exists with restic_password,
  # rclone_conf and cloudflared_token (ORDEM.md, sprint): sops-nix checks
  # every declared secret at build time.
  backup = {
    enable = false;
    name = "macmini";
    paths = map (p: "${config.users.users.zirondi.home}/${p}") [
      ".config/sops"
      ".ssh"
      ".oci"
      ".config/containers"
      ".claude"
      ".claude.json"
      ".codex"
      ".gemini"
      ".config/opencode"
      ".sparrow"
      "UNESP"
    ];
    exclude = [
      "**/node_modules"
      "**/.cache"
    ];
  };
  services.cloudflaredTunnel.enable = false;

  sops = lib.mkIf (config.backup.enable || config.services.cloudflaredTunnel.enable) {
    defaultSopsFile = ./secrets.sops.yaml;
    # The admin age key; it also decrypts every other repository's secrets
    age.keyFile = "${config.users.users.zirondi.home}/.config/sops/age/keys.txt";
  };
}
