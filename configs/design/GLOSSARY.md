# Desktop

The shared language for the desktop on macOS and Linux: what sits on the screen and the states it can be in. The spec in this directory uses only these terms; each window manager's own word is listed under _Avoid_ and in the table at the end.

## Places

**Monitor**:
A physical screen and the area the window manager lays out on it.
_Avoid_: output, display, screen (in the spec)

**Workspace**:
A numbered set of windows shown on one monitor at a time.
_Avoid_: space, desktop, tag

**Bar**:
The floating strip at the top of each monitor with menus, workspaces, the clock and indicators.
_Avoid_: menu bar, panel, status bar

**Bar item**:
One element of the bar, interactive or not.
_Avoid_: module, widget, applet

**Dock**:
The strip of pinned and running apps on the right edge.
_Avoid_: launcher, taskbar

## Things

**Window**:
An application's rectangle, managed by the window manager.
_Avoid_: container, node, client

**Surface**:
Anything drawn above windows that is not a window: a menu, panel, tooltip, notification, launcher, confirmation or lock screen.
_Avoid_: popup, popover, overlay (as general terms)

**Variant**:
A named kind of surface (`menu`, `panel`, `tooltip`, `notification`, `launcher`, `confirm`, `lock`) that differs only in size, position and content.

**Row**:
One selectable line inside a surface.
_Avoid_: entry, item (inside surfaces)

**Native surface**:
A surface the system draws on macOS (Spotlight, Notification Center, system dialogs, Dock, lock screen); exempt from restyling.

## Arrangement

**Tiled window**:
A window placed by the layout, sharing the workspace with its neighbours.

**Floating window**:
A window placed by itself above the tiled ones.

**Layout**:
How the tiled windows of a workspace are arranged: tiles, tabbed or stacked.

**Tabbed**:
Windows on top of each other, one visible, switched side to side.
_Avoid_: horizontal accordion (except when naming the AeroSpace command)

**Stacked**:
Windows on top of each other, one visible, switched up and down.
_Avoid_: vertical accordion (except when naming the AeroSpace command)

## States

**Focused**:
The one window, or the one surface part, that receives keyboard input.
_Avoid_: active

**Selected**:
The surface row that Enter would activate, or the current choice in a list.
_Avoid_: highlighted, active

**Hover**:
Under the mouse pointer, without being chosen.

**Urgent**:
A window or workspace asking for attention.
_Avoid_: alert, demands attention

**Destructive**:
An action that ends the session or the machine (restart, shut down, log out).

## Spec terms

**Token**:
A named value in `THEME.md` (color, size, shape, depth) that configs reference instead of a literal.

**Platform**:
One side of the desktop: macOS (AeroSpace, SketchyBar) or Linux (i3, eww, rofi, dunst, picom).

## Names in each window manager

| Term | i3 | AeroSpace |
| :--- | :--- | :--- |
| Window | container, window, client | window, node |
| Monitor | output | monitor |
| Workspace | workspace | workspace |
| Tabbed | `tabbed` | `h_accordion` |
| Stacked | `stacking` | `v_accordion` |
| Tiles | `splith` / `splitv` | `tiles` |
| Floating window | floating container | floating window |
| Urgent | urgency hint | — |
