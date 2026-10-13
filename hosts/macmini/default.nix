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
}
