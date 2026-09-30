# Future Enhancements & Backlog

## 📋 Pendências de Commits (Estratégia de 3 Repositórios)
> O plano detalhado de commits passo a passo para os 3 repositórios (`dotfiles`, `services`, `private-services`) está documentado no artefato `plan_monorepo_services_showcase.md`.

- [ ] **1. Repositório `dotfiles` (Público)**:
  - Commit 1: `chore(meta): adiciona documentação base, guias de infra e regras de agentes`
  - Commit 2: `feat(modules): consolida módulos nixos, darwin e shared com suporte a podman e pipewire`
  - Commit 3: `feat(hosts): adiciona configurações de hosts (macmini, nitro5, rpi3, hetzner)`
  - Commit 4: `feat(configs): adiciona dotfiles de usuário (zsh, kitty, nvim, ssh, git, clash-party, agents)`
  - Commit 5: `feat(scripts): adiciona ferramentas de automação, deploy, setup, sync-skills e testes locais`
- [ ] **2. Repositório `services` (Público - Orquestrador)**:
  - Commit inicial: `feat(services): implementa stacks de containers docker/podman compose públicos`
- [ ] **3. Repositório `private-services` (Privado - Orquestrador)**:
  - Commit inicial: `feat(services): implementa orquestrador de serviços privados e submódulos`

---

## 🚀 Backlog Futuro (Pós-Commit)

### Scripts & Automação
- [ ] **Pesquisar e estruturar `just` (`Justfile`)**:
  - Avaliar a adoção do `just` (command runner moderno) para centralizar tarefas do monorepo e substituir a invocação manual de scripts bash (ex: `just deploy nitro5`, `just update`, `just secrets <svc>`), trazendo autocompletion nativo, documentação inline automática (`just --list`) e padronização entre macOS e Linux.

### Linux Environments (NixOS)
- [ ] **Flashy Sudo Prompt**: Implementar `SUDO_ASKPASS` pareado com `zenity` ou `rofi` para comandos de terminal que exigem sudo dispararem alertas visuais na interface gráfica do i3.

### Infrastructure & Networking
- [ ] **Nested Wildcard SSL Certs (`*.*.leazirondi.com.br`)**:
  - Migrar para suporte a subdomínios em múltiplos níveis (ex: `service.host.leazirondi.com.br`) via Cloudflare Advanced Certificate Manager ou ACME DNS-01 automatizado no Traefik.
