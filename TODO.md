## 🚀 Backlog Futuro

### Scripts & Automação
- [ ] **Pesquisar e estruturar `just` (`Justfile`)**:
  - Avaliar a adoção do `just` (command runner moderno) para centralizar tarefas do monorepo e substituir a invocação manual de scripts bash (ex: `just deploy nitro5`, `just update`, `just secrets <svc>`), trazendo autocompletion nativo, documentação inline automática (`just --list`) e padronização entre macOS e Linux.

### Linux Environments (NixOS)
- [ ] **Flashy Sudo Prompt**: Implementar `SUDO_ASKPASS` pareado com `zenity` ou `rofi` para comandos de terminal que exigem sudo dispararem alertas visuais na interface gráfica do i3.

### Infrastructure & Networking
- [ ] **Nested Wildcard SSL Certs (`*.*.leazirondi.com.br`)**:
  - Migrar para suporte a subdomínios em múltiplos níveis (ex: `service.host.leazirondi.com.br`) via Cloudflare Advanced Certificate Manager ou ACME DNS-01 automatizado no Traefik.

### Ferramentas de Segurança & Boas Práticas
- [ ] **Linters e scanners**:
  - `shellcheck`: Linter estático para scripts em Bash (`deploy.sh`, `update.sh`, etc.).
  - `trivy`: Scanner de segurança para contêineres e imagens Docker/Podman nos repositórios de serviços.
- [ ] **Acesso de Servidores Remotos (Deploy Keys)**:
  - Avaliar chaves SSH dedicadas de deploy (`deploy@hetzner`, `deploy@rpi3`) caso deseje automação de `git pull` apenas-leitura nos nós remotos.
