# Contributing & Development Workflow

This repository serves as a unified system monorepo managing multi-OS configurations (macOS via nix-darwin, Linux via NixOS), user dotfiles (Home Manager), and container infrastructure.

## Verification & Testing

Before creating commits or deploying changes, run the validation toolchain:

### 1. Nix Flake Evaluation
Verify that all host configurations evaluate cleanly and that the scripts pass `shellcheck`:
```bash
just check          # nix flake check + macmini evaluation
```
Enter `nix develop` for a shell with `just`, `shellcheck`, `nixfmt`, `statix`, `deadnix` and `sops`.

To evaluate a specific host derivation directly:
```bash
# macOS host:
nix eval .#darwinConfigurations.macmini.config.system.build.toplevel.drvPath

# NixOS hosts:
nix eval .#nixosConfigurations.nitro5.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.hetzner.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.rpi3.config.system.build.toplevel.drvPath
```

### 2. Code Formatting & Linting
- **Nix code**: Format Nix expressions with `nixfmt`:
  ```bash
  nixfmt **/*.nix
  ```
- **Neovim Lua**: Format Lua configs in `configs/nvim/` with `stylua`:
  ```bash
  stylua configs/nvim/
  ```
- **Shell scripts**: Lint with `shellcheck`:
  ```bash
  just lint
  ```

### 3. Container & Compose Testing
To test Docker/Podman Compose services locally without crashing on missing networks or secrets:
```bash
# Test a single stack:
./scripts/test-compose.sh <service-name>

# Test with the full proxy stack:
./scripts/test-compose.sh socket-proxy traefik-public <service-name>
```

## Git Workflow & Conventions

1. **Track New Files**: Whenever creating a new file, run `git add <file>`. Nix Flakes strictly ignores untracked files during evaluation.
2. **Conventional Commits**: Format commit messages logically:
   - `feat(hosts): ...`
   - `feat(modules): ...`
   - `chore(dotfiles): ...`
   - `docs: ...`
3. **No Plain Secrets**: Never commit unencrypted secrets or `.env` files. Encrypt secrets using `sops` and `.sops.yaml`.
