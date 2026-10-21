# Theme

Tokens for the shared look of macOS and Linux: color, type, size, shape, depth. Every value a config uses comes from this file, by token name. A value that is not here is a gap in the spec: report it, do not invent it. Components are in `WINDOWS.md` and `SURFACES.md`; what each platform can't do is in `CAPABILITIES.md`.

Dark only (v1). No motion (v1, `decisions/0003-no-motion-in-v1.md`).

## Wallpaper

`wallhaven-m371r9.jpg` (6016×3384): magenta and violet smoke fading into black. It lives in `~/Pictures/` on each machine and is **not** committed (third-party image, 3.7 MB, public repo). The prototype uses a gradient of `accent`, `accent-2` and `bg` in its place.

| Host | Path | Set by |
| :--- | :--- | :--- |
| macmini | `~/Pictures/wallhaven-m371r9.jpg` | System Settings (by hand) |
| nitro5 | `~/Pictures/wallpaper.jpg` | `feh` in `configs/i3/config` |

To copy it to a new Linux host: `scp ~/Pictures/wallhaven-m371r9.jpg <host>:Pictures/wallpaper.jpg`.

## Color

Accents come from the wallpaper; text and status colors are Apple's dark system colors (same as `configs/kitty/kitty.conf`).

### Base

| Token | Value | Used for |
| :--- | :--- | :--- |
| `bg` | `#0e0b1c` | Base of every background (deep indigo from the bottom of the wallpaper) |
| `fg` | `#f5f5f7` | Text, icons |
| `fg-dim` | `#8e8e93` | Secondary and inactive text, disabled items |
| `accent` | `#e04cc8` | Focus: focused workspace, focused window border, selection (magenta) |
| `accent-2` | `#7c4dff` | Presence: occupied workspaces, app icons, the i3 split indicator (violet) |
| `red` | `#ff453a` | Urgent, critical, destructive actions, wrong password |
| `orange` | `#ff9f0a` | Microphone in use |
| `yellow` | `#ffd60a` | Low battery, warnings |
| `green` | `#32d74b` | Charging, camera in use |

### Composite

| Token | Value | Used for |
| :--- | :--- | :--- |
| `bg-bar` | `bg` at 70% | Bar and dock |
| `bg-surface` | `bg` at 90% | Every surface (`SURFACES.md`): menus, panels, tooltips, notifications, launcher, confirm |
| `outline` | `#ffffff` at 20% | 1 px edge of the bar, the dock and every surface |
| `separator` | `#ffffff` at 20% | Lines between groups of rows (same value as `outline`) |
| `hover` | `#ffffff` at 8% | Background of anything under the mouse |
| `selected` | `accent` at 35% | Background of the item Enter would activate, the active choice, a pressed item |
| `focus-ring` | `accent`, 1 px, inside the item | Keyboard focus where it differs from `selected` |
| `border-active` | `accent` | Focused window |
| `border-inactive` | `#3a2577` | Unfocused windows (`accent-2` at 40% over `bg`, flattened because i3 has no alpha) |
| `border-urgent` | `red` | Window asking for attention (Linux only) |
| `tab-active` | `#582258` | i3 tab/stack title of the focused window (`selected` over `bg`, flattened) |
| `tab-inactive` | `bg` | Other i3 tab/stack titles |

### Alpha in each format

| Opacity | Hex alpha | SketchyBar, JankyBorders `0xAARRGGBB` | rofi, dunst `#RRGGBBAA` | GTK CSS (eww) |
| :--- | :--- | :--- | :--- | :--- |
| 90% | `e6` | `0xe60e0b1c` | `#0e0b1ce6` | `rgba(14, 11, 28, 0.90)` |
| 70% | `b3` | `0xb30e0b1c` | `#0e0b1cb3` | `rgba(14, 11, 28, 0.70)` |
| 35% | `59` | `0x59e04cc8` | `#e04cc859` | `rgba(224, 76, 200, 0.35)` |
| 20% | `33` | `0x33ffffff` | `#ffffff33` | `rgba(255, 255, 255, 0.20)` |
| 8% | `14` | `0x14ffffff` | `#ffffff14` | `rgba(255, 255, 255, 0.08)` |

i3 takes `#RRGGBB` only, which is why the window tokens above are flattened. Colors are defined once per platform (`configs/sketchybar/colors.sh`, the variables at the top of `configs/eww/eww.scss`) and referenced by name; a hex literal anywhere else is a bug.

## Type

Both families are installed on every host by `modules/shared/home.nix` (packages `redhat-official-fonts` and `nerd-fonts.hack`). Weights: **Regular and Bold only**. Red Hat Mono also ships Light and Medium, but SketchyBar silently falls back to the proportional system font for a weight a family lacks, so the system sticks to the two every font has.

| Token | Family | Used for |
| :--- | :--- | :--- |
| `font` | `Red Hat Mono` | All text. Chosen over Hack (too thin and narrow) and Cascadia Code (slightly smaller at the same size) by comparing them in the prototype, 2026-10-20 |
| `font-icon` | `Hack Nerd Font Propo` | Every glyph icon (bar, dock, rows, notifications) |

Red Hat Mono has no Nerd Font glyphs. Wherever one string sets the font for both text and icons (rofi, dunst, i3 titles), list the icon font as a fallback: pango `Red Hat Mono, Hack Nerd Font Propo 10`; GTK CSS `font-family: "Red Hat Mono", "Hack Nerd Font Propo"`.

Icons must use the **Propo** variant. The plain `Hack Nerd Font` gives each icon the width of one text cell, so renderers squeeze wide glyphs (Wi-Fi, volume, display) or let them overflow into the label; `Hack Nerd Font Mono` shrinks them on purpose. Propo gives each icon its own width. Seen on nitro5 in the prototype (Zen), 2026-10-20.

| Token | Size | Weight | Used for |
| :--- | :--- | :--- | :--- |
| `text` | 13 px | Regular | Default: bar labels, rows, notification body, tooltips |
| `text-strong` | 13 px | Bold | Clock, focused workspace number, surface headers, notification title |
| `text-small` | 11 px | Regular | Stats (CPU, GPU, RAM), metadata, secondary lines |
| `launcher-input` | 20 px | Regular | Text typed in the launcher |
| `launcher-text` | 15 px | Regular | Launcher result rows |
| `icon` | 14 px | Bold | Bar icons |
| `icon-large` | 16 px | Bold | Logo menu icon (Apple, NixOS), tray icons |

Sizes are logical pixels. macOS points equal logical pixels, so SketchyBar uses them as they are. Pango sizes (i3, rofi, dunst) are points: `pt = px × 0.75` at 96 dpi, so 13 px = `10`, 11 px = `8`, 15 px = `11`, 16 px = `12`, 20 px = `15`. GTK CSS (eww) takes `px` directly. If nitro5 does not run at 96 dpi (`xrdb -query | grep dpi`), recompute and record the factor here.

Terminal text (Kitty: Cascadia Code 14) is the content of a window, not part of this system.

## Size and spacing

| Token | Value | Used for |
| :--- | :--- | :--- |
| `bar-height` | 32 px | Bar |
| `bar-offset` | 6 px | Bar from the top edge of the screen |
| `edge` | 8 px | Bar side margin; any surface or window from a screen edge; windows from the dock |
| `gap` | 8 px | Between windows; window top edge below the bar |
| `window-top` | 46 px | Top of the highest window: `bar-offset + bar-height + gap` |
| `surface-top` | 44 px | Top of a surface opened from the bar: `bar-offset + bar-height + 6` |
| `row-height` | 26 px | One row in a menu or panel |
| `pad-surface` | 6 px | Inside a surface, around its rows |
| `pad-row` | 0 10 px | Inside a row (vertical, horizontal) |
| `pad-tooltip` | 4 8 px | Inside a tooltip |
| `pad-notification` | 10 12 px | Inside a notification |
| `icon-slot` | 18 px | Fixed width reserved for the icon at the start of a row, input or slider, glyph centered in it. Nerd Font glyphs in Hack Nerd Font are up to two cells wide, so a slot as wide as the font size clips them; the fixed slot also keeps labels aligned |
| `space-icon` | 8 px | Between an icon (or its slot) and its label |
| `surface-width` | 240 px | Minimum width of a menu |
| `panel-width` | 300 px | Calendar and other panels |
| `launcher-width` | 680 px | Launcher (Spotlight-sized; the menus' 240 px scale read as too small on a 15.6" 1080p screen, 2026-10-20) |
| `launcher-row-height` | 36 px | One result row in the launcher |
| `launcher-icon` | 24 px | App icon in a launcher row |

## Shape

| Token | Value | Used for |
| :--- | :--- | :--- |
| `radius-outer` | 10 px | Windows (Linux, through picom), bar, dock, every surface |
| `radius-inner` | 6 px | Anything inside a container: rows, workspace pills, dock items, input fields, calendar days |
| `border-window` | 2 px | Window border (i3, JankyBorders) |
| `border-surface` | 1 px | `outline` around the bar, the dock and surfaces |

## Depth

| Token | Value | Used for |
| :--- | :--- | :--- |
| `blur` | radius 30 (SketchyBar `blur_radius`) | Behind everything translucent: bar, dock, surfaces, Kitty. Linux: picom `dual_kawase`, strength tuned by eye to match, value recorded in the picom config |
| `shadow` | black at 45%, blur 24 px, offset 0 x / 8 y | Windows, bar, dock, surfaces. macOS draws its own window shadows; this token is for the Linux side and SketchyBar |

## Bar layout

Same structure on both systems:

| Position | macOS (SketchyBar) | Linux (eww) |
| :--- | :--- | :--- |
| Left | Apple menu (About, Settings, App Store, Activity Monitor, Sleep, Lock, Restart…, Shut Down…, Log Out…) | NixOS logo menu (Lock, Sleep, Restart…, Shut Down…, Log Out…, Network, Bluetooth, Sound, Displays) |
| Left | AeroSpace workspaces | i3 workspaces |
| Left | Menus of the focused app (`pkgs/sketchybar-menus`, needs Accessibility); in a browser, the tab title | Focused window title (a browser's tab title) |
| Center | Clock, Brazilian date (`sáb 17/10  21:05`); click: month + next events (khal), Cmd+click: Calendar | Clock, same format; click: month (GTK calendar) + next events (khal); bell = Focus (dunst paused) |
| Right | Mic (orange) / camera (green) in use, hidden while idle (`pkgs/sketchybar-privacy`) | Mic / camera in use (PipeWire streams, `/dev/video*`) |
| Right | Now playing (`media-control`) | Now playing (`playerctl`) |
| Right | CPU, GPU (IOKit), RAM; click: Activity Monitor | CPU, GPU (AMD iGPU, "NV x%" for the NVIDIA card), RAM; click: `btop` in Kitty |
| Right | Network: Ethernet when up, else Wi-Fi; click: Network settings | Network: IP, name in the tooltip; click: nm-connection-editor |
| Right | Bluetooth (click toggles) | Bluetooth (click toggles, right click blueman) |
| Right | Volume: scroll changes it; click: slider, outputs (`switchaudio-osx`), Sound Settings | Volume: scroll changes it; click: slider, outputs, Per-App Volume (pavucontrol) |
| Right | Battery (hidden without one) | Battery, tray |
| Right | Toggle to the native menu bar (app icons) | — |

Bar shape: a floating pill, `bar-height` high, `bar-offset` from the top, `edge` from each side (a fixed margin, not a percentage width), `radius-outer` corners, `bg-bar` with `blur`, `border-surface` in `outline`, `shadow`.

Bar items:

| Item | Normal | Hover | Selected / active | Urgent |
| :--- | :--- | :--- | :--- | :--- |
| Workspace pill (22 px high, `radius-inner`) | empty: hidden; occupied: `accent-2` text | `hover` | focused: `accent` background, `fg` `text-strong`; shown on its own monitor without focus: `focus-ring`, `fg` text. Each monitor's bar lists only that monitor's workspaces | `red` background (Linux only) |
| Icon or label button | `fg` | `hover` behind it, `radius-inner` | its popup open: `selected` | — |
| Stats (CPU, GPU, RAM) | `fg`, `text-small` | `hover` behind it, `radius-inner` | — | — |
| Indicator with no action (battery, mic/camera) | `fg` | none | — | — |

Popups share one look: `SURFACES.md`. Calendars come from Nextcloud through vdirsyncer + khal (`modules/shared/calendar.nix`).

`$mod+B` toggles the bar on both (configs/design/KEYMAP.md). On macOS it swaps SketchyBar and the native menu bar: since macOS 26/27 the native status icons are drawn by one process (`MenuBarAgent`), so SketchyBar can no longer mirror them as aliases.

## Dock

macOS Dock on the right (`modules/darwin/desktop.nix`) with DockDoor previews; it is native and not restyled. On Linux the eww dock on the right (`configs/eww`, pinned apps in `configs/eww/dock-pinned`, running apps from i3) follows the bar's shape: `bg-bar`, `blur`, `outline`, `radius-outer`, `shadow`, `edge` from the screen edge. Items use `radius-inner`; hover is `hover`, the focused app is `selected`, a running app has a `•` in `fg` under it (10 px; transparent when not running, so the items keep their height). i3 has dock areas only at the top and bottom, so the eww bar and dock ignore i3 and the i3 gaps keep windows `edge` clear of them.
