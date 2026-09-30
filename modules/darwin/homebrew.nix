{ config, pkgs, ... }:

{
  # --- Homebrew (managed by nix-darwin) ---
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "none";
    };

    # Organize Casks into a dedicated directory
    caskArgs.appdir = "~/Applications/Brew Apps";

    taps = [
      {
        name = "anomalyco/tap";
        trusted = true;
      }
      {
        name = "ARAS-Workspace/tap";
        trusted = true;
      }
  
    ];
    brews = [
      "aria2"
      "autoconf"
      "automake"
      "gnutls"
      "libgcrypt"
      "libtool"
      "ollama"
      "opencode-v2"
      "pkg-config"
      "podman"
      "podman-compose"
      "sevenzip"
    ];
    casks = [
      "1password"
      "android-studio"
      "appcleaner"
      "balenaetcher"
      "bettermouse"
      "bitwarden"
      "calibre"
      "clash-verge-rev"
      "clash-party"
      "cloudmounter"
      "crossover"
      "disk-drill"
      "element"
      "figma"
      "font-cascadia-code"
      "font-meslo-lg-nerd-font"
      "fuse-t"
      "handbrake-app"
      "heroic"
      "homebrew/cask/transmission"
      "karabiner-elements"
      "keka"
      "keycastr"
      "legcord"
      "lulu"
      "mounty"
      "obs"
      "pear-desktop"
      "perplexity"
      "phantom-wg-mac"
      "podman-desktop"
      "raspberry-pi-imager"
      "rustdesk"
      "steam"
      "stremio"
      "tailscale-app"
      "zen"
    ];
  };
}
