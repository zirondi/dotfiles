{ config, pkgs, lib, ... }:

let
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
in
{
  home.username = "zirondi";
  home.homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/zirondi" else "/home/zirondi";
  home.stateVersion = "24.05";

  home.file = {
    ".config/kitty".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/configs/kitty";
    ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/configs/nvim";
    ".config/git".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/configs/git";
    ".config/starship.toml".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/configs/starship/starship.toml";
    
    # Extra files
    ".hushlogin".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/configs/zsh/.hushlogin";
    ".zshrc_essentials".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/configs/zsh/.zshrc_essentials";
    ".ssh/config".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/configs/ssh/config";
    ".config/opencode/opencode.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/configs/opencode/opencode.json";
    ".config/rclone/rclone.conf.template".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/configs/rclone/rclone.conf.template";
    ".agents/.skill-lock.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/configs/agents/.skill-lock.json";
  };

  # Activation script to synchronize AI agent skills via skills.sh if network is reachable
  home.activation.syncSkills = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -f "${config.home.homeDirectory}/.agents/.skill-lock.json" ] && command -v npx >/dev/null 2>&1; then
      if ${pkgs.curl}/bin/curl -s --connect-timeout 2 https://skills.sh >/dev/null 2>&1; then
        echo "Syncing AI agent skills via skills.sh..."
        npx --yes skills update -g -y >/dev/null 2>&1 || true
      fi
    fi
  '';

  home.packages = with pkgs; [
    nerd-fonts.hack
    nerd-fonts.terminess-ttf
    nerd-fonts.iosevka-term
    nerd-fonts._3270
  ];

  programs.home-manager.enable = true;
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      share = true;
    };

    # Source our custom configs
    initContent = ''
      source ${dotfilesPath}/configs/zsh/.zshrc
    '';
    profileExtra = ''
      source ${dotfilesPath}/configs/zsh/.zprofile
    '';
  };
}
