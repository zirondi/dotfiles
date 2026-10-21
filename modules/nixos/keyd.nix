{
  config,
  pkgs,
  lib,
  ...
}:

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
  # macOS-like shortcuts live inside Kitty (configs/kitty/linux.conf) and, for
  # every other app, in xremap (modules/nixos/xremap.nix), which translates
  # Super+key to Ctrl+key per application and skips terminals.
  #
  # Caps Lock is the Hyper key from configs/design/KEYMAP.md, same as Karabiner on
  # macOS: tap = Escape, hold = Super+Ctrl (the i3 $mod).

  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        # Every keyboard except xremap's virtual one (1234:5678). keyd's own
        # output goes to xremap (modules/nixos/xremap.nix); if keyd also grabbed
        # xremap's output, every key would pass through keyd twice and the
        # Alt/Super swap would apply twice: Super+Ctrl ($mod) would reach X as
        # Alt+Ctrl and the swap would cancel itself out.
        ids = [
          "*"
          "-1234:5678"
        ];
        settings = {
          main = {
            # CapsLock: tap → Escape (Neovim), hold → Super+Ctrl (i3 $mod)
            capslock = "overload(hyper, esc)";

            # Swap left Alt and Super so the key next to the space bar is Cmd
            # (Super), as on a Mac keyboard. Muscle memory follows position;
            # the keycaps are swapped physically too. Right Alt stays AltGr
            # (needed for ABNT2 symbols).
            leftalt = "layer(meta)";
            leftmeta = "layer(alt)";
          };
          # Modifier layer: holding it acts as Ctrl+Meta(Super) on every key
          "hyper:C-M" = { };
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
