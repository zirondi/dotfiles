# Agent rules

Binding rules for every agent working in this repository (Claude Code, Antigravity). Commands, architecture and the traps of the flake are in `CLAUDE.md`. Domain terms (host, workstation, server, stack, service, exposure, switch, deploy, sync) are defined in the glossaries listed in `GLOSSARY-MAP.md`; use them as defined.

## 1. Guardrails

1. **Commits and pushes are the user's.** Leave every change in the working tree for the user to review and group into commits; commit or push only when the user asks. A new file gets `git add` at once (flakes ignore untracked files), and stays uncommitted.
2. **Secret values stay out of the conversation.** Everything an agent reads or prints lands in the transcript, so an exposed secret has to be rotated; the user has had to do this more than once.
   - Check a secret by its length, a hash or whether it exists (`wc -c`, `sha256sum`, `test -s`), never by its value: no `sops -d` to stdout, no `cat` of a decrypted file under `secrets/`, no printing environment variables, tokens or key files.
   - Filter logs before reading them: grep for what you need, or mask values (`sed -E 's/(key|token|password|secret)([=: ]+)[^ ]+/\1\2<redacted>/I'`). Known leak: the `ferdium-server` entrypoint logs `App key is <key>` on every start (`rpi3`, `journalctl -u podman-ferdium-server`).
   - When the user must see a value (a generated password, an admin token), hand them the command to run in a terminal of their own, outside the agent (not Claude Code's `!` prefix, whose output enters the conversation).
   - Generate secrets straight into the file that will be encrypted, as `scripts/init-secrets.sh` does, and remove any plain-text copy.
   - If a secret is exposed anyway, say so at once, name it and where it lives, and give the rotation steps.
3. **Switches and deploys run after the user confirms.** Prepare the change, validate it (`just check`, `nix eval` of the host), then offer the exact command; run it only on the user's go-ahead, for every host.
4. **Consult before breaking a rule.** When a request would break cross-OS parity, the separation between shared and specific modules, or any rule in this file, stop and ask the user "Are you sure you want to proceed?" before doing it.
5. **What this repo builds runs without pay-per-use APIs.** AI features use local inference on the Mac mini (M1). The agents the user works with are outside this rule.

## 2. Recording what you learn

- **Each rule lives in the file that owns its subject**, once:
  - this file: rules every agent needs in every session;
  - `CLAUDE.md`: commands, architecture, gotchas, and what only Claude does;
  - `docs/agents/`: the reference for one domain, reached by a pointer from here;
  - `configs/design/`: the desktop (look, keymap, behaviour);
  - `CODING_STANDARDS.md`: what a reviewer checks;
  - `just check`: anything a tool can verify, instead of a written rule.

  The edit that adds a rule also removes or rewrites what it made stale. When a new workflow, infrastructure decision or global shortcut is settled, propose where it goes.
- **Handoff log:** after a complex session or a significant feature, add a short summary of the changes and decisions to `agent_logs.md`, in Portuguese, newest first; the user prunes it after large commits. Open items go to the tracker (`docs/agents/issue-tracker.md`).
- **Private stacks stay out of this public repo.** Everything about a stack of `private-services` (what it does, targets, accounts, decisions, open items) is logged in that repository's `agent_logs.md`, with handoffs in its `docs/`. Here, record only what changes in this repo (a cask, a module), without describing the private stack behind it.

## 3. Cross-OS parity and the desktop

- **macOS is the reference.** macOS behaviour can barely be changed, so macOS defines each shortcut and behaviour and Linux adapts to it. Expect the friction to come from macOS and solve it on the Linux side. `Super` on Linux mirrors `Command` on macOS. Both directions get daily use: the long-term setup is a MacBook Air as the laptop and a NixOS PC as the main machine.
- **One keymap:** `configs/design/KEYMAP.md` is the source of truth for shortcuts on every host. Change it first, then each platform's config.
- **One design system:** the look and behaviour of the desktop (windows, bars, dock, popups, notifications, launcher, lock screen) come from `configs/design/` (its `README.md` lists the rules). Change the spec first, then each platform's configs. A color or size that is not a token in `configs/design/THEME.md` is a gap to report. A change is done when the conformance checklist in `WINDOWS.md` or `SURFACES.md` is filled in for the platform it touched.
- **Modules:** universal settings go in the shared modules, OS- or hardware-specific ones in `modules/darwin/`, `modules/nixos/` or the host. `nix-darwin` holds the macOS system layer; Home Manager holds user dotfiles and CLI tools on every OS. A package in a shared module must build on both `aarch64-darwin` and `x86_64-linux`.
- **Test before bare metal:** a major change to the Linux workstation is build-checked in the `nitro5-vm` configuration (`just vm-test`) before it reaches `nitro5`.

## 4. Infrastructure

- **Tailscale is the backbone** for private traffic between every host. Tunnel exposure goes through `cloudflared`, so no firewall port opens for it.
- **Builds stay off low-powered targets:** `rpi3` (and any host sharing the Mac's architecture) is built on the Mac in the `nix-builder` container; `scripts/deploy.sh` chooses this on its own.
- **Backups** are Restic to Google Drive, one repository per host; state and open steps in `ORDEM.md`.
- **Identity and access:** credentials live in Vaultwarden, and SSH access favours strong controls (YubiKey, Touch ID).
- **Inventories:** a change to the network or to a stack is reflected in the inventories in `docs/` (`service_allocation.md`, `infrastructure_inventory.md`, `network_ip_ranges.md`, `network_topology.md`) in the same change.

## 5. Read before

- **Before creating or changing a stack**, read `docs/agents/compose.md` (exposure, networks, hardening, secrets, the workflow for a new stack).
- **Before touching passwords, SSH keys, the vault or `rbw-menu`**, read `docs/agents/credentials.md`.
- **Before writing a script or reviewing a diff**, read `CODING_STANDARDS.md`.
- **Before naming a domain concept** (in a commit, a `TODO.md` item, a doc), check `GLOSSARY-MAP.md`.

## 6. Scope and topics

The repository's GitHub topics cover its core technologies: `nixos`, `nix-darwin`, `home-manager`, `podman`, `sops-age`, `tailscale`, `i3`, `dotfiles`. When a change brings a new core technology, a new kind of stack, a new host or a new system tool outside these topics:

1. Tell the user explicitly to add that topic on GitHub and in the commit.
2. Reflect the new scope in the semantic commit (`feat(<scope>): ...`) and in the components table of `README.md`.

## 7. Skills

Shared skills live in `~/.agents/skills`. Use them where they apply and your agent has them: `docker-compose-orchestration` for stacks, `nix-best-practices` for flakes and modules, `tailscale` for tailnet connectivity and isolation, `design-doc-mermaid` for Mermaid in Markdown docs.
