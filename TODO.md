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
- [ ] **sops-nix no rpi3**: declarar `sops.secrets` para `/var/lib/pihole/secrets.env` e `/var/lib/cloudflared/token.env` (hoje criados à mão).
- [ ] **Fixar tags de imagem no rpi3** (`pihole:latest`, `cloudflared:latest`, Home Assistant `:stable`).
- [ ] **Deploy keys**: `ForwardAgent` foi desligado em `configs/ssh/config`; cadastrar a chave de cada servidor no GitHub (Settings → Deploy keys) para `dotfiles`, `services` e `services-private`.
- [ ] **Homebrew (fazer DEPOIS do update dos hosts)**:
  - `onActivation.upgrade = false`: o `darwin-rebuild` para de atualizar todos os brews/casks a cada execução; atualizar manualmente com `brew upgrade`.
  - `cleanup = "uninstall"`: antes de ligar, declarar em `modules/darwin/homebrew.nix` o que quiser manter. Hoje seriam removidos — brews: `transmission-cli`, `tree`, `wireguard-tools`, `pkgconf`; casks: `clash-verge-rev`, `crossover`, `eigent`, `lulu`, `mounty`, `phantom-wg-mac`, `whatsapp`.
- [ ] **`nixfmt`**: formatar a árvore inteira em um commit isolado e então adicionar `nixfmt --check` aos `checks` do flake.
- [ ] **Backup do rpi3**: `rclone-backup` ainda sincroniza `/etc/nixos` e não define `--config`.
- [ ] **Sessões `screen` no Mac**: encerrar `update` e `rpi` quando o deploy do rpi3 terminar (`screen -S <nome> -X quit`) e apagar `~/screenlog.0`.
- [ ] **Token do `gh` em texto puro**: o login feito via SSH gravou o token em `~/.config/gh/hosts.yml` (o Keychain do macOS não fica acessível numa sessão SSH). Depois de recriar o repositório: refazer o login na sessão gráfica do Mac (`gh auth logout && gh auth login`, que usa o Keychain) e não manter o escopo `delete_repo`.
