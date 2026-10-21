# Capabilities

What each platform can do for the parts of this system, and what the spec decided for each gap. Researched 2026-10-20 against AeroSpace v0.21.3-Beta, JankyBorders v1.9.0, SketchyBar, i3 4.25.1 and picom v13. Nothing was verified specifically on macOS 27; recheck a row before relying on it after an upgrade.

Sources: [AeroSpace guide](https://nikitabobko.github.io/AeroSpace/guide) and [commands](https://nikitabobko.github.io/AeroSpace/commands), [JankyBorders man page](https://github.com/FelixKratz/JankyBorders/wiki/Man-Page), [i3 user guide](https://i3wm.org/docs/userguide.html), [picom](https://picom.app/).

## Windows

| Capability | macOS | Linux | Spec decision |
| :--- | :--- | :--- | :--- |
| Border width and active / inactive color | JankyBorders `width`, `active_color`, `inactive_color` | i3 `default_border pixel`, `client.*` | Both, `decisions/0002-jankyborders-on-macos.md` |
| Urgent border color | **No** (no urgency data in AeroSpace or JankyBorders) | i3 `client.urgent` | Linux only |
| Gradient or glow border | JankyBorders, not both at once ([#155](https://github.com/FelixKratz/JankyBorders/issues/155)) | No | Not used |
| Window corner radius | **No**: the system decides, and it varies per app on Tahoe. JankyBorders follows it (`style=round`) | picom `corner-radius`, rounds the i3 border too | Linux `radius-outer`; macOS native |
| Inner, outer, per-side gaps | Yes | Yes | Both |
| Smart gaps (no gaps for one window) | **No**, rejected upstream ([PR #1229](https://github.com/nikitabobko/AeroSpace/pull/1229)) | `smart_gaps`, `hide_edge_borders smart` | Not used: gaps and border always |
| Title bars | **No**, won't be added ([#90](https://github.com/nikitabobko/AeroSpace/issues/90)) | Yes | None, except i3 tabbed/stacked titles |
| Tab / stack indicator | Accordion edge slivers only | Tabbed/stacked title bars | Platform's own; styled on i3 |
| Dim or fade unfocused windows | **No** | picom `rules` with `dim`, `opacity` | Not used |
| Window shadows | Native, fixed | picom `shadow` | Linux matches `shadow` |
| Blur behind windows | **No** for AeroSpace windows (JankyBorders dropped blur in 1.7.0); apps like Kitty blur themselves | picom `blur-method dual_kawase` | Linux `blur` |
| Animations (open, close, workspace, move) | **No**, by design | picom `animations` | None in v1, `decisions/0003-no-motion-in-v1.md` |
| Float by app or title | `on-window-detected` | `for_window` | One list, `WINDOWS.md` |
| Center or size a floating window | **No** absolute position or center command | `move position center`, `resize set` | Linux centers; macOS leaves it to the app |
| Always on top | **No** ([#4](https://github.com/nikitabobko/AeroSpace/issues/4)) | Floating is above tiling only | Not used |
| Sticky across workspaces | **No** ([#2](https://github.com/nikitabobko/AeroSpace/issues/2)) | `sticky enable` | Not used |
| Scratchpad | **No** ([#272](https://github.com/nikitabobko/AeroSpace/issues/272)) | Yes | Not used |
| Layouts | `tiles`, `accordion` (h/v), orientation `auto` | `splith/v`, `tabbed`, `stacking`, orientation `auto` | `KEYMAP.md` maps tabbed ↔ h_accordion, stacked ↔ v_accordion |
| Focus follows mouse | `focus-follows-mouse` (off by default) | `focus_follows_mouse` (on by default) | Off on both |
| Pointer warp | Callbacks: `move-mouse monitor-lazy-center` | `mouse_warping output` (window center) | On monitor change only |
| Drag to move | Tiled swap and resize; `Cmd+Ctrl` drag anywhere | `floating_modifier`, `tiling_drag` | Platform's own |

## Bars and surfaces

| Capability | macOS | Linux | Spec decision |
| :--- | :--- | :--- | :--- |
| Blur behind bar and surfaces | SketchyBar `blur_radius` | picom `dual_kawase` (eww draws no blur itself) | Both, `blur` |
| Shadow on bar and surfaces | SketchyBar `shadow=on` | picom | Both, `shadow` |
| Urgent workspace in the bar | **No** data (only the Dock bounce) | i3 workspace `urgent` flag | Linux only |
| Anchor a popup to its bar item | SketchyBar popups attach to their item | eww windows have fixed geometry | Linux aligns to the bar section (`SURFACES.md`) |
| Restyle notifications, launcher, lock screen, Dock | **No** (native) | dunst, rofi, i3lock, eww dock | Native exempt; Linux follows `SURFACES.md` |
| Separate hover state on launcher and menus | Native exempt | **No** in rofi: no `:hover` element state; `hover-select` turns the hovered row into the selection | In rofi, hover paints `selected` (magenta 35%); eww popups keep separate `hover` (white 8%) |

## Known issues on macOS 26+

- JankyBorders: high WindowServer GPU use ([#188](https://github.com/FelixKratz/JankyBorders/issues/188)), corrupted borders on resize under 26.5 ([#199](https://github.com/FelixKratz/JankyBorders/issues/199)), memory growth ([#128](https://github.com/FelixKratz/JankyBorders/issues/128)). `style=square` still leaves the inner corner round ([#194](https://github.com/FelixKratz/JankyBorders/issues/194)). If radii look wrong on Tahoe, rebuild against the current Xcode CLT ([#176](https://github.com/FelixKratz/JankyBorders/issues/176)).
- AeroSpace parks windows of hidden workspaces in a screen corner; JankyBorders can draw "ghost" borders there ([#181](https://github.com/FelixKratz/JankyBorders/issues/181)).
- AeroSpace on 26.5: slow or missed window detection ([#1615](https://github.com/nikitabobko/AeroSpace/issues/1615)). v0.20.3 changed its signing certificate, so macOS asks for Accessibility again after that upgrade.
- picom: the `size` and `position` animation triggers are experimental (irrelevant while v1 has no motion).
