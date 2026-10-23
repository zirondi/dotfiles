# Coding standards

The rules a reviewer checks in a diff of this repo, on top of what `just check` already enforces (`nixfmt`, `shellcheck`, flake evaluation). Read it when reviewing a change, and before writing a script or a stack. Mechanical rules belong in `just check`, not here: when one of these can be checked by a tool, move it there and delete it from this file.

## Everywhere

- Match the surrounding code: its comment density, naming and idiom. Comments are short and say why, not what.
- Each file stays in its language: the agent files, `configs/design/` and code comments in English; `ORDEM.md`, `TODO.md`, `reminders.md`, `agent_logs.md` and handoffs in Portuguese.
- Domain terms follow the glossaries in `GLOSSARY-MAP.md`; a word listed under _Avoid_ is a finding.

## Nix

- A shared module gets only what builds on both `aarch64-darwin` and `x86_64-linux`; a Linux-only package (for example a Linux GUI app) sits in a Linux module.
- Universal settings live in the shared modules; OS- or hardware-specific ones in `modules/darwin/`, `modules/nixos/` or the host.
- Every user config is linked with `config.lib.file.mkOutOfStoreSymlink` to `~/dotfiles/configs/...`, so edits are live without a rebuild.
- A new tool is installed declaratively in a module, not with an ad-hoc `nix run` or a manual install.

## Desktop

- A shortcut matches `configs/design/KEYMAP.md`, and a color, size or state matches a token or rule in `configs/design/` (`THEME.md`, `SURFACES.md`, `WINDOWS.md`). A value that is not a token is a gap to report, not a value to invent.
- A change to one platform's desktop has its counterpart on the other, or a row in `configs/design/CAPABILITIES.md` explaining why not.

## Scripts (`scripts/`)

- No hardcoded absolute paths, SSH ports or user names: hosts are SSH aliases resolved by `configs/ssh/config`.
- Scripts that take `<flake-host>` and `<target-ssh>` default the second to the first (`./deploy.sh nitro5`).
- Behaviour adapts to arguments; the script is reachable through `just` or `$PATH`.

## Stacks

- The stack follows `docs/agents/compose.md`: template, hardening, timezone, one exposure and its network, secrets only as `*.sops.yaml`.
- The inventories in `docs/` reflect any network or stack change in the same diff.

## Docs

- Mermaid node labels with special characters are quoted: `id["Label (Extra Info)"]`.
