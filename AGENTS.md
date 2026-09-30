# AI Agent Guidelines (NixOS Monorepo)

This repository serves as a unified monorepo managing all Dotfiles, DevOps, Infrastructure, and System configurations for the user's personal ecosystem and academic projects. AI Agents assisting in this repository must strictly adhere to the rules below.

## ⚠️ Core Agent Behaviors
1. **No Automatic Commits**: Do not run `git commit` or automatically commit changes during workflows unless explicitly asked by the user. Modify the necessary files and leave them unstaged/staged for the user to review and group into logical commits themselves. **Important Exception for Nix**: When creating entirely NEW files, you MUST run `git add <file>` to track them, otherwise Nix Flakes will ignore them during evaluation. You still must not commit them.

2. **Rule Enforcement & Consultation**: If the user suggests a change that breaks cross-OS compatibility, breaks logical separation, or contradicts any guideline in this `AGENTS.md`, **STOP and explicitly consult the user** ("Are you sure you want to proceed?").
3. **Continuous Updating**: If a new workflow (e.g., VM testing), infrastructure decision, or global keybinding is established, **proactively suggest appending it to this `AGENTS.md`** file so the context is preserved for future sessions.
4. **Agent Handoff Logging**: Ao finalizar uma sessão de trabalho complexa ou implementar uma funcionalidade significativa, crie um pequeno resumo das mudanças e decisões tomadas no arquivo `agent_logs.md` na raiz do projeto. Isso serve para manter o contexto para futuras sessões de IA. O arquivo será limpo periodicamente pelo usuário após realizar grandes commits.

## 1. Monorepo Architecture & Multi-OS Strategy
- **Shared vs Specific Modularity**: Maintain strict separation of concerns. Universal configurations belong in shared modules (e.g., `shared.nix`, `common.nix`). OS/hardware-specific configurations MUST be isolated in their respective domains (`darwin/` for Mac Mini M1, `nixos/` for Acer Nitro 5 and RPi).
- **Tooling Boundaries**: Use `nix-darwin` for system-level configurations on macOS. Use `home-manager` to manage user-specific dotfiles and CLI tools across all operating systems.
- **Package Management (Fail-Safe)**: Before adding a new Nix package to a common module, verify that it compiles for both `aarch64-darwin` and `x86_64-linux`. Linux-only GUI apps (e.g., `zen-browser`) must strictly reside in Linux-specific modules.
- **VM Testability**: Major architectural changes to the system should be designed to be tested in a local NixOS VM on the Mac before being deployed to bare-metal hardware.

## 2. UX & Keybinding Parity
- **Muscle Memory Consistency**: The UX between macOS and NixOS must be virtually identical. Always map the `Super` key on Linux to mirror the `Command` key on macOS. Modifying ZSH, Kitty, or Window Manager configs must never break this parity.
- **Aesthetics & UI**: Terminal and UI configurations should follow a modern, minimalist "Apple-like" aesthetic (Soft UI / Neumorphism / Glassmorphism). Be careful with strict syntax rules (e.g., hex color parsing in Kitty) when applying themes.

## 3. Infrastructure & Services (Server Layer)
- **Logical Separation**: Maintain logical separation (via VMs, containers, or VLANs) between personal services (Home Assistant, Trilium, Vaultwarden) and academic/public services (CACCo websites, CTF SSH servers).
- **Containerization**: Deploy application services using OCI containers (Docker via `docker-compose` or Podman inside Nix configurations) instead of bare-metal installs when possible.
- **LLMs & AI Costs**: The user runs local inference on their Mac Mini M1. **Do not** suggest implementations that rely on paid APIs (OpenAI, Anthropic). There is a strict no "pay-as-you-use" cost policy.

## 4. Networking, Security & Backups
- **Tailscale (Mesh VPN)**: Tailscale is the backbone for secure, private communication across all nodes (local and cloud).
- **Cloudflare Tunnels**: Use `cloudflared` to expose public-facing services (e.g., academic sites) safely without opening firewall ports to the local network.
- **Identity & Access**: Manage identities via Vaultwarden. Prioritize robust SSH access controls (Yubikey, Apple Touch ID).
- **Monitoring & Backups**: Use Netdata (resources) and Uptime Kuma (status) with Telegram alerts for SSH logins/shutdowns. Critical databases must be backed up via Cron/Rsync to the user's 5TB Google Drive.

## 5. Scripts & Documentation
- **Agnostic Scripts**: Custom maintenance scripts must reside in a dedicated `scripts/` directory, be added to `$PATH`, and dynamically adapt based on arguments (no hardcoded absolute paths).
- **Mermaid.js Safety**: When modifying Mermaid diagrams, you **must** enclose node labels with special characters in quotes (e.g., `id["Label (Extra Info)"]`) to prevent VS Code parse errors.
- **Keep Inventories Updated**: Always ensure changes to network/services are reflected in infrastructure markdown files (e.g., `service_allocation.md`, `infrastructure_inventory.md`, and `ip_ranges.md`).

## 6. AI Agent Skills & Tooling Integration
When assisting in this repository, agents MUST leverage the globally installed skills whenever applicable:
- **UI & Web Development**: Always rely on the `modern-web-guidance` skill when scaffolding or debugging web interfaces (e.g., CACCo websites, internal dashboards) to enforce the required Neumorphism/Glassmorphism aesthetic and modern CSS best practices.
- **Diagrams & Visualizations**: Use the `design-doc-mermaid` skill to guarantee parse-safe Mermaid syntax for static markdown documents. For interactive chat explorations of the network topology, proactively use the `generative_ui` skill to render rich HTML/React widgets instead of plain text.
- **Nix & Docker Configurations**: Consult `nixos-best-practices` and `docker-compose-orchestration` when creating or modifying Nix flakes or container manifests to ensure cross-OS compatibility and optimal container architecture.
- **Networking & VPN**: Rely on the `tailscale` skill when diagnosing connectivity issues or structuring Zero-Trust isolation rules between personal and academic environments.

## 7. Dotfiles Monorepo Specifics (Established in Migration)
- **Instant Feedback (`mkOutOfStoreSymlink`)**: All user configuration files (e.g., Kitty, Neovim, Git, Starship) MUST be symlinked using Home Manager's `config.lib.file.mkOutOfStoreSymlink` pointing to absolute paths in `~/dotfiles/configs/`. This bypasses the read-only Nix store, allowing the user to edit configs in the repo and see changes instantly without running `nix rebuild`.
- **Zsh Management**: We do not use Oh My Zsh. Zsh and its plugins (e.g., autosuggestions, syntax-highlighting) are managed declaratively via Home Manager (`programs.zsh`), but the user's aliases, functions, and pure configs remain in `configs/zsh/` and are loaded via `programs.zsh.initExtra` and `programs.zsh.profileExtra`.
- **Home Manager Safety**: The root `home.nix` must keep `home-manager.backupFileExtension = "backup";` configured to prevent Nix from clobbering existing physical files when instantiating symlinks.

## 8. Kitty & SSH Kitten
- **SSH Kitten Configuration (`remote`)**: When invoking `kitten ssh` with custom configurations, do not use `--kitten=ssh.conf=...`. The correct syntax to load an alternative configuration file is to use the include directive: `kitten ssh --kitten include=ssh_copy.conf`.

## 9. Docker Compose & Podman Orchestration
- **Compose Conventions**: All Docker Compose services must live in `services/<stack-name>/compose.yml`.
- **Hardening Defaults**: Every service must use `security_opt: [no-new-privileges=true]`.
- **Timezones**: Mount `/etc/timezone:ro` and `/etc/localtime:ro` and set `TZ=America/Sao_Paulo`.
- **Secrets**: Use file-based Docker secrets (`./secrets/` mapped to `/run/secrets/`). Never commit plain text `.env` files; they must be encrypted via `sops-nix` or gitignored.
- **Networks**: Traefik-routed services connect to the external `edge-network`. Services needing Docker API access connect to `socket-proxy`.
- **Runtime**: NixOS hosts use Podman Compose (`virtualisation.podman.enable = true`) instead of Docker Desktop/Engine.

## 10. Local Compose Testing & Secret Management
- **Local Testing**: To test `compose.yml` files locally (especially on macOS), agents and the user should use `scripts/test-compose.sh <service-name>`. This script automatically creates necessary networks (`edge-network`, `socket-proxy`), generates dummy secret files to prevent container crashes, and handles Podman/Docker differences.
  - To test with the full proxy stack: `./scripts/test-compose.sh socket-proxy traefik-public <service>`
  - To force `x86_64` emulation on Apple Silicon: `./scripts/test-compose.sh --amd64 <service>`
- **SOPS (sops-nix)**: Secrets are managed using `sops-nix` with `age` keys. The `.sops.yaml` configuration dictates access based on service directories (`services/**/secrets.sops.yaml`). Always encrypt new secrets utilizing the existing `.sops.yaml` structure. Servers use their derived SSH host keys to decrypt natively.

## 11. SSH & Host Parity in Custom Scripts
- **SSH Config as Source of Truth**: Custom maintenance and deployment scripts (`scripts/`) must strictly rely on `configs/ssh/config` as the single source of truth for remote host connectivity (ports, identity files, hostnames, and remote users).
- **No Hardcoded Ports**: Scripts must never hardcode SSH ports (e.g., `-p 42721`) or usernames; let the OpenSSH client resolve options directly from the user's SSH config.
- **Flake Host Defaulting**: Scripts expecting a `<flake-host>` and `<target-ssh>` (e.g., `deploy.sh`, `update.sh`, `clean.sh`) must default `target-ssh` to `<flake-host>` so that commands like `./deploy.sh nitro5` work seamlessly without redundant arguments.

## 12. Local Scratchpad & AI Drafts (`scratch/`)
- **Uncommitted Workspace**: Use the `scratch/` directory (gitignored) for intermediate notes, draft guides, raw LLM conversation summaries, or ephemeral scripts that should not be tracked by Git or pushed to remote repositories.
- **Inter-Agent Context**: Agents can freely read, write, or consult files in `scratch/` to understand user intent, migration stages, or background research across multiple sessions without polluting the repository's commit history.
## 13. Topic & Scope Drift Awareness
- **Sincronização de Tópicos do GitHub**: Os tópicos base deste repositório cobrem as tecnologias centrais (`nixos`, `nix-darwin`, `home-manager`, `podman`, `sops-age`, `tailscale`, `i3`, `dotfiles`).
- **Detecção de Mudança**: Sempre que uma alteração introduzir uma nova tecnologia central, stack de container inédita, novo host ou ferramenta de sistema que divirja dos tópicos atuais:
  1. O agente **DEVE** alertar explicitamente o usuário para incluir essa tag/tópico no commit e atualizar os tópicos no GitHub.
  2. O agente deve refletir o novo escopo no commit semântico (ex: `feat(<novo-escopo>): ...`) e na tabela de componentes do `README.md`.
