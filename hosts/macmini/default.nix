{ config, pkgs, lib, ... }:

{
  # --- Nix Garbage Collection ---
  # Darwin uses interval, NixOS uses dates
  nix.gc.interval = { Weekday = 7; Hour = 3; Minute = 0; };  # Sunday 3 AM

  # Enable nix entirely disabled in active config for some reason?
  nix.enable = false;
  nix.gc.automatic = lib.mkForce false;

  # --- System Packages (macOS system-level) ---
  environment.systemPackages = with pkgs; [
    # GUI Apps from Nix Packages
    discord
    obsidian
    vscode
    thunderbird
    kitty
    zoom-us
    telegram-desktop
  ];

  # Ensure Homebrew is in PATH
  environment.systemPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];

  # Allow specific unfree packages
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
    "discord"
    "obsidian"
    "vscode"
    "zoom"
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

  # --- Home Manager ---
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";

  home-manager.users.zirondi = import ../../modules/shared/home.nix;
}
