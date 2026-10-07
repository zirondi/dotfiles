# Command runner for the monorepo. Run `just` to list every recipe.
# Recipes wrap the scripts in scripts/; hosts are SSH aliases from configs/ssh/config.

flake := justfile_directory()

# List available recipes
default:
    @just --list

# Evaluate all NixOS hosts and run the flake checks (shellcheck)
check:
    nix flake check "{{flake}}"
    nix eval "{{flake}}#darwinConfigurations.macmini.config.system.build.toplevel.drvPath"

# Lint shell scripts
lint:
    cd "{{flake}}/scripts" && shellcheck -x -S warning *.sh lib/*.sh gen-passphrase
    shellcheck -S warning "{{flake}}/configs/clash-party/crypt.sh"

# Format Nix files
fmt:
    cd "{{flake}}" && git ls-files -z '*.nix' | xargs -0 nix fmt --

# Apply the configuration to this machine
switch:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "$(uname)" = "Darwin" ]; then
      sudo darwin-rebuild switch --flake "{{flake}}#macmini"
    else
      sudo nixos-rebuild switch --flake "{{flake}}#$(hostname)"
    fi

# Deploy to a remote host: `just deploy hetzner --nix` or `just deploy hetzner --svc n8n`
deploy host *args:
    "{{flake}}/scripts/deploy.sh" {{host}} {{args}}

# Update flake inputs, then deploy: `just update nitro5` or `just update hetzner --input nixpkgs`
update host *args:
    "{{flake}}/scripts/update.sh" {{host}} {{args}}

# Garbage-collect old generations (locally when no host is given)
clean host="localhost":
    "{{flake}}/scripts/clean.sh" {{host}}

# Create encrypted SOPS stubs for every secret a service declares
secrets service:
    "{{flake}}/scripts/init-secrets.sh" {{service}}

# Start compose stacks locally with dummy secrets: `just test-compose socket-proxy n8n`
test-compose *services:
    "{{flake}}/scripts/test-compose.sh" {{services}}

# Build-check a NixOS host without deploying (defaults to nitro5-vm)
vm-test host="nitro5-vm" *args:
    "{{flake}}/scripts/vm-test.sh" {{host}} {{args}}
