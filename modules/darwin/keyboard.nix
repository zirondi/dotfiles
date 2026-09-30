{ config, pkgs, lib, ... }:

{
  # --- macOS Keyboard Configuration ---
  # Enables key remapping via hidutil and configures macOS-specific keyboard behavior.

  system.keyboard = {
    enableKeyMapping = true;
  };

  # --- Home/End Key Normalization ---
  # On macOS, Home/End natively jump to the top/bottom of the DOCUMENT.
  # On Windows/Linux, they jump to the beginning/end of the LINE.
  # This config makes macOS match the Windows/Linux behavior.
  #
  # Generates ~/Library/KeyBindings/DefaultKeyBinding.dict
  # Works in native Cocoa apps (TextEdit, Pages, Safari, Notes, etc.)
  # Does NOT affect Electron apps (VS Code, Discord) — they handle Home/End correctly already.
  # Does NOT affect Kitty — it sends its own escape sequences to the shell.
  home-manager.users.zirondi = { config, ... }: {
    home.file.".config/karabiner".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/configs/karabiner";

    targets.darwin.keybindings = {
      # Home → beginning of line (instead of top of document)
      "\\UF729"   = "moveToBeginningOfLine:";
      # End → end of line (instead of bottom of document)
      "\\UF72B"   = "moveToEndOfLine:";

      # Shift+Home → select to beginning of line
      "$\\UF729"  = "moveToBeginningOfLineAndModifySelection:";
      # Shift+End → select to end of line
      "$\\UF72B"  = "moveToEndOfLineAndModifySelection:";

      # Cmd+Home → beginning of document (original Home behavior, moved to Cmd)
      "@\\UF729"  = "moveToBeginningOfDocument:";
      # Cmd+End → end of document (original End behavior, moved to Cmd)
      "@\\UF72B"  = "moveToEndOfDocument:";

      # Shift+Cmd+Home → select to beginning of document
      "$@\\UF729" = "moveToBeginningOfDocumentAndModifySelection:";
      # Shift+Cmd+End → select to end of document
      "$@\\UF72B" = "moveToEndOfDocumentAndModifySelection:";
    };
  };
}
