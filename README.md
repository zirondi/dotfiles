# ❄️ Dotfiles & Infrastructure Monorepo

[![Nix Flake Check](https://img.shields.io/badge/nix-flakes-blue.svg?logo=nixos&logoColor=white)](flake.nix)
[![Architecture: Multi-OS](https://img.shields.io/badge/arch-Darwin_%7C_NixOS-success.svg)](#hosts--hardware-targets)
[![Home Manager](https://img.shields.io/badge/dotfiles-Home_Manager-purple.svg)](modules/shared/home.nix)
[![Secrets: SOPS + Age](https://img.shields.io/badge/secrets-SOPS_%2B_Age-orange.svg)](#secrets--security)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A unified, declarative system monorepo managing personal workstations, cloud servers, edge nodes, dotfiles, and containerized services across **macOS** and **NixOS**.

---

## 🏛️ Architecture Overview

```
                                  ┌────────────────────────┐
                                  │       flake.nix        │
                                  └───────────┬────────────┘
                                              │
                      ┌───────────────────────┼───────────────────────┐
                      ▼                       ▼                       ▼
            ┌───────────────────┐   ┌───────────────────┐   ┌───────────────────┐
            │   modules/shared  │   │  modules/darwin   │   │   modules/nixos   │
            │   (Common, Home,  │   │   (nix-darwin,    │   │  (Podman, Audio,  │
            │     CLI tools)    │   │  Ollama, Brew)    │   │    Keyd, Polkit)  │
            └─────────┬─────────┘   └─────────┬─────────┘   └─────────┬─────────┘
                      │                       │                       │
                      └───────────────────────┼───────────────────────┘
                                              │
                      ┌───────────────────────┴───────────────────────┐
                      ▼                                               ▼
         ┌─────────────────────────┐                     ┌─────────────────────────┐
         │      Workstations       │                     │    Servers & Routing    │
         │  macmini (Apple Silicon)│                     │  hetzner (Cloud VPS)    │
         │  nitro5  (NixOS + i3)   │                     │  rpi3    (Edge / HA)    │
         └─────────────────────────┘                     └─────────────────────────┘
```

### Core Design Principles

1. **Declarative & Reproducible**: Entire operating system states, kernel parameters, firewall rules, and desktop environments are version-controlled via **Nix Flakes**.
2. **Instant Dotfile Feedback**: Dotfiles in `configs/` are linked using Home Manager's `config.lib.file.mkOutOfStoreSymlink`. Edits made in this repository take effect immediately without requiring a `nixos-rebuild` or `darwin-rebuild`.
3. **Cross-OS Parity**: Keybindings, terminal aesthetics (Kitty), shell ergonomics (Zsh, Starship, Zoxide), and developer workflows mirror each other identically across macOS and Linux.
4. **Zero-Trust Network**: Remote compute and workstations communicate securely across a flat **Tailscale Mesh VPN**; public services are exposed safely via **Cloudflare Tunnels**.
5. **Decoupled Container Stacks**: Production applications and docker/podman compose services live in dedicated orchestrator repositories (`public/services` and `private/private-services`), integrated cleanly via Git submodules.

---

## 💻 Hosts & Hardware Targets

| Host | Architecture | OS Layer | Role / Highlights |
| :--- | :--- | :--- | :--- |
| **`macmini`** | `aarch64-darwin` | macOS + `nix-darwin` | Workstation, Local LLM inference (Ollama), Homebrew, Touch ID SSH |
| **`nitro5`** | `x86_64-linux` | NixOS 26.05 + i3 | Laptop Workstation, NVIDIA Prime offload, ABNT2 layout, Polkit Agent |
| **`hetzner`** | `x86_64-linux` | NixOS 26.05 | Cloud VPS (Helsinki), Disko automated partitioning, Edge proxy |
| **`rpi3`** | `aarch64-linux` | NixOS 26.05 | Low-power Edge Gateway, Pi-hole (DNS), Tailscale Subnet Router |

---

## 📂 Repository Layout

```
.
├── flake.nix                  # Central flake outputs and host definitions
├── Justfile                   # Command runner wrapping scripts/ (`just --list`)
├── AGENTS.md                  # Behavioral rules & guidelines for AI assistants
├── TODO.md                    # Active roadmap, backlog, and commit staging
├── agent_logs.md              # AI agent session handoff changelog
│
├── hosts/                     # Machine-specific hardware configurations
│   ├── macmini/               # Apple Silicon M1 configuration
│   ├── nitro5/                # Acer Nitro 5 (i3, NVIDIA bus IDs, hardware template)
│   ├── hetzner/               # Cloud VPS host with disko disk configuration
│   └── rpi3/                  # Raspberry Pi 3 configuration and edge services
│
├── modules/                   # Reusable Nix modules
│   ├── shared/                # Common configs: cli-tools.nix, cli-dev.nix, common.nix, home.nix
│   ├── darwin/                # macOS-specific: homebrew, keyboard, ollama, podman
│   └── nixos/                 # Linux-specific: common, podman, keyd, pipewire audio
│
├── configs/                   # Physical user dotfiles (symlinked via Home Manager)
│   ├── zsh/                   # Modular ZSH setup (shared/, macos/, linux/)
│   ├── kitty/                 # Modern terminal emulator configs & SSH kitten
│   ├── nvim/                  # Neovim IDE configuration (LazyVim)
│   ├── ssh/                   # Single source of truth for remote host aliases
│   ├── agents/                # AI Agent skill lockfile (.skill-lock.json via skills.sh)
│   ├── clash-party/           # Mihomo / Clash Party proxy rules & crypt.sh
│   ├── git/                   # Git user configuration, templates, and ignore rules
│   └── starship/              # Minimalist cross-shell prompt configuration
│
├── scripts/                   # System automation, deployment, and testing tools
│   ├── lib/common.sh          # Shared helpers (service lookup, DOTFILES_FLAKE)
│   ├── deploy.sh              # Single-command host sync & service deployment
│   ├── update.sh              # Flake lock updater and remote host switcher
│   ├── clean.sh               # Garbage collection and Nix store optimizer
│   ├── test-compose.sh        # Local Docker/Podman compose sandbox runner
│   ├── sync-skills.sh         # Global AI Agent skills synchronizer (skills.sh)
│   └── setup.sh               # Fresh machine bootstrap installer
│
└── docs/                      # Architectural specs, networking, and runbooks
    ├── network_topology.md    # Mermaid diagram of Tailscale mesh & routing
    ├── network_ip_ranges.md   # IPAM conventions (LAN, Tailscale CGNAT, containers)
    ├── infrastructure_inventory.md # Domains, hardware nodes, compute resources
    ├── service_allocation.md  # Workload distribution strategy
    ├── nixos_anywhere_guide.md# Guide for provisioning bare-metal VPS via RAM kexec
    └── host-management.md     # Runbook for enrolling new macOS/NixOS nodes
```

---

## 🚀 Quick Start

### 1. Evaluating Configurations
Verify that all system configurations evaluate and that the scripts pass `shellcheck`:
```bash
just check          # or: nix flake check
```
The same checks run on every push via GitHub Actions (`.github/workflows/check.yml`).

### 2. Applying Configurations Locally
```bash
# On macOS:
darwin-rebuild switch --flake .#macmini

# On NixOS:
sudo nixos-rebuild switch --flake .#nitro5
```

### 3. Deploying to Remote Hosts
Deploy Nix configurations and update container stacks remotely from your workstation:
```bash
# Deploy full system + copy every stack of the services submodule (nothing remote is deleted):
./scripts/deploy.sh hetzner

# Deploy NixOS system configuration only:
./scripts/deploy.sh hetzner --nix

# Deploy specific container services:
./scripts/deploy.sh hetzner --svc socket-proxy traefik
```

### 4. Synchronizing AI Agent Skills
Skills are managed declaratively using [skills.sh](https://skills.sh):
```bash
# Sync all global skills defined in configs/agents/.skill-lock.json:
./scripts/sync-skills.sh
# (or use the shell alias: sync-skills)
```

---

## 🔐 Secrets & Security

- **Age & SOPS**: Sensitive credentials, tokens, and keys are encrypted at rest using [sops-nix](https://github.com/Mic92/sops-nix) with `age` encryption keys.
- **Hardware Integration**: Target hosts decrypt their runtime secrets natively from their SSH host keys via `ssh-to-age`.
- **Zero Plain-Text Policy**: All unencrypted `.env` and raw credential files are strictly gitignored. Stubs are initialized via `./scripts/init-secrets.sh <service>`.

---

## 📚 Documentation & Guides

Explore the `docs/` directory for detailed references:
- 🗺️ **[Network Topology](docs/network_topology.md)**: Visual breakdown of the Tailscale mesh and Cloudflare proxy flow.
- 🌐 **[IPAM & Address Ranges](docs/network_ip_ranges.md)**: Reserved ranges for LAN, Tailscale, and containers.
- 📦 **[Service Allocation](docs/service_allocation.md)**: Workload placement criteria across cloud and local nodes.
- ⚡ **[NixOS Anywhere Guide](docs/nixos_anywhere_guide.md)**: Remote cloud installation without ISOs or KVM consoles.
- 🛡️ **[Cloudflare Routing Guide](docs/cloudflare_routing_guide.md)**: Tunnel ingress configuration through the Raspberry Pi.
- 🤝 **[Contributing & Testing](docs/contributing.md)**: Code formatting, syntax validation, and testing conventions.
