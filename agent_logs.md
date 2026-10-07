# AI Agent Handoff Logs

Este arquivo serve como um registro contínuo ("passagem de bastão") entre diferentes sessões de IA. O objetivo é manter o contexto sobre decisões de arquitetura e modificações recentes antes que elas sejam agrupadas em commits formais pelo usuário.

*Aviso: Este arquivo deve ser limpo periodicamente pelo usuário após realizar commits significativos, mantendo apenas o histórico recente para poupar o consumo de contexto (tokens).*

---

## [2026-10-07] - Builder local para o rpi3, sops-nix no Pi e cleanup do Homebrew

**Contexto:** O deploy do `rpi3` ficou dias compilando no próprio Pi. Causas: (1) o kernel `linux-rpi` vem do `nixos-hardware` (`raspberry-pi-3`) e não existe no `cache.nixos.org`; (2) `scripts/deploy.sh` fixava `--build-host "$TARGET"`. Os dois builds presos no Pi (um órfão de ~55 h) foram encerrados; o Pi segue na geração antiga (26.05, kernel 6.18.34).

**O que foi feito (tudo sem commit):**
1. **Builder em contêiner** (`scripts/lib/builder.sh`, AGENTS.md §15): contêiner `nix-builder` (`nixos/nix:2.35.2`, volume `nix-builder-store`) na Podman machine. O `deploy.sh` avalia no Mac, envia o fecho do `.drv` ao contêiner, constrói lá, copia ao alvo só os caminhos que faltam e ativa (`nix-env --set` + `switch-to-configuration` via `systemd-run`). Flags novas: `--build-on local|target` e `--build-only`. Hosts x86_64 continuam com `nixos-rebuild --build-host`. `just clean builder` limpa a store do builder.
2. **rpi3**: `hosts/rpi3/secrets.sops.yaml` (chaves `pihole_env` e `cloudflared_env`, destinatários: admin + host key do rpi3) consumido via `sops.secrets` em `hosts/rpi3/services.nix`; imagens fixadas nas versões em produção (HA `2026.8.0`, Pi-hole `2026.07.2`, cloudflared `2026.7.3`); `rclone-backup` sem `/etc/nixos` e com `RCLONE_CONFIG` explícito.
3. **Homebrew** (`modules/darwin/homebrew.nix`): `autoUpdate`/`upgrade` desligados (alias `update-brew`), `cleanup = "uninstall"`, tap `ARAS-Workspace/tap` removido, taps `frankea/whisky` e `pear-devs/pear` declarados com `trusted = true` (sem isso o brew recusa os casks e a ativação aborta). Aplicado no macmini.

**Decisões:**
- `nix.linux-builder` do nix-darwin não serve: o Mac usa Determinate Nix (`nix.enable = false`). O builder nativo do Determinate exige login no FlakeHub; descartado.
- O kernel vendor foi mantido (trocar para mainline, que tem cache, é risco de boot num Pi headless).

**Pendências:** ver `TODO.md` (deploy do rpi3 com o builder; cópia e ativação pelo caminho novo ainda não foram exercitadas). A Podman machine foi para 4 GiB.

---

## [2026-10-06] - Auditoria do Monorepo: Correções de Bugs, Hardening SSH, Tooling (just/CI)

**Contexto:** Análise completa do repositório seguida da execução do plano aprovado pelo usuário. Nada foi commitado nem aplicado em nenhum host (sem `darwin-rebuild`/deploy); só arquivos alterados.

**O que foi feito:**
1. **Bugs:**
   - `home.nix` era importado duas vezes no macmini (`flake.nix` + `hosts/macmini/default.nix`), fazendo `~/.zshrc`/`~/.zprofile` darem `source` em dobro. Agora existe um único `hmModule` no `flake.nix` (com `backupFileExtension = "backup"` em TODOS os hosts).
   - `configs/ssh/config`: `IgnoreUnknown UseKeychain` (a opção só existe no OpenSSH da Apple e quebrava o parse no Linux).
   - `scripts/update.sh --input`: sintaxe corrigida (`nix flake update <input> --flake ...`).
   - `scripts/deploy.sh`: o sync global não usa mais `rsync --delete` (apagaria stacks remotas vindas de outros repositórios); modo desconhecido agora é erro; a chave age derivada da host key não é mais gravada em `/tmp` (vai por `SOPS_AGE_KEY` no ambiente do processo root).
   - `scripts/setup.sh`: clone em `/var/lib/dotfiles` e depois movido para `~zirondi/dotfiles` (antes ficava em `/root`, ilegível para o usuário); removidas menções a Oh My Zsh/stow.
   - `scripts/test-compose.sh`: UID do socket Podman via `id -u` (era `501` fixo).
2. **Organização Nix:**
   - `hetzner` passou a usar `mkNixosHost`; `hosts/nitro5/default.nix` perdeu tudo que já vinha dos módulos comuns.
   - Ativações exclusivas do macOS saíram de `modules/shared/home.nix` para `modules/darwin/ollama.nix` e `modules/darwin/homebrew.nix`.
   - `modules/shared/cli-tools.nix` (base, todos os hosts) + novo `modules/shared/cli-dev.nix` (gcc, node, python, just, shellcheck, nixfmt...; só macmini e nitro5).
   - `nixos-hardware` agora segue o `nixpkgs` raiz (um nixpkgs a menos no lock); URL do nix-darwin atualizada.
3. **Segurança (vale no próximo deploy):**
   - `modules/nixos/common.nix`: `PasswordAuthentication = false` e `KbdInteractiveAuthentication = false` em todos os hosts NixOS.
   - Login root por chave a partir de `10.0.0.0/24` ficou só em `nitro5` e `rpi3`; no `hetzner` o root via SSH está desabilitado e a porta 22 saiu do firewall.
4. **Tooling:**
   - `flake.nix`: outputs `formatter`, `devShells.default` e `checks.shellcheck`.
   - `Justfile`, `scripts/lib/common.sh` (`find_service_dir`, `SERVICES_PATH`) e `.github/workflows/check.yml`.
   - `hosts/hetzner`: timer `backup-volumes` (04:00) rodando `scripts/backup-volumes.sh`, só ativo quando existir `~/.config/rclone/rclone.conf`; o script ganhou `BACKUP_REMOTE`/`BACKUP_SOURCE` e `--backup-dir` (versões antigas vão para `<remote>-archive/<data>/`).

**Decisões de Arquitetura:**
- Segredos decriptados continuam `chmod 444`: containers rootless com usuário não-root precisam ler o bind mount.
- O tratamento de `TUNNEL_TOKEN*` no `deploy.sh` foi mantido: `traefik-cloudflared/compose.yml` depende dessas variáveis.
- Não foi adicionado `nixfmt --check` aos checks: a árvore atual não está formatada e o diff seria enorme.

**Pendências / Ações Requeridas pelo Usuário:**
- **Antes de aplicar em `hetzner`/`rpi3`/`nitro5`:** manter uma sessão SSH aberta em paralelo (senha e root deixam de funcionar).
- **Aplicado em 2026-10-07:** `macmini` (`darwin-rebuild switch`) e `hetzner` (`deploy.sh hetzner --nix`) já estão na configuração nova; `deploy.sh hetzner --svc n8n` validou a decriptação via `SOPS_AGE_KEY`. `rpi3` em andamento. O `nitro5` ainda roda Ubuntu (não NixOS), então nada foi aplicado nele.
- Rodar `darwin-rebuild switch --flake ~/dotfiles#macmini` para corrigir o `source` duplicado e instalar `just`/`shellcheck`.
- Novos tópicos (AGENTS.md §13): `just` e `github-actions`.
- **Adendo (2026-10-07):** `ForwardAgent yes` removido de `hetzner` e `rpi3` em `configs/ssh/config` (o `git pull` nos servidores passará a usar deploy keys). `tmux`, `gh` e `git-filter-repo` adicionados aos módulos de CLI; alias `cd` → `z` (zoxide). Automação privada que estava em `scripts/` foi movida para o repositório privado e o histórico público foi reescrito sem ela.
- Itens não executados estão em `TODO.md` ("Pendências da auditoria de 2026-10-06").
- Entradas deste log anteriores a 2026-09-30 foram movidas para `scratch/agent_logs_archive_pre-2026-09-30.md`.

---

## [2026-09-30] - Planejamento e Provisionamento do Vaultwarden (Hetzner)

**Contexto:** Planejamento e estruturação do serviço de gerenciamento de senhas e estratégia de autenticação/identidade na Hetzner VPS.

**Decisões Arquiteturais:**
1. **Identidade / IdP**: Resgatado o rascunho de **Kanidm** (Rust IdP em `scratch/services_drafts/kanidm`). Decidido manter o **Vaultwarden no modelo Standalone** para evitar a fricção de login duplo (OIDC + Master Password) nas extensões de navegadores e aplicativos móveis, reservando o Kanidm para futuros serviços web e controle de acesso fino (Traefik ForwardAuth, n8n, etc.).
2. **Localização de Serviços:** O serviço foi criado diretamente no repositório de serviços externos em `~/repos/github/me/public/services/vaultwarden` conforme solicitado, desacoplado do submodule no dotfiles para permitir testes locais imediatos sem push/pull forçado.

**O que foi feito:**
1. **Compose Manifest:** Criado [compose.yml](file:///Users/zirondi/repos/github/me/public/services/vaultwarden/compose.yml) com hardening (`no-new-privileges=true`), WebSocket na porta 80, timezones da América/São Paulo, rede `edge-network` e labels Traefik para `vault.leazirondi.com.br`.
2. **Segredos (SOPS):** Criado diretório `secrets/` e gerado o stub criptografado [admin_token.sops.yaml](file:///Users/zirondi/repos/github/me/public/services/vaultwarden/secrets/admin_token.sops.yaml) com chaves do admin e do host Hetzner.
3. **Documentação:** Atualizado [docs/service_allocation.md](file:///Users/zirondi/repos/github/me/public/dotfiles/docs/service_allocation.md) registrando a Hetzner VPS como host do cofre.
4. **Gerador de Passphrase Diceware PT-BR:** Criado script Bash [scripts/gen-passphrase](file:///Users/zirondi/repos/github/me/public/dotfiles/scripts/gen-passphrase) integrado ao `$PATH` com a wordlist offline do ThoughtWorks Dadoware (`scripts/wordlists/dadoware-pt.txt`), normalizando acentos para ASCII por padrão para evitar quebras em consoles TTY ou teclados internacionais.

---

## [2026-09-30] - Divisão em 3 Repositórios, Submódulo Git, Licenciamento e Higienização Final

**Contexto:** Conclusão da grande migração do ecossistema de dotfiles e infraestrutura. O monorepo foi desacoplado em 3 repositórios independentes no GitHub (`dotfiles`, `services` e `private-services`) com integração via submódulo Git relativo, commits atômicos padronizados em inglês (Conventional Commits 1.0.0) e assinados criptograficamente via SSH/1Password.

**O que foi feito:**
1. **Estrutura de 3 Repositórios e Submódulo Git:**
   - `public/dotfiles` (branch `main`): Monorepo principal contendo Nix Flakes, nix-darwin, NixOS, Home Manager, dotfiles e scripts de automação.
   - `public/services` (branch `dev`): Orquestrador público de contêineres Docker/Podman Compose. Adicionado como submódulo em `dotfiles/services` utilizando URL relativa (`../services.git`) apontando para a branch `dev`, permitindo compatibilidade universal de clonagem (HTTPS anônimo para o público/estudantes e SSH autenticado para o autor).
   - `private/private-services` (branch `dev`): Orquestrador privado para automações e serviços sensíveis. Mantido desacoplado do submódulo Git público e resolvido dinamicamente pelos scripts locais via `find_service_dir`.
2. **Saneamento de Serviços Ativos na VPS Helsinki:**
   - Auditado o histórico de comandos e estado em execução no servidor de produção `helsinki`.
   - Mantidas no repositório público exclusivamente as stacks ativas em produção: `socket-proxy`, `traefik-cloudflared` (túneis duplos com Cloudflare Zero Trust) e `n8n`.
   - 15 stacks não utilizadas ou rascunhos foram arquivados com segurança em `scratch/services_drafts/`.
3. **Licenciamento Estratégico:**
   - Criado [LICENSE](file:///Users/zirondi/repos/github/me/public/dotfiles/LICENSE) com licença **MIT** nos repositórios públicos (`dotfiles` e `services`), permitindo uso livre pela comunidade e acadêmicos.
   - Criado `LICENSE` **Proprietary & Confidential** (Copyright 2026 Leandro Zirondi) no `private-services`, garantindo proteção jurídica total a soluções e algoritmos proprietários (como `insta-monitor`).
4. **Governança de Commits & Assinatura Criptográfica:**
   - Adotado o padrão Conventional Commits 1.0.0 em inglês, sem emojis, para alcançar público internacional e manter histórico limpo.
   - Atualizado o template [configs/git/template](file:///Users/zirondi/repos/github/me/public/dotfiles/configs/git/template) para formato bilíngue (EN/PT) com avisos de escopo e tópicos.
   - Todos os commits foram executados diretamente pelo usuário em seu shell autenticado para garantir assinatura criptográfica SSH (`key::ssh-ed25519 ...`) integrada ao 1Password / Touch ID, obtendo o selo "Verified" no GitHub.
5. **Governança de Agentes (`AGENTS.md`):**
   - **Regra 12 (Local Scratchpad & AI Drafts):** Instituído o diretório gitignored `scratch/` para rascunhos, planos e passagens de contexto inter-agentes sem poluir o histórico Git.
   - **Regra 13 (Topic & Scope Drift Awareness):** Obrigatoriedade de alertar o usuário e atualizar os tópicos do GitHub sempre que novas tecnologias centrais forem introduzidas.
6. **Higienização de Documentação:**
   - Removido `docs/guia_de_transicao.md` após conclusão bem-sucedida de todas as fases da migração.
   - Relocado `guia-ghcr-submodules.md` para [private-services/docs/guia_ghcr_submodules.md](file:///Users/zirondi/repos/github/me/private/private-services/docs/guia_ghcr_submodules.md), mantendo o fluxo de registry privado GHCR no repositório correspondente.
   - Atualizados os arquivos [README.md](file:///Users/zirondi/repos/github/me/public/dotfiles/README.md) e [TODO.md](file:///Users/zirondi/repos/github/me/public/dotfiles/TODO.md) marcando o encerramento do roadmap de migração e delineando o backlog futuro (`just`, `SUDO_ASKPASS`, wildcard SSL).
