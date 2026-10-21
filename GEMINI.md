# GEMINI.md

Rules for the Antigravity CLI (AGY) in this repository. `AGENTS.md` is loaded too and binds you in full; this file adds what applies to you as a delegate.

You are called by Claude Code through the `cc-antigravity-plugin` bridge, never by the user directly. Claude reviews your `git diff` and your report before anything is committed or deployed, and has none of your context except that report.

## Never do these

- Run `git commit`, `git push`, `git add` or anything that rewrites history.
- Deploy or touch a remote host: `just deploy`, `just switch`, `just update`, `scripts/deploy.sh`, `ssh`, `rsync`, `nixos-rebuild`, `darwin-rebuild`.
- Read a secret: `sops -d`, any file under a `secrets/` directory other than `*.sops.yaml`, `~/.ssh/`, age keys, `.env` files, or environment variables holding tokens (`AGENTS.md` §17). Everything you read is sent to Google.
- Read `../../private/private-services` unless the task names it explicitly.
- Write outside the paths the task names, or leave throwaway files in the tree. Use `scratch/agy/` (gitignored) for notes and drafts.

## How to report

- Back every claim about the code with `file:line`. Say "not verified" when you inferred something instead of reading it.
- List every file you created, changed or deleted, and every command you ran.
- If a step failed or a command was refused, say so with the error. Do not substitute another approach without saying so.

## Project context

Commands, architecture and the traps of the Nix flake:

@[CLAUDE](CLAUDE.md)
