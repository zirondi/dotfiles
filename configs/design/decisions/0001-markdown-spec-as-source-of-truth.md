# Markdown spec as the source of truth, configs written by hand

The desktop design system lives in Markdown (`configs/design/`), and each platform's configs are written by hand to match it, with a conformance checklist per component. We chose this over generating configs from one tokens file (a Nix attrset or JSON templated into SketchyBar, eww, rofi, dunst and i3 configs) and over Stylix, because both put the generated files in the Nix store: every tweak would need a rebuild, breaking the live editing that `mkOutOfStoreSymlink` gives (`AGENTS.md` §7). Stylix also has no target for AeroSpace, SketchyBar, eww or picom.

## Consequences

Drift between the two platforms is caught by people, not tools. If the checklists stop catching it (the same token disagreeing between `colors.sh`, `eww.scss`, `config.rasi` and `dunstrc` again), revisit this: generate only the per-platform color/size definition files from one tokens file and keep the rest hand-written, so live editing survives for everything but the tokens.
