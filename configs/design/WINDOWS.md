# Windows

How windows look and behave on both platforms. Values are tokens from `THEME.md`; terms are defined in `GLOSSARY.md`; anything marked "Linux only" or "macOS: native" is explained in `CAPABILITIES.md`.

Implemented by `configs/aerospace/aerospace.toml` and JankyBorders (`modules/darwin/`) on macOS, and by `configs/i3/config` and picom (`modules/nixos/i3.nix`) on Linux.

## Behavior (identical on both)

macOS defines behavior; Linux matches it.

- **Layout:** new workspaces tile (`tiles` / default split), orientation chosen from the monitor's aspect (`auto`). Tabbed and stacked layouts exist only through `$mod+W` and `$mod+S` (`KEYMAP.md`). There is no scratchpad.
- **Focus does not follow the mouse.** Focus changes by click or keyboard. (AeroSpace default; i3 needs `focus_follows_mouse no`.)
- **Mouse warps on monitor change only:** when focus moves to another monitor, the pointer moves there (AeroSpace: the monitor center; i3: the focused window center, its only option). It does not move when focus changes on one monitor.
- **New windows take focus** when they open.
- **A window alone on a workspace** keeps its gaps and its border. No smart gaps, no hidden edge borders.
- **Fullscreen** (`$mod+F`) covers the whole monitor: no gaps, no border, no rounding, the bar hidden behind it.
- **Floating windows** sit above tiled ones and are moved with `$mod`+drag on Linux and `Cmd+Ctrl`+drag on macOS.
- **Destructive window actions** (`$mod+Shift+Q`) close at once, like `Cmd+W`; there is no confirmation for one window.

## Geometry

| Edge | Value |
| :--- | :--- |
| Top of the highest window | `window-top` (46 px from the screen top) |
| Between windows | `gap` (8 px) |
| Left, bottom | `edge` (8 px) |
| Right | `edge` from the dock (Linux: dock width + `edge`; macOS: the native Dock area + `edge`) |

On i3 the inner gap also applies at the screen edges, so the outer values are what is left after it: the agent sets them so the result matches this table, then measures.

## Look

| | Focused | Unfocused | Urgent |
| :--- | :--- | :--- | :--- |
| Border, `border-window` (2 px) | `border-active` | `border-inactive` | `border-urgent` (Linux only) |
| Title bar | none | none | none |
| Shadow | `shadow` (Linux) / native (macOS) | same | same |
| Dimming, opacity change | none | none | none |

- **Corners:** `radius-outer` on Linux through picom, border included. On macOS windows keep the system radius and JankyBorders follows it (`style=round`).
- **i3 has one more state**, `focused_inactive` (focused in a container that is not focused, e.g. on the other monitor): it uses `border-inactive`, the same as unfocused, because macOS has no such state.
- **i3 split indicator** (the edge where the next window will open): `accent-2`.
- **Tabbed and stacked title bars (i3 only):** the only title bars that exist. Height from the font (`text` = pango `10`), text centered. Focused: `tab-active` background, `fg` text. Others: `tab-inactive` background, `fg-dim` text. Border of the tab: same as its background. On macOS the equivalent is AeroSpace's accordion, which shows window edges, not titles.
- **Translucency:** windows are opaque unless the app asks otherwise (Kitty: `background_opacity 0.65`, `background_blur 64`; on Linux the blur comes from picom).

### What picom must not touch

Surfaces that draw their own shape: the eww bar and dock, rofi, dunst, i3lock. picom must not round them again, must not draw a second shadow on top of their own, and must give them `blur` only where `THEME.md` says so. Fullscreen windows get no rounding and no shadow.

## Floating

One list for both platforms. To add an app, add it here first, then to both configs.

| What | macOS (AeroSpace `on-window-detected`) | Linux (i3 `for_window`) |
| :--- | :--- | :--- |
| Dialogs, file pickers, pop-up windows | AeroSpace floats dialogs by itself | `window_type="dialog"`, `window_role="dialog"`, `window_role="pop-up"` |
| Password menu (`rbw-menu`) | Kitty window titled `rbw-menu` | `class="rbw-menu"` |
| System settings | System Settings | — |
| Sound settings | (inside System Settings) | `class="Pavucontrol"` |
| Network settings | (inside System Settings) | `class="Nm-connection-editor"` |
| Bluetooth settings | (inside System Settings) | `class=".blueman-manager-wrapped"` (check the real class with `xprop`) |

Placement: on Linux a floating window opens **centered** on its monitor at the size it asks for. AeroSpace has no centering command, so on macOS the app places it (most center themselves).

## Conformance checklist

The implementing agent fills this in for its platform and hands it back. "Can't" must point to a line in `CAPABILITIES.md`.

- [ ] Focused border is `accent`, 2 px; unfocused is `#3a2577`; urgent is `red` (Linux) — checked by opening two windows side by side.
- [ ] A single window on a workspace has a border and 8 px gaps.
- [ ] The top of a window is 46 px below the screen top, i.e. 8 px under the bar; 8 px from the left and bottom; 8 px from the dock.
- [ ] Linux: windows have 10 px rounded corners, border included; the bar, dock, rofi, dunst and lock screen are not double-rounded or double-shadowed.
- [ ] Linux: translucent Kitty shows blur behind it.
- [ ] Focus does not follow the mouse; moving focus to the other monitor centers the pointer there.
- [ ] Every row of the floating table floats; on Linux it opens centered.
- [ ] Fullscreen: no gaps, border, rounding or shadow.
- [ ] i3 tabbed/stacked titles use `tab-active` / `tab-inactive` and `text`.
- [ ] No hex literal outside the platform's color definitions.
