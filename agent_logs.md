# AI Agent Handoff Logs

Este arquivo serve como um registro contínuo ("passagem de bastão") entre diferentes sessões de IA. O objetivo é manter o contexto sobre decisões de arquitetura e modificações recentes antes que elas sejam agrupadas em commits formais pelo usuário.

*Aviso: Este arquivo deve ser limpo periodicamente pelo usuário após realizar commits significativos, mantendo apenas o histórico recente para poupar o consumo de contexto (tokens).*

---

## [2026-10-13] - rpi3 na geração nova, Traefik unificado no `hetzner` e `ORDEM.md`

**Contexto:** retomada do backlog. O usuário definiu a ordem de trabalho, registrada em `ORDEM.md` (rpi3, Traefik, Oracle, Kaly42, chaves e cofre).

**O que foi feito:**
1. **rpi3:** o deploy da geração 26.11 deixou Pi-hole e cloudflared parados. Duas causas, corrigidas em `hosts/rpi3/services.nix` e aplicadas: nomes de imagem sem `docker.io/` (o Podman novo não resolve nomes curtos) e falta de `--cap-add=NET_RAW` no Pi-hole (o dnsmasq se recusa a iniciar). DNS validado a partir da LAN.
2. **`initialPassword`** removido de `rpi3` e `nitro5`. Numa instalação nova, definir a senha com `ssh root@<host> passwd zirondi`.
3. **Traefik (submódulo `services`):** stack `traefik-cloudflared` renomeado para `traefik`; redes `cloudflared-network`, `tunnel-network` e `public-network` no lugar de `tunnel` e `edge-network`; entrypoints `web`, `websecure` e `public`, os dois últimos publicados em endereços diferentes do host. `scripts/deploy.sh` exporta `TAILNET_IP` e `PUBLIC_IP`. `mail` e `vaultwarden` vieram do checkout irmão; `dashboard.yml` e `tailnet.yml` saíram; novo stack `whoami` (só tailnet).
4. **Deploy no `hetzner`:** `traefik`, `n8n`, `mail`, `vaultwarden` e `whoami` recriados. Wildcard `*.hetzner.leazirondi.com.br` emitido primeiro na CA de staging e depois na de produção. Nomes públicos (`vault`, `n8n`, `webmail`) respondendo 200 pelo túnel.
5. **Commits:** o trabalho acumulado do `dotfiles` foi dividido em commits assinados com a `main` (formatação com nixfmt separada das mudanças funcionais).

**Decisões:**
- O submódulo `services/` é a única cópia de trabalho; o checkout irmão vira espelho somente leitura (`AGENTS.md` §9).
- Entrypoints separados por endereço em vez de filtro por IP de origem: o piloto confirmou que o Podman rootless entrega ao Traefik o IP da rede do container, não o do cliente.
- Os stacks do RISE e da SECComp foram parados na troca de redes, a pedido do usuário. Voltam quando os composes deles trocarem `edge-network` por `tunnel-network`.
- Kanidm fica desligado até o bloco de identidade.
- Pi-hole continua como DNS e passa a ser também o DHCP da LAN (a configurar em casa).
- `ferdium-server`: a imagem tem build `arm64` e usa cerca de 134 MB parada (medido no Mac); cabe no Pi.

**Depois, na mesma sessão:**
- **rpi3:** Home Assistant removido (lâmpada e tomada são Tuya e serão controladas por script local). O Pi entrou no tailnet como subnet router de `10.0.0.0/24`.
- **`hetzner`:** stacks do RISE e da SECComp removidos por completo, com cópia dos arquivos do servidor em `hetzner-backup-2026-10-13/` no repositório local de cada um (ignorada via `.git/info/exclude`).
- **Oracle:** novo `scripts/oci-launch.sh` e `oci-cli` no `cli-dev.nix`. A VCN criada pelo wizard usava `10.0.0.0/16`, a mesma faixa da LAN de casa; foi movida para `10.20.0.0/16` pela API (as subnets precisaram ser recriadas, a API não aceita trocar a faixa no lugar). O script roda no macmini, na sessão `tmux` `oci`, com `--no-retry`: sem isso a CLI repete sozinha cada pedido recusado por mais de um minuto.
- **Git sem agent:** nesta sessão não havia ssh-agent. Commits foram assinados com `-c user.signingkey=~/.ssh/main` e o push funciona com `GIT_SSH_COMMAND='ssh -i ~/.ssh/main -o IdentitiesOnly=yes'`. O host `github` do `configs/ssh/config` tem a `IdentityFile` comentada e os remotos usam `git@github.com` direto.

**Pendências:** ver `ORDEM.md`. Em resumo: VM da Oracle ainda sem capacidade; Kaly42 não começou (a 443 pública do `hetzner` segue fechada); DHCP no Pi-hole e aparelhos Tuya dependem de estar em casa; limpar o checkout irmão do `services`; trocar a senha de VNC do Mac; permissão do token de DNS na zona `zirondi.tech`.

**Tópicos (AGENTS.md §13):** `traefik` passa a ser peça central (TLS próprio e exposição direta); vale incluir como tópico no GitHub.

---

## [2026-10-09] - Guacamole só no tailnet e macmini voltando sozinho após reinício

**Contexto:** O `mac-remote-access` (em `scratch/services_drafts/`) estava parado porque a VM do Podman não sobrevivia ao login. O usuário quer o Mac acessível mesmo depois de queda de luz.

**O que foi feito:**
1. **Guacamole:** `cloudflared` removido do compose (backup em `compose.yml.cloudflared.bak`); o Guacamole escuta em `127.0.0.1:8080` e é publicado por `tailscale serve --bg 8080` em `https://leandros-mac-mini.tail34d28c.ts.net/guacamole/` (a raiz dá 404).
2. **`modules/darwin/podman.nix`:** `AbandonProcessGroup = true` no agente `podman-machine` (sem isso o launchd mata a VM quando o comando termina) e novo agente `mac-remote-access`, que espera a VM e inicia `mac-ra-guacd` e `mac-ra-guacamole`.
3. **`hosts/macmini/default.nix`:** `power.restartAfterPowerFailure` e `power.sleep.computer = "never"`.
4. **`modules/darwin/homebrew.nix`:** cask `android-commandlinetools` (`sdkmanager` e `avdmanager`; o Java vem do JBR do Android Studio).

**Validado pelo usuário após reboot:** Tailscale, VM do Podman e Guacamole voltam sozinhos. Dependem de login automático e de "VPN On Demand" ligado no app do Tailscale, ambos configurados à mão (fora do Nix).

**Depois, na mesma sessão:**
- **Energia:** testes de tomada mostraram que o macmini só religa sozinho em piscadas. `autorestartatconnect` não é suportado neste aparelho e `pmset schedule poweron` não sobrevive ao corte. Saída: nobreak.

**Pendências:** queda de energia real não foi testada (`shutdown` é desligamento limpo e não religa). Apagar o túnel e o Access antigos na Cloudflare, o `secrets/tunnel_token` local e trocar a senha de VNC. O Wetty continua no compose, sem acesso.

---

## [2026-10-07] - Planejamento do backlog, formatação com nixfmt e preparação do TLS por host

**Contexto:** Sessão de triagem do `TODO.md` com o usuário, item a item. O `TODO.md` ganhou uma seção "Ordem de execução" no topo e o novo `reminders.md` guarda o que depende de lugar ou momento.

**O que foi feito:**
1. **`nixfmt`:** os 22 arquivos `.nix` foram formatados e `checks.nixfmt` entrou no `flake.nix`. As derivações de `nitro5`, `nitro5-vm`, `rpi3`, `hetzner` e `macmini` ficaram idênticas antes e depois; `just check` passa.
2. **TLS por host (sem deploy):** no submódulo `services`, `traefik-cloudflared` ganhou o entrypoint `websecure`, o resolver DNS-01 da Cloudflare (CA de staging), o middleware `tailnet-only`, o secret `cloudflare_dns_api_token` (stub cifrado) e a imagem fixada em `traefik:v3.7`. `scripts/deploy.sh` exporta `INSTANCE_HOST`. O `hetzner` entrou no tailnet (`100.115.88.115`) e o registro `*.hetzner.leazirondi.com.br` foi criado pelo usuário.
3. **`scripts/init-secrets.sh`:** passa `--config` explícito ao `sops` e apaga o stub se a cifragem falhar (antes deixava o texto puro num arquivo `.sops.yaml`).
4. **Plugin da Cloudflare** (skills e MCP) instalado no Claude Code, escopo de usuário.

**Decisões:**
- Deploy keys: não cadastrar; nenhum servidor faz `git pull`.
- `trivy`: sai como item próprio; fica só uma receita `just scan` futura, local.
- Cofre familiar: continuar no Vaultwarden.
- Submódulo `services`: está íntegro e não foi recriado; o repositório recriado foi o `dotfiles`.
- Chaves SSH: `sol` (pessoal, GitHub, assinatura), `luna` (CACCo, SECComp, CTF), `terra` (automações); o Kindle mantém a `kindle_rsa`. Referência nos hosts por `fetchurl` com hash fixo.
- `csp-watcher`: três fontes (relatórios do navegador, cálculo de hashes pelo watcher, navegador headless com sessão) e liberação automática só em janela de aprendizado; fora dela, aprovação pelo Telegram.

- Redes de containers: `tunnel` → `cloudflared-network`, `edge-network` → `tunnel-network`, nova `public-network` para o que for exposto direto na 443. O AGENTS.md (§9, §10, §14) será reescrito junto; aprovado pelo usuário, nada alterado ainda.
- Kaly42: wiki do grupo (Docmost, login próprio) em `*.kaly.leazirondi.com.br`, exposta direto na 443 do `hetzner`, na `public-network`. Um único Traefik com dois entrypoints separados pelo IP de escuta (público e Tailscale). Prazo: fim de semana de 10 e 11/10/2026. O CSP por hashes fica para depois.
- `rbw-agent`: atende só a sessão local do Mac.

**Estado do `hetzner` em 2026-10-07 22h (só leitura):** todos os containers de pé, exceto o Kanidm (loop de reinício; o Traefik acusa a falta do `kanidm-transport@file`). `n8n` e `webmail` respondem 200. O Vaultwarden responde 200 pelo IP `104.21.65.52` da Cloudflare; a partir do macmini o nome resolvia para `188.114.96.5` e a conexão não fechava (problema de rota local, não do servidor). O `/etc/resolv.conf` do servidor passou a usar o DNS do Tailscale.

**Pendências / Ações Requeridas pelo Usuário:**
- Nenhum commit foi feito. O index do `dotfiles` contém só o `rbw-menu`; a ordem dos commits está em `reminders.md`.
- Token da Cloudflare gravado no secret e e-mail ACME confirmado (`acme@leazirondi.com.br`); o piloto do TLS está liberado. O Vaultwarden respondeu normalmente de outra rede.
- Os serviços do `hetzner` ficaram fora do ar durante a sessão (nenhum deploy foi feito por ela). Hipótese não testada: o `tailscale up` assumiu o DNS da máquina.
- `mail` e `vaultwarden` rodam em produção sem commit, no checkout `~/repos/github/me/public/services`.

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

## [2026-10-07] - `rbw-menu`: menu de senhas via rbw + fzf (Mac Mini implementado, Nitro 5 desenhado)

**Contexto:** A extensão do Bitwarden (com o Vaultwarden) sugeriu uma senha que não foi salva. Como não existe extensão alternativa, a extensão saiu do caminho crítico: `rbw generate` gera e grava em uma operação, e o script relê do servidor antes de entregar a senha. Nada foi commitado nem aplicado (`just switch` pendente).

**O que foi feito:**
1. `modules/shared/cli-dev.nix`: `rbw`, `pinentry_mac` (Darwin), `pinentry-curses` e `xclip` (Linux).
2. `scripts/rbw-menu` (novo): menu com fzf (senha, usuário, TOTP, editar), `gen` (gera, salva e confirma) e `setup <email> <url>`.
3. `flake.nix` e `Justfile`: `rbw-menu` no shellcheck.
4. `configs/karabiner/karabiner.json`: `Cmd+Ctrl+P` abre o menu em uma janela do Kitty.
5. `AGENTS.md` seção 15 e `TODO.md` atualizados.

**Decisões:**
- Config híbrida: o e-mail da conta não entra no repo (público); URL e pinentry são aplicados por `rbw-menu setup`.
- Paridade: `Super+Ctrl+P` no Linux, ainda não ligado porque não existe `configs/i3/` no repo.
- `pinentry-curses` no Linux porque o `pinentry-gtk2` foi removido do nixpkgs.
- Direção futura: Kanidm (identidade) e OpenBao (segredos e CA de SSH). O cofre familiar segue em aberto (Psono é o candidato).

**Detalhes, checklist de teste e avaliação completa das alternativas:** `scratch/handoffs/HANDOFF-rbw-password-menu.md`.

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
