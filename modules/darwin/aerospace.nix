{
  config,
  pkgs,
  lib,
  ...
}:

{
  # --- AeroSpace: i3-like tiling window manager for macOS ---
  # Keys: configs/design/KEYMAP.md. The config is configs/aerospace/aerospace.toml,
  # linked out of the store so edits apply with $mod+Shift+C (no rebuild).
  # It starts itself at login (start-at-login = true in the config).
  #
  # Installed as a cask in /Applications, like Karabiner: it needs the
  # Accessibility permission, which macOS ties to the app's path.

  homebrew.taps = [
    {
      name = "nikitabobko/tap";
      trusted = true;
    }
  ];
  homebrew.casks = [
    {
      name = "nikitabobko/tap/aerospace";
      args = {
        appdir = "/Applications";
      };
    }
  ];

  home-manager.users.zirondi =
    { config, ... }:
    {
      home.file.".config/aerospace/aerospace.toml".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/configs/aerospace/aerospace.toml";
    };
}
