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
    caskArgs.appdir = "/Applications/Brew Apps";

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
      "fileicon"
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
      # --- System & Privileged Apps ---
      # MUST stay in /Applications due to macOS syspolicyd / Network Extensions restrictions
      { name = "1password"; args = { appdir = "/Applications"; }; }
      { name = "karabiner-elements"; args = { appdir = "/Applications"; }; }
      { name = "protonvpn"; args = { appdir = "/Applications"; }; }
      { name = "tailscale-app"; args = { appdir = "/Applications"; }; }

      # --- Dev ---
      { name = "android-studio"; args = { appdir = "/Applications/Brew Apps/Dev"; }; }
      { name = "claude"; args = { appdir =  "/Applications/Brew Apps/Dev/"; }; }
      { name = "claude-code"; args = { appdir = "/Applications/Brew Apps/Dev/"; }; }
      { name = "figma"; args = { appdir = "/Applications/Brew Apps/Dev"; }; }
      { name = "kitty"; args = { appdir = "/Applications/Brew Apps/Dev"; }; }
      { name = "podman-desktop"; args = { appdir = "/Applications/Brew Apps/Dev"; }; }
      { name = "visual-studio-code"; args = { appdir = "/Applications/Brew Apps/Dev"; }; }

      # --- Ferramentas ---
      { name = "appcleaner"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }
      { name = "balenaetcher"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }
      { name = "bettermouse"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }
      { name = "bitwarden"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }
      { name = "calibre"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }
      { name = "clash-party"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }
      { name = "cloudmounter"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }
      { name = "disk-drill"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }
      { name = "fuse-t"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }
      { name = "keka"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }
      { name = "keycastr"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }
      { name = "logitech-g-hub"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }
      { name = "obsidian"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }
      { name = "openmtp"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }
      { name = "pear-desktop"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }
      { name = "perplexity"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }
      { name = "raspberry-pi-imager"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }
      { name = "rustdesk"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }
      { name = "softmaker-freeoffice"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }
      { name = "thunderbird"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }
      { name = "trilium-notes"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }
      { name = "zoom"; args = { appdir = "/Applications/Brew Apps/Ferramentas"; }; }

      # --- Games ---
      { name = "frankea/whisky/whisky"; args = { appdir = "/Applications/Brew Apps/Games"; }; }
      { name = "heroic"; args = { appdir = "/Applications/Brew Apps/Games"; }; }
      { name = "pcsx2"; args = { appdir = "/Applications/Brew Apps/Games"; }; }
      { name = "prismlauncher"; args = { appdir = "/Applications/Brew Apps/Games"; }; }
      { name = "steam"; args = { appdir = "/Applications/Brew Apps/Games"; }; }

      # --- Media ---
      { name = "discord"; args = { appdir = "/Applications/Brew Apps/Media"; }; }
      { name = "element"; args = { appdir = "/Applications/Brew Apps/Media"; }; }
      { name = "handbrake-app"; args = { appdir = "/Applications/Brew Apps/Media"; }; }
      { name = "homebrew/cask/transmission"; args = { appdir = "/Applications/Brew Apps/Media"; }; }
      { name = "legcord"; args = { appdir = "/Applications/Brew Apps/Media"; }; }
      { name = "obs"; args = { appdir = "/Applications/Brew Apps/Media"; }; }
      { name = "stremio"; args = { appdir = "/Applications/Brew Apps/Media"; }; }
      { name = "telegram-desktop"; args = { appdir = "/Applications/Brew Apps/Media"; }; }

      # --- Browsers (Default Appdir) ---
      "google-chrome"
      "zen"

      # --- Fonts ---
      "font-cascadia-code"
      "font-meslo-lg-nerd-font"
    ];
  };

  home-manager.users.zirondi = { config, lib, ... }: {
    # Activation script to apply native macOS folder icons to Brew Apps categories
    home.activation.applyFolderIcons = lib.hm.dag.entryAfter ["writeBoundary"] ''
      FILEICON="/opt/homebrew/bin/fileicon"
      BREW_APPS="/Applications/Brew Apps"
      ICONS_PATH="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources"

      if [ -x "$FILEICON" ]; then
        echo "Applying native macOS icons to Brew Apps categories..."
      
        # Dev
        if [ -d "$BREW_APPS/Dev" ]; then
          $FILEICON set "$BREW_APPS/Dev" "$ICONS_PATH/DeveloperFolderIcon.icns" >/dev/null 2>&1 || true
        fi

        # Ferramentas
        if [ -d "$BREW_APPS/Ferramentas" ]; then
          $FILEICON set "$BREW_APPS/Ferramentas" "$ICONS_PATH/UtilitiesFolder.icns" >/dev/null 2>&1 || true
        fi

        # Media
        if [ -d "$BREW_APPS/Media" ]; then
          $FILEICON set "$BREW_APPS/Media" "$ICONS_PATH/MovieFolderIcon.icns" >/dev/null 2>&1 || true
        fi

        # Games (Custom Icon)
        if [ -d "$BREW_APPS/Games" ]; then
          $FILEICON set "$BREW_APPS/Games" "${config.home.homeDirectory}/dotfiles/assets/icons/games-folder.icns" >/dev/null 2>&1 || true
        fi
      fi
    '';
  };
}
