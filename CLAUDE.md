# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

The binding rules for this repo (no automatic commits, cross-OS parity, compose conventions, secrets, SSH, credentials) live in `AGENTS.md` and are imported here. Read them as part of this file:

@AGENTS.md

## Commands

`just` wraps everything in `scripts/`; run `just` to list recipes. `nix develop` gives a shell with `just`, `shellcheck`, `nixfmt`, `statix`, `deadnix`, `sops`, `age` and `ssh-to-age`.

| Task | Command |
| :--- | :--- |
| Full validation (what CI runs) | `just check` |
| Lint shell scripts | `just lint` |
| Format Nix files | `just fmt` |
| Apply to this machine | `just switch` |
| Deploy to a remote host | `just deploy <host> [--nix \| --svc <stack>...]` |
| Build a host without deploying | `just deploy <host> --build-only` |
| Update flake inputs and deploy | `just update <host> [--input nixpkgs]` |
| Build-check the Nitro 5 config as a VM | `just vm-test` (add `--image` for a QCOW2 for UTM) |
| Start compose stacks locally with dummy secrets | `just test-compose [--amd64] <stack>...` |
| Create encrypted SOPS stubs for a stack | `just secrets <stack>` |
| Garbage-collect | `just clean [host \| builder]` |

Evaluate a single host instead of the whole flake (the fastest check after editing one host or module):

```bash
nix eval .#nixosConfigurations.<nitro5|nitro5-vm|rpi3|hetzner>.config.system.build.toplevel.drvPath
nix eval .#darwinConfigurations.macmini.config.system.build.toplevel.drvPath
```

Things that fail in non-obvious ways:

- `nix flake check` does not evaluate `darwinConfigurations`. `just check` adds the `macmini` evaluation; running the bare flake check after a Darwin change proves nothing.
- `nix flake check` also fails on unformatted Nix (`nixfmt` check) and on shellcheck warnings. Run `just fmt` before `just check`.
- Flakes only see files tracked by git. A new, un-added file produces "file not found" errors at evaluation time.
- The shellcheck file list is written out twice, in `Justfile` (`lint`) and in `flake.nix` (`checks.shellcheck`). A new script without a `.sh` extension (like `gen-passphrase`, `rbw-menu`) must be added to both.
- Lua in `configs/nvim/` is formatted with `stylua configs/nvim/`; it is not part of `just fmt`.

## Architecture

### Flake composition

`flake.nix` defines every host. Two helpers carry the shared wiring:

- `mkNixosHost` builds a NixOS host from `hosts/<hostname>/default.nix` plus the modules every NixOS host gets: `modules/shared/common.nix`, `modules/shared/cli-tools.nix`, `modules/nixos/common.nix`, sops-nix and Home Manager. Host-specific additions go in `extraModules`.
- `hmModule` is the Home Manager wiring applied to every host (NixOS and Darwin), pointing the user at `modules/shared/home.nix`.

`macmini` does not use `mkNixosHost`; its module list is spelled out under `darwinConfigurations`, so a new shared module has to be added in both places.

Module tiers:

- `modules/shared/cli-tools.nix` is installed on every host, servers included. `modules/shared/cli-dev.nix` holds development toolchains and is only added to the workstations (`macmini`, `nitro5`, `nitro5-vm`).
- `modules/darwin/` and `modules/nixos/` hold the OS-specific system layers.
- On Linux workstations the desktop is split in two: `modules/nixos/desktop.nix` holds what any desktop needs whatever the window manager (Kitty, fonts, GUI apps, the polkit agent); `modules/nixos/i3.nix` holds only the i3 session (the eww bar and dock in `configs/eww`, rofi, picom, dunst, lock screen, screenshots). Keys for both OSes are in `configs/design/KEYMAP.md`, the look in `configs/design/THEME.md`.

`nitro5-vm` reuses `hosts/nitro5/` with the NVIDIA module dropped and the disk and initrd forced to virtio. It exists so Nitro 5 changes can be build-checked from the Mac.

### The `~/dotfiles` path

`~/dotfiles` is a symlink to this repository, and two things depend on that exact path:

- `modules/shared/home.nix` links dotfiles with `mkOutOfStoreSymlink` to `~/dotfiles/configs/...`, so edits under `configs/` are live without a rebuild. Only adding or removing a link needs a rebuild.
- Scripts read the flake from `DOTFILES_FLAKE`, which defaults to `~/dotfiles` (`scripts/lib/common.sh`).

Zsh is enabled through Home Manager, which only sources `configs/zsh/.zshrc` and `.zprofile`; aliases and keybindings are split into `configs/zsh/{shared,macos,linux}/`.

### Services and where containers are defined

Containers are defined in two different ways depending on the host:

- Compose stacks live in `services/`, a git submodule (`../services.git`, branch `dev`). Changes there are commits in that repository, not this one. Its `.sops.yaml` (`services/.sops.yaml`) lists the admin and host age keys; this repo has no root `.sops.yaml`.
- `rpi3` declares its containers in Nix (`hosts/rpi3/services.nix`), with secrets from `hosts/rpi3/secrets.sops.yaml` decrypted by sops-nix using the host SSH key.

Scripts resolve a stack name through `find_service_dir` in `scripts/lib/common.sh`, searching in order: `SERVICES_DIR`, the `services/` submodule, a sibling `../services` checkout, then `../../private/private-services`. A stack can therefore come from the private repo without being present here.

### Deploy flow

`scripts/deploy.sh <flake-host> [target-ssh] [mode]` does up to two things: a NixOS rebuild and a compose sync.

- Where the system is built is chosen automatically. When the target has the same CPU architecture as the Mac (`rpi3`), the build runs in the local `nix-builder` container (`scripts/lib/builder.sh`) and only the missing store paths are copied, then the system is activated over SSH. Otherwise (`hetzner`, `nitro5`) it runs `nixos-rebuild --build-host` on the target.
- `--svc` with no stack names rsyncs the whole first services root to `~/services/` on the host without `--delete` and does not start anything. With names, each stack is synced and restarted. Decrypted files under `secrets/` are never copied; only `*.sops.yaml`.

Hosts are SSH aliases from `configs/ssh/config`, which is why `just deploy rpi3` needs no user, port or address.

### Reference material

- `docs/` holds the inventories that must track network and service changes (`service_allocation.md`, `infrastructure_inventory.md`, `network_ip_ranges.md`, `network_topology.md`) and the provisioning runbooks.
- `ORDEM.md` says what is being worked on now and in which order; read it first. `TODO.md` holds the detail of each item, `reminders.md` what depends on a place or moment, and `agent_logs.md` is the handoff log for significant sessions.
- `scratch/` is gitignored; `scratch/handoffs/` holds background for work in progress.

## Delegating to Antigravity (AGY)

The `cc-antigravity-plugin` sends work to the Antigravity CLI (`agy`, Gemini) through its bridge. Its purpose here is to save Anthropic credits on reading-heavy work and to use Gemini's larger context window. This section overrides the "delegate all coding" policy the plugin injects at session start.

When to use which:

1. **Claude directly**: the material to read is under 100 KB and under 20 files, or the task needs judgment (Nix modules, deploy, secrets, design decisions). Final review of AGY's output is always Claude's.
2. **AGY**: the task must read more than 100 KB, more than 20 files, or a single file over 50 KB (whole-repo sweeps, large logs, many similar files), or it is bulk mechanical generation or front-end work.
3. **Fresh Claude subagent** (`AGENTS.md` §18): after two failed AGY runs (error, quota, wrong or contradictory output). Brief it with what AGY found. Use `sonnet` unless the problem needs `opus`.

How to call it:

- Analysis and review: `--read-only --model gemini-4-argon-high`. A Gemini model is pinned on purpose, because the value of a second opinion comes from a different model family. When Gemini disagrees with an earlier Claude analysis, report the disagreement instead of reconciling it.
- Writing files: `--sandbox --mode accept-edits --model gemini-3.8-flash-high`, plus `--parallel` for independent front-end parts. The bridge still forwards `--dangerously-skip-permissions` in this mode. The sandbox blocks terminal writes (tested 2026-10-20: `touch` inside and outside the workspace were refused) but not the network, so edits only land through AGY's file tools.
- Ask for `file:line` with every claim, and spot-check the cited lines before relying on them.
- `private-services`: ask the user before every run that would read it, because its content goes to Google. Never pass decrypted files, `~/.ssh` or age keys, with `--files`, `--dirs` or `--add-dir`.
- After a writing run, read `git diff`, `git add` any new file (flakes ignore untracked files) and run the usual checks (`just fmt`, `just check`, `nix eval` for the touched host). AGY never commits or deploys.

`GEMINI.md` holds the rules AGY itself follows; AGY reads it and `AGENTS.md`, not this file directly. Keep `AGENTS.md` under AGY's 24 KB per-file rule limit. The safety keys in `~/.gemini/antigravity-cli/settings.json` (`proceed-in-sandbox`, terminal sandbox, no non-workspace access) are enforced by `home.activation.antigravitySafety` in `modules/shared/home.nix`, and the skills list comes from `configs/antigravity/skills.json`.
