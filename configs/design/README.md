# Desktop design system

One look and one behavior for the desktop on macOS (AeroSpace, SketchyBar, JankyBorders) and Linux (i3, eww, rofi, dunst, picom, i3lock). The files here are the source of truth; the configs implement them. **Change the spec first, then each platform's configs.**

| File | Holds |
| :--- | :--- |
| `GLOSSARY.md` | The words the spec uses, and each window manager's name for them |
| `THEME.md` | Tokens: color, type, size, shape, depth; bar layout; dock |
| `WINDOWS.md` | Window behavior and look, floating list, checklist |
| `SURFACES.md` | Menus, panels, tooltips, notifications, launcher, confirm, lock: one component, its states and variants, checklist |
| `KEYMAP.md` | Every shortcut on both platforms |
| `CAPABILITIES.md` | What each platform can and can't do, and the decision for each gap |
| `decisions/` | Why the hard-to-reverse choices were made |
| `prototype/` | `index.html`: the whole system rendered with the tokens, macOS and Linux side by side |

## Rules

1. **macOS defines behavior, the spec defines the look.** What a window or surface *does* is identical on both platforms, and when they differ macOS wins (`AGENTS.md` §3). The look is the ideal one; each platform implements as much of it as it can, and every shortfall is a row in `CAPABILITIES.md`. Linux may look richer (rounded corners, blur), never behave differently.
2. **Tokens, not values.** A config references a token by name through its platform's color/size definitions. A hex code or size that is not in `THEME.md` is a gap in the spec: report it, do not invent one.
3. **Every state is specified.** Each interactive part lists `normal`, `hover`, `selected`, `pressed`, `focused`, `disabled` (and `urgent` or `destructive` where they apply); a state that does not apply is marked so.
4. **Native macOS surfaces are exempt** (Spotlight, Notification Center, system dialogs, Dock, lock screen). Their Linux counterparts follow `SURFACES.md`.
5. **A change is done when its checklist is filled in** for the platform it touched (`WINDOWS.md`, `SURFACES.md`), with any "can't" pointing to `CAPABILITIES.md`.

## Prototype

`prototype/index.html` is a static page with no dependencies. To view it from another machine on the tailnet, serve it on the tailnet address only, never on `0.0.0.0`:

```bash
python3 -m http.server 8765 --bind "$(tailscale ip -4)" --directory configs/design/prototype
```

Then open `http://<host>:8765` from the other machine.
