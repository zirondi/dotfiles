# Keymap (macOS ↔ Linux)

This table is the source of truth for keyboard shortcuts across hosts. The configs below implement it; change this file first, then each config.

| File | Implements |
| :--- | :--- |
| `configs/aerospace/aerospace.toml` | Window manager on macOS (AeroSpace) |
| `configs/i3/config` | Window manager on Linux (i3) |
| `configs/karabiner/karabiner.json` | Caps Lock as Hyper key on macOS, `$mod+P` password menu |
| `modules/nixos/keyd.nix` | Caps Lock as Hyper key on Linux |
| `configs/xremap/config.yml` | Cmd-style app shortcuts on Linux (`Super+C` → `Ctrl+C`, ...) |
| `configs/kitty/linux.conf` | Cmd-style shortcuts inside Kitty on Linux |

## Principle: macOS is the reference

Everything is built around **Cmd**. macOS behavior can barely be changed, so macOS defines the shortcut and Linux adapts to it: **`Super` on Linux plays the role of `Cmd`**. The long-term setup is a MacBook Air as the laptop and a NixOS PC as the main machine, so both directions get daily use.

There are two layers, both on Cmd:

1. **App layer: `Cmd+key`.** Native on macOS. On Linux, `xremap` translates `Super+key` to `Ctrl+key` in every app except terminals, where Kitty handles `Super` itself. Translations use `exact_match`, so `Super+Ctrl+key` (the WM layer) is never touched.
2. **WM layer: `$mod` = `Cmd+Ctrl`** (`Super+Ctrl` on Linux). macOS already uses this chord for system actions (fullscreen, lock screen), and apps rarely bind it. `Cmd+Option` is avoided: browsers use it for DevTools and tab switching.

**PC keyboards:** keyd swaps left `Alt` and `Super` (keycaps swapped physically too), so the key next to the space bar is `Super` = `Cmd`, as on a Mac keyboard. Muscle memory follows position. Right `Alt` stays `AltGr` for ABNT2 symbols.

**Hyper key:** Caps Lock is a tap-hold key on both systems. **Tap = `Escape`**, **hold = `Cmd+Ctrl`** (`$mod`), so `Caps+J` equals `Cmd+Ctrl+J`. `Shift+Caps` toggles Caps Lock. Escape is sent on key release.

## WM layer (`$mod` = Cmd+Ctrl = Caps held)

| Keys | Action | AeroSpace | i3 |
| :--- | :--- | :--- | :--- |
| `$mod` + `h` `j` `k` `l` / arrows | Focus left, down, up, right | `focus` | `focus` |
| `$mod+Shift` + `h` `j` `k` `l` / arrows | Move window | `move` | `move` |
| `$mod` + `1`…`9`, `0` | Go to workspace 1…10 | `workspace N` | `workspace number N` |
| `$mod+Option` + `1`…`9`, `0` | Send window to workspace (not `$mod+Shift`: `Cmd+Ctrl+Shift+3/4` are macOS screenshots) | `move-node-to-workspace` | `move container to workspace` |
| `$mod+Tab` | Previous workspace (back and forth) | `workspace-back-and-forth` | `workspace back_and_forth` |
| `$mod` + `,` / `.` | Focus monitor left / right | `focus-monitor` | `focus output` |
| `$mod+Shift` + `,` / `.` | Send window to monitor left / right | `move-node-to-monitor` | `move container to output` |
| `$mod+F` | Fullscreen (same meaning as native macOS `Cmd+Ctrl+F`) | `fullscreen` | `fullscreen toggle` |
| `$mod+Shift+Space` | Toggle floating / tiling | `layout floating tiling` | `floating toggle` |
| `$mod+E` | Toggle split orientation | `layout tiles horizontal vertical` | `layout toggle split` |
| `$mod+W` | Tabbed (horizontal accordion) | `layout h_accordion` | `layout tabbed` |
| `$mod+S` | Stacked (vertical accordion) | `layout v_accordion` | `layout stacking` |
| `$mod+\` | Next window opens side by side | `split horizontal` | `split h` |
| `$mod+-` | Next window opens below | `split vertical` | `split v` |
| `$mod+R` | Resize mode: `h` `j` `k` `l`, `Esc`/`Enter` to leave | `mode resize` | `mode "resize"` |
| `$mod+Enter` | New terminal (Kitty) | `exec-and-forget open -na kitty` | `exec kitty` |
| `$mod+Shift+Q` | Close window | `close --quit-if-last-window` | `kill` |
| `$mod+Shift+C` | Reload WM config | `reload-config` | `reload` |
| `$mod+B` | Toggle the status bar (macOS: swap SketchyBar and the native menu bar, which holds the app icons). Linux: soft fullscreen of the focused monitor, its bar (and the dock on the laptop screen) hide and its windows take their space | `plugins/menubar.sh toggle` | `launch.sh toggle-bar` (bar, dock and the i3 gaps kept for them) |
| `$mod+P` | Password menu (`rbw-menu`) | Karabiner rule | `exec kitty --class rbw-menu` |
| `$mod+Q` | Lock screen | native macOS | `loginctl lock-session` (i3lock) |
| `$mod+Space` | Emoji picker | native macOS | `rofi -show emoji` |

i3 only: `$mod+Shift+R` restarts i3 in place.

## App layer (Cmd)

| Keys | Action | macOS | Linux |
| :--- | :--- | :--- | :--- |
| `Cmd+Space` | App launcher | Spotlight | `rofi -show drun` (i3) |
| `Cmd+Tab` | Switch window | native | `rofi -show window` (i3) |
| `Cmd+Shift+Q` | Log out | native (loginwindow dialog) | `confirm` surface (`configs/eww/scripts/confirm.sh`) |
| `Cmd+Shift` + `3` / `4` | Screenshot of the screen / an area, to a file | native (Desktop) | `maim` (`~/Pictures/Screenshots`) |
| `Cmd+Ctrl+Shift` + `3` / `4` | Same, to the clipboard | native | `maim \| xclip` |
| `Cmd+Shift+5` | Capture tool | native | `flameshot gui` |
| `Cmd` + `C` `V` `X` `Z` `A` `S` `F` `T` `W` `Q` `N` `R` `L` `O` `P` `K` `B` `I` | Copy, paste, cut, undo, select all, save, find, new tab, close tab, quit, new window, reload, address bar, open, print, link, bold, italic | native | `Ctrl+key` (xremap) |
| `Cmd+W` in single-window tools that ignore `Ctrl+W` (`nm-connection-editor`, `pavucontrol`, `blueman`) | Close window | native | `i3-msg kill` (xremap) |
| `Cmd+W` / `Cmd+Q` in Steam | Quit Steam (both: closing its window ends Steam on Linux, accepted on 2026-10-20) | native | `i3-msg kill` / `steam -shutdown` (xremap) |
| `Cmd+Shift` + `Z` `S` `T` `N` | Redo, save as, reopen tab, new private window | native | `Ctrl+Shift+key` (xremap) |
| `Cmd` + `=` `-` `0` | Zoom in, out, reset | native | `Ctrl+key` (xremap) |
| `Cmd` + `←` `→` | Start / end of line | native | `Home` / `End` (xremap) |
| `Cmd` + `↑` `↓` | Start / end of document | native | `Ctrl+Home` / `Ctrl+End` (xremap) |
| `Cmd+Backspace` | Delete to start of line | native | `Shift+Home`, `Backspace` (xremap) |
| `Cmd` + `[` `]` | Back / forward | native | `Alt+←` / `Alt+→` (xremap) |
| `Cmd+Shift` + `[` `]` | Previous / next tab | native | `Ctrl+PgUp` / `Ctrl+PgDn` (xremap) |
| `Option` + `←` `→` | Previous / next word | native | `Ctrl+←` / `Ctrl+→` (xremap) |
| `Option+Backspace` | Delete previous word | native | `Ctrl+Backspace` (xremap) |

Terminals are excluded from the xremap translation: `Ctrl+C` must stay SIGINT. Kitty maps `Super` itself in `configs/kitty/linux.conf`.

## Not mapped yet

- `Cmd` + `1`…`9` (tab N): Chromium uses `Ctrl+N` on Linux, Firefox and Zen use `Alt+N`. Needs per-app rules in xremap.
- `` Cmd+` `` (cycle windows of the same app).
