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
