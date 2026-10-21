# Surfaces

Everything that floats above windows and is not a window: menus, panels, tooltips, notifications, the launcher, confirmations, the lock screen. They are one component with variants. A variant changes only size, position and content; anatomy, tokens and states are shared. Values are tokens from `THEME.md`.

Implemented by `configs/sketchybar/lib/popup.sh` (macOS) and by the `.popup`/`.entry` classes in `configs/eww/eww.scss`, `configs/rofi/config.rasi` and `configs/dunst/dunstrc` (Linux).

**Native surfaces are exempt.** Spotlight, Notification Center, system dialogs, the macOS Dock and the macOS lock screen are drawn by the system and not restyled. The Linux surface that plays the same role follows this file; it should look like a sibling of the macOS one, not a copy.

## Anatomy

```
╭───────────────────────────────╮  container: bg-surface, outline 1 px, radius-outer,
│  Header                       │             blur, shadow, pad-surface
│ ╭───────────────────────────╮ │
│ │ 󰒓  Row label        ⌘ ,   │ │  row: row-height, pad-row, radius-inner,
│ ╰───────────────────────────╯ │       icon + space-icon + label (+ hint, fg-dim)
│ ───────────────────────────── │  separator: 1 px, separator, 4 px above and below
│ ╭───────────────────────────╮ │
│ │ 󰐥  Shut Down…             │ │
│ ╰───────────────────────────╯ │
╰───────────────────────────────╯
```

| Part | Look |
| :--- | :--- |
| Container | `bg-surface`, `border-surface` in `outline`, `radius-outer`, `blur`, `shadow`, padding `pad-surface` |
| Header (optional) | `text-strong`, `fg`, same padding as a row, not interactive |
| Row | `row-height`, padding `pad-row`, corners `radius-inner`; icon (`text` size, centered in `icon-slot`) + `space-icon` + label in `text`, `fg`; an optional hint (shortcut, value) right-aligned in `fg-dim` |
| Separator | 1 px line in `separator`, full width inside the padding, 4 px of space above and below |
| Secondary line | `text-small`, `fg-dim` |
| Input field (launcher) | `hover` background, `radius-inner`, `pad-row`, text `fg`, placeholder `fg-dim` |
| Slider (volume) | track `hover`, filled part `accent`, knob `fg` |

## States

Every interactive part has all of these. "—" means the state does not apply and must not be styled.

| State | Meaning | Row | Input field | Slider |
| :--- | :--- | :--- | :--- | :--- |
| `normal` | At rest | no background, `fg` | as in Anatomy | as in Anatomy |
| `hover` | Under the mouse | `hover` background | — | knob unchanged |
| `selected` | What Enter would activate (keyboard), or the current choice (active output, today) | `selected` background | — | — |
| `pressed` | Mouse button down | `selected` background | — | — |
| `focused` | Has keyboard focus and is not already shown as `selected` | `focus-ring` | `focus-ring` | `focus-ring` |
| `disabled` | Not available now | `fg-dim` text, no hover | `fg-dim` text | `fg-dim` fill |
| `destructive` | Ends the session or the machine | label ends in `…`, opens a `confirm`; `fg` until hovered, then `red` text | — | — |

`hover` and `selected` can be true at once (mouse over the keyboard selection): `selected` wins.

## Variants

| Variant | Opened by | Width | Position | Closes on |
| :--- | :--- | :--- | :--- | :--- |
| `menu` | Click on a bar item (logo menu, volume outputs, network) | `surface-width` minimum, grows with content | Under the item that opened it, top at `surface-top`, kept `edge` from the screen edge | Click outside, `Esc`, choosing a row, a second click on the item |
| `dock-menu` | Right-click on a dock item (Linux; macOS: the native Dock menu) | `surface-width` minimum, grows with content | At the pointer (rofi `-monitor -3`); opened from the logo menu (Displays) it is centered on the monitor under the mouse instead (rofi `-monitor -5`), since a left-edge pointer would push it off screen | Same as `menu` |
| `panel` | Click on the clock (calendar + events), volume (slider + outputs) | `panel-width` | Same as `menu` | Same as `menu`, except choosing (panels stay open while used) |
| `tooltip` | Hovering a bar item that has one | content | Under the item, 6 px gap | Mouse leaves the item |
| `notification` | dunst (Linux). macOS: native | 360 px | Top right: top at `surface-top`, right at `edge`; 6 px between stacked ones | Timeout 5 s (`critical`: never), click. A click runs the notification's action, as on macOS; with several actions and no default one it opens them as a `dock-menu` at the pointer (rofi). Right click closes all. Requests that need an answer (Bluetooth pairing) are dialogs with buttons, not notifications |
| `launcher` | `Cmd+Space`, `Cmd+Tab`, `$mod+Space` (rofi). macOS: Spotlight, native | `launcher-width` (680 px) | Centered horizontally, top at 20% of the screen | `Esc`, choosing, click outside |
| `confirm` | A `destructive` row (Linux). macOS: native `loginwindow` dialog | 300 px | Centered on the screen | Either button, `Esc` (= Cancel) |
| `lock` | Lock, sleep, lid (Linux, i3lock). macOS: native | full screen | — | Correct password |

Where the platform cannot anchor a surface to its item (eww windows have fixed geometry), it is aligned to the bar section instead: left section `edge` from the left, center section centered, right section `edge` from the right. Never a hand-tuned offset like `x 120px`.

### Variant details

- **notification:** title `text-strong`, body `text`, app icon at most 32 px on the left, `pad-notification`. `critical` replaces the `outline` border with 1 px `red` and has no timeout. Only one look for `low` and `normal`.
- **launcher:** sized like Spotlight, larger than the other surfaces. Input field on top with `launcher-input` text, then up to 8 rows of `launcher-row-height` with `launcher-text` labels and `launcher-icon` app icons. The highlighted result is `selected`; mouse hover over the others is `hover`. The `confirm` surface keeps the normal row and text sizes even where it shares the launcher's theme.
- **confirm:** header with the action ("Shut down?"), one `text` line of consequence, two buttons on one row: **Cancel** (left, `selected` by default, so Enter cancels) and the action (right, `red` text). Buttons are rows with `radius-inner`.
- **lock (spec only, implementation later):** wallpaper behind, the clock in `text-strong` scaled up, the ring in `accent-2`, `accent` on key press, `red` when wrong. The current i3lock screen was disliked (`TODO.md`); redesign it with the user before implementing.
- **tooltip:** `pad-tooltip`, `text`, one line; no header, no rows.

## Conformance checklist

The implementing agent fills this in for its platform and hands it back. "Can't" must point to a line in `CAPABILITIES.md`.

- [ ] Every surface has `bg-surface` (90%), 1 px `outline`, `radius-outer` 10 px, `blur`, `shadow`. List any surface that differs.
- [ ] Rows are 26 px with `radius-inner` 6 px; hover is white 8%; keyboard selection and pressed are magenta 35%.
- [ ] Icons use `Hack Nerd Font Propo` and sit in an 18 px slot in rows: no glyph is squeezed, clipped or touching its label, and labels line up across rows.
- [ ] Text in Red Hat Mono: 13 px default, 13 px Bold headers, 11 px secondary; rofi and dunst converted to pango points, with Hack Nerd Font Propo as the icon fallback.
- [ ] Menus and panels open with their top at 44 px, `edge` from the screen side, aligned to their item or section; no hand-tuned offsets.
- [ ] Notifications: top 44 px, right 8 px, 360 px wide, `critical` with a red border.
- [ ] Every destructive row ends in `…` and asks for confirmation; Enter in the confirmation cancels.
- [ ] `Esc` and a click outside close menus, panels and the launcher, or `CAPABILITIES.md` says why not.
- [ ] Tooltips: radius 10 px, padding 4×8.
- [ ] No hex literal outside the platform's color definitions.
