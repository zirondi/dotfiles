## 🚀 Backlog Futuro

### Scripts & Automação
- [x] **`just` (`Justfile`)**: receitas `check`, `lint`, `fmt`, `switch`, `deploy`, `update`, `clean`, `secrets`, `test-compose` e `vm-test` encapsulam os scripts de `scripts/` (`just --list`).

### Linux Environments (NixOS)
- [ ] **Flashy Sudo Prompt**: Implementar `SUDO_ASKPASS` pareado com `zenity` ou `rofi` para comandos de terminal que exigem sudo dispararem alertas visuais na interface gráfica do i3.

### Infrastructure & Networking
- [ ] **Nested Wildcard SSL Certs (`*.*.leazirondi.com.br`)**:
  - Migrar para suporte a subdomínios em múltiplos níveis (ex: `service.host.leazirondi.com.br`) via Cloudflare Advanced Certificate Manager ou ACME DNS-01 automatizado no Traefik.

### Ferramentas de Segurança & Boas Práticas
- [ ] **Linters e scanners**:
  - [x] `shellcheck`: roda em `nix flake check`, `just lint` e no GitHub Actions (`.github/workflows/check.yml`).
  - `trivy`: Scanner de segurança para contêineres e imagens Docker/Podman nos repositórios de serviços.
- [ ] **Acesso de Servidores Remotos (Deploy Keys)**:
  - Avaliar chaves SSH dedicadas de deploy (`deploy@hetzner`, `deploy@rpi3`) caso deseje automação de `git pull` apenas-leitura nos nós remotos.

### Pendências da auditoria de 2026-10-06
- [ ] **Deploy do rpi3**: sops-nix (`hosts/rpi3/secrets.sops.yaml`), tags de imagem fixas e ajuste do `rclone-backup` estão prontos no repositório. Aplicar com `./scripts/deploy.sh rpi3 root@rpi3 --nix` (build no Mac, ver AGENTS.md §15) mantendo uma sessão SSH aberta no Pi. Após validar, apagar no Pi os arquivos antigos `/var/lib/pihole/secrets.env` e `/var/lib/cloudflared/token.env`.
- [ ] **Deploy keys**: `ForwardAgent` foi desligado em `configs/ssh/config`; cadastrar a chave de cada servidor no GitHub (Settings → Deploy keys) para `dotfiles`, `services` e `services-private`.
- [x] **Homebrew**: `upgrade`/`autoUpdate` desligados (atualizar com o alias `update-brew`) e `cleanup = "uninstall"` ligado em `modules/darwin/homebrew.nix`; aplicado no macmini em 2026-10-07.
- [ ] **`nixfmt`**: formatar a árvore inteira em um commit isolado e então adicionar `nixfmt --check` aos `checks` do flake.
- [ ] **Sessões `screen` no Mac**: encerrar `update` e `rpi` quando o deploy do rpi3 terminar (`screen -S <nome> -X quit`) e apagar `~/screenlog.0`.
- [ ] **Token do `gh` em texto puro**: o login feito via SSH gravou o token em `~/.config/gh/hosts.yml` (o Keychain do macOS não fica acessível numa sessão SSH). Depois de recriar o repositório: refazer o login na sessão gráfica do Mac (`gh auth logout && gh auth login`, que usa o Keychain) e não manter o escopo `delete_repo`.
