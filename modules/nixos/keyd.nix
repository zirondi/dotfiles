{ config, pkgs, lib, ... }:

{
  # --- keyd: System-wide key remapping for NixOS workstations ---
  #
  # WHY NOT Super ↔ Ctrl swap?
  # ─────────────────────────────
  # It's tempting to swap Super and Ctrl to replicate macOS's Cmd behavior,
  # but it breaks badly in practice:
  #
  #   1. i3 uses Super ($mod) for window management — a swap would kill all
  #      WM shortcuts ($mod+Enter, $mod+d, $mod+1-9, etc.)
  #
  #   2. keyd operates at the evdev level (kernel), BEFORE apps see events.
  #      If Super+C becomes Ctrl+C, Kitty receives Ctrl+C = SIGINT instead
  #      of its internal cmd+c = copy_to_clipboard mapping.
  #
  #   3. Kitty's linux.conf already provides full macOS muscle memory:
  #      Super+C = copy, Super+V = paste, Super+T = new tab, etc.
  #      This works because Kitty treats Super as "cmd" and intercepts it
  #      before passing events to the shell.
  #
  # The approach: system terminal shortcuts (Ctrl+C, Ctrl+D, Ctrl+R) stay on Ctrl.
  # macOS-like shortcuts live inside Kitty and app-specific configs.

  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        settings = {
          main = {
            # CapsLock → Escape (tap)
            # Essential for Neovim — exit insert mode without reaching for Escape.
            capslock = "esc";
          };
          # Shift+CapsLock → toggle CapsLock
          # Preserves access to CapsLock when you genuinely need ALL CAPS.
          shift = {
            capslock = "capslock";
          };
        };
      };
    };
  };
}
