# Credentials: the vault, `rbw-menu` and SSH keys

Read this before touching passwords, SSH keys, the vault or `scripts/rbw-menu`. Background: `scratch/handoffs/HANDOFF-rbw-password-menu.md`.

## Direction

- The Vaultwarden vault is the single home for the user's credentials.
- Passwords go through `rbw-menu` today.
- SSH keys are meant to live in the same vault as SSH-key items, served on the workstations (`macmini`, `nitro5`) by `rbw-agent`'s built-in SSH agent, so `ssh`, `git` and the scripts pick them up with no key files on disk. This part is planned, not built: keys still live in `~/.ssh/` and `configs/ssh/config` points at them.
- Servers never hold the vault or run this agent.
- Kanidm (identity) and OpenBao (infrastructure secrets, SSH CA) remain later options. Before introducing any other tool for passwords, SSH keys or secrets, consult the user.

## `rbw-menu`

- **Shortcut:** `Cmd+Ctrl+P` on macOS (Karabiner rule in `configs/karabiner/karabiner.json`) and `Super+Ctrl+P` on Linux open `scripts/rbw-menu` in a dedicated Kitty window. The chord belongs to `rbw-menu` alone.
- **Save before use:** a new password is created through `rbw-menu gen`, which stores the entry and re-reads it from the server before handing the password over. Keep that order: a password reaches the clipboard only after the server confirms it is saved.
- **Account data stays out of the repo:** the vault e-mail is never committed. Per-machine settings are applied with `rbw-menu setup <email> <base-url>`.
