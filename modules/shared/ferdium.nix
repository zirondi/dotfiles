{ ... }:

{
  # Ferdium custom recipes, kept in configs/ferdium/recipes and linked as the
  # client's dev recipe folder, so an edit there only needs a service reload
  # (Cmd+R). Workstations only: the servers have no Ferdium. The client itself
  # comes from the Homebrew cask (macOS) and nixpkgs (hosts/nitro5).
  home-manager.users.zirondi =
    { config, pkgs, ... }:
    let
      devRecipes =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/Ferdium/recipes/dev"
        else
          ".config/Ferdium/recipes/dev";
    in
    {
      home.file.${devRecipes}.source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/configs/ferdium/recipes";
    };
}
