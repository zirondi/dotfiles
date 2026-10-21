# Host Management

This guide outlines the process for adding a new machine (host) to this system monorepo.

## Adding a New NixOS Host

1. Boot the new machine using a NixOS live USB or provision remotely via `nixos-anywhere` (see [nixos_anywhere_guide.md](nixos_anywhere_guide.md)).
2. Generate the hardware configuration for the new hardware:
   ```bash
   nixos-generate-config --dir /tmp/new-host
   ```
3. Copy `/tmp/new-host/hardware-configuration.nix` into this repository under `hosts/<new-hostname>/`.
4. Create `hosts/<new-hostname>/default.nix` and define the new host in the root `flake.nix` file under the `nixosConfigurations` output.
5. Track the new files in Git (`git add hosts/<new-hostname>`) and apply the configuration:
   ```bash
   # Local rebuild on the machine:
   sudo nixos-rebuild switch --flake .#<new-hostname>

   # Or remote deployment from your workstation:
   ./scripts/deploy.sh <new-hostname> --nix
   ```

## Adding a New macOS Host (nix-darwin)

1. Ensure the Nix package manager and `nix-darwin` are installed on the Mac.
2. Create a host-specific module under `hosts/<new-hostname>/default.nix`.
3. Define the new host in the root `flake.nix` file under the `darwinConfigurations` output.
4. Apply the configuration:
   ```bash
   darwin-rebuild switch --flake .#<new-hostname>
   ```

## Syncing Work Between Workstations

`just sync <host>` (`scripts/sync-dotfiles.sh`) syncs this repository in both directions with another workstation over SSH, so uncommitted work moves with you without going through GitHub. It runs from either side: `just sync nitro5` on the Mac and `just sync macmini` on the notebook do the same thing.

- **Same unison version on both ends.** Unison's protocol and archive format change between releases, so both machines must run the same version. It comes from `modules/shared/cli-dev.nix` and the shared nixpkgs pin; never override or pin it on one host only. The script compares `unison -version` on both ends and stops on a mismatch: rebuild the older host first.
- **Run it when switching machines**, not continuously. A `.git` directory changing on both sides at once is how any file sync corrupts a repository.
- **Conflicts** (the same file changed on both sides) are skipped in batch mode and listed at the end. Resolve them with `just sync <host> --interactive`.
- **Not synced:** `result*` build links, `.direnv`, `.DS_Store` and decrypted files under any `secrets/` directory. The encrypted `*.sops.yaml` files next to them are synced.
- The repo must sit at the same path relative to `$HOME` on both machines (`repos/github/me/public/dotfiles`, with `~/dotfiles` linking to it). Hosts are aliases from `configs/ssh/config`.
