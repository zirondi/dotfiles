# AI Agent Handoff Logs

Este arquivo serve como um registro contínuo ("passagem de bastão") entre diferentes sessões de IA. O objetivo é manter o contexto sobre decisões de arquitetura e modificações recentes antes que elas sejam agrupadas em commits formais pelo usuário.

*Aviso: Este arquivo deve ser limpo periodicamente pelo usuário após realizar commits significativos, mantendo apenas o histórico recente para poupar o consumo de contexto (tokens).*

---

## [2026-10-20] - Política de uso do Antigravity (AGY) e config gerenciada pelo Nix

**O que foi feito:**
1. **Política** (decidida com o usuário) em `CLAUDE.md`, seção "Delegating to Antigravity (AGY)": Claude direto abaixo de 100 KB / 20 arquivos ou quando a tarefa pede julgamento; AGY acima disso (ou um arquivo >50 KB), em geração mecânica e front-end; subagent Claude novo (§18) depois de duas falhas do AGY. Revisão com `--read-only --model gemini-4-argon-high` (segunda opinião de outra família de modelos, divergência reportada e não conciliada); escrita com `--sandbox --mode accept-edits --model gemini-3.8-flash-high`. `private-services` só com confirmação a cada uso, porque o conteúdo vai para o Google. A seção sobrepõe a política "delegar todo código" que o plugin injeta no início da sessão.
2. **`GEMINI.md`** novo, com as regras que o próprio AGY segue (sem commit, deploy ou leitura de segredos; `file:line` em cada afirmação; scratch em `scratch/agy/`), incluindo o `CLAUDE.md` com `@[CLAUDE](CLAUDE.md)`. O AGY lê `AGENTS.md` e `GEMINI.md`, não o `CLAUDE.md`, e corta cada arquivo de regra em 24 KB (o `AGENTS.md` está com 22 KB).
3. **Config do AGY pelo Home Manager** (`modules/shared/home.nix`): `~/.gemini/config/skills.json` vira link para `configs/antigravity/skills.json`. O arquivo antigo apontava para `~/.agent/skills`, que não existe, e por isso o AGY não via as skills compartilhadas. O activation script `antigravitySafety` força `toolPermission = proceed-in-sandbox`, `enableTerminalSandbox = true` e `allowNonWorkspaceAccess = false` no `settings.json`, sem tocar no resto (o AGY reescreve o modelo e os workspaces).
4. **Comportamento verificado:** o bridge só desliga `--dangerously-skip-permissions` em `--read-only` e `--mode auto`. Com `--sandbox`, o terminal do AGY não escreve nem dentro do workspace, mas a rede fica aberta. O `model` do `settings.json` (`Gemini 3.1 Pro (High)`) não existe mais no catálogo; sem `--model`, o AGY caiu no `gemini-4-argon-medium`.
5. **Referência:** os padrões vieram do `squid-protocol/gitgalaxy` (subagent `gemini-analyzer`, `.agents/skills` → `.claude/skills`, sandbox no `settings.json`).

**Pendências:** rodar `just switch` no macmini (e no nitro5, se o AGY for instalado lá) para aplicar o link e as chaves de segurança.

---

## [2026-10-20] - Design system do desktop (`configs/design/`) e conformidade nas duas plataformas

**O que foi feito:**
1. **Design system** em `configs/design/` (inglês), planejado com as skills `grilling`, `domain-modeling`, `prototype` e `writing-for-agents`: `README.md` (5 regras), `GLOSSARY.md`, `THEME.md` (tokens; `THEME.md` e `KEYMAP.md` movidos de `configs/` com as referências atualizadas), `WINDOWS.md` e `SURFACES.md` (com checklists de conformidade), `CAPABILITIES.md` (o que cada plataforma não faz), `decisions/0001-0003` (spec em Markdown e configs à mão, com geração por tokens como saída futura; JankyBorders; sem animação na v1) e `prototype/index.html` (1920×1080, `?variant=linux|macos|states`, seletor de fonte). Regra no `AGENTS.md` §2 ("One Design System") e as skills no §6.
2. **Decisões:** macOS define o comportamento, a spec define o visual; um componente `surface` para popups, menus, notificações, launcher, confirmação e lock; hover branco 8%, selected magenta 35%; raio 10 fora e 6 dentro; texto em **Red Hat Mono** (`redhat-official-fonts` em `modules/shared/home.nix`), ícones em **Hack Nerd Font Propo** (a variante sem sufixo espreme os glyphs); slot de ícone de 18 px; launcher no tamanho do Spotlight (680 px, tokens próprios); só tema escuro.
3. **Fase 3 por dois subagentes** (briefs em `scratch/handoffs/design-phase3-*.md`). macOS: `colors.sh` com nomes de token, popups pelo `lib/popup.sh`, hover na barra, JankyBorders via `services.jankyborders` em `modules/darwin/desktop.nix` (cores lidas do `colors.sh`). Linux: i3 com tokens, sem smart gaps, `focus_follows_mouse no`, gaps medidos (topo 46); picom v13 escrito como texto em `modules/nixos/i3.nix` (o módulo NixOS gera `rules` que o picom 13 rejeita); eww reescrito; confirmação por rofi (`configs/eww/scripts/confirm.sh`, `configs/rofi/confirm.rasi`) para Restart, Shut Down, Log Out e `Cmd+Shift+Q`; calendário com grade própria (`configs/eww/scripts/calendar.sh`) no lugar do GTK; `libnotify` instalado.
4. **Armadilha encontrada:** ferramentas de escrita de agentes descartam glyphs da faixa `U+E000–U+F8FF` (o logo do NixOS, cadeado, power…), deixando strings vazias. Escrever esses glyphs por código (`\uf313` em Python) e conferir a contagem depois de editar.

**Pendências:** em `TODO.md` ("Design system do desktop"). Detalhe e estado em `scratch/handoffs/HANDOFF-design-system.md`.

---

## [2026-10-17] - NixOS no nitro5, keymap e tema unificados entre macOS e Linux

**O que foi feito:**
1. **NixOS no nitro5** por `nixos-anywhere` (Ubuntu apagado): `hosts/nitro5/disk-config.nix` (disko, ESP + LUKS2/ext4, `console.earlySetup` para digitar a senha em ABNT2, zram), `hardware-configuration.nix` gerado na instalação, estado do Tailscale e redes Wi-Fi levados por `--extra-files`. Root por SSH só da LAN e do IP do macmini no tailnet. Kexec pegou outro IP por DHCP; retomado com `--phases disko,install,reboot`.
2. **Keymap único** (`configs/design/KEYMAP.md`, regra no `AGENTS.md` §2): tudo em Cmd; `$mod` = Cmd+Ctrl (Super+Ctrl), Caps Lock como Hyper key (Karabiner / keyd `overload`), Alt↔Super trocados no keyd, xremap traduz Super→Ctrl fora dos terminais. AeroSpace (`modules/darwin/aerospace.nix`) e i3 com o mesmo mapa; mandar para workspace em `$mod+Option` (Cmd+Ctrl+Shift+3/4 são prints do macOS); prints do Mac reproduzidos no Linux.
3. **Bug do keyd:** `ids = ["*"]` pegava o teclado virtual do xremap e cada tecla passava duas vezes (Super virava Alt). Excluído `-1234:5678`.
4. **Barras:** SketchyBar no Mac (Homebrew, para as permissões de TCC ficarem num caminho fixo; `modules/darwin/sketchybar.nix`) e eww no Linux (`configs/eww`, troca o Polybar), com o mesmo layout (`configs/design/THEME.md`): menu de sistema, workspaces, menus do app (helper `pkgs/sketchybar-menus`, título da aba em navegadores), relógio no centro com calendário, mic/câmera em uso (`pkgs/sketchybar-privacy`), mídia, CPU/GPU/RAM, rede, Bluetooth, volume com popup e bateria. Popups com base comum (`configs/sketchybar/lib/popup.sh`). No macOS 27 os ícones nativos não podem mais virar alias (`MenuBarAgent`); `$mod+B` troca para a barra nativa.
5. **Dock:** Dock do Mac na direita (`modules/darwin/desktop.nix`); no Linux uma dock do eww na direita (o i3 só tem área de dock em cima/embaixo; Plank removido, assim como o input `plank-reloaded`).
6. **Desktop Linux** separado em `modules/nixos/desktop.nix` (Kitty, fontes, GTK/Qt escuros, Papirus, Bibata, polkit, sync de calendário) e `modules/nixos/i3.nix` (sessão do i3). Bloqueio com `i3lock-color` + `programs.i3lock` (PAM) e `flock` contra bloqueio duplo; ly como display manager.
7. **Calendário:** `modules/shared/calendar.nix` com vdirsyncer (CalDAV do Nextcloud, credenciais pelo `rbw`, item "Nextcloud CalDAV") e khal; timer de 15 min (systemd / launchd).
8. **Outros:** `scripts/ntfy-send.sh` com níveis e espera (hooks do Claude Code), `scripts/sync-dotfiles.sh` (`just sync <host>`, Unison, mesma versão nos dois lados), NVIDIA sem runtime D3 nessa plataforma (`finegrained = false`), datas em formato brasileiro nas barras.

**Pendências:**
- `sudo nixos-rebuild switch --flake ~/dotfiles#nitro5` no próprio notebook (a LAN do Mac até o Wi-Fi dele falhou; depois disso o deploy funciona pelo tailnet).
- `just switch` no Mac (helpers 1.2, privacy, vdirsyncer, Dock à direita, agente do Guacamole de volta) e dar Acessibilidade ao SketchyBar quando o macOS pedir.
- Calendário: criar a senha de app no Nextcloud, guardar no Vaultwarden como "Nextcloud CalDAV" e rodar `vdirsyncer discover nextcloud_calendars` nas duas máquinas.
- `TODO.md`: modo bateria, Bibata no Mac, Guacamole na raiz e no `private-services`, lista de ferramentas no Trilium.

---

## [2026-10-15] - Nextcloud no `hetzner`

**O que foi feito:**
1. **Stack `services/nextcloud`:** Nextcloud 35 (apache), Postgres 17, Redis 8 e um container de cron. Só pelo tailnet (`nextcloud.hetzner.leazirondi.com.br`), com redirect do `/.well-known/{cal,card}dav` e o `security-headers@file` (HSTS). Segredos `postgres_password` e `admin_password` em SOPS. Testado localmente com `test-compose` e no ar no `hetzner`; apps Mail, Calendar e Contacts instalados, cron em modo `cron`, setup checks limpos.
2. **Swap de 2 GB** no `hetzner` (`hosts/hetzner/default.nix`), aplicado.
3. Inventários, `README.md` e bloco 6 do `ORDEM.md` atualizados.

**Decisões:** imagem clássica e não a AIO (a AIO quer o socket do Docker); sem Kanidm por enquanto (o app `user_oidc` liga depois); o SnappyMail sai quando as contas estiverem no Nextcloud Mail. Pendências no bloco 6 do `ORDEM.md` (contas OAuth, importação, backup com `pg_dump`).

**Observado:** o deploy `--nix` no `hetzner` reinicia o `podman.socket` do usuário e o provedor Docker do Traefik fica alguns segundos com 503.

---

## [2026-10-15] - Cliente Ferdium e receita Discord com Vencord

**O que foi feito:**
1. **Cliente Ferdium:** cask `ferdium` no Mac (`modules/darwin/homebrew.nix`, seção Ferramentas) e pacote `ferdium` no Nitro 5 (`hosts/nitro5/default.nix`). Os dois só valem depois de `just switch` / deploy; o Nitro 5 ainda não está com Nix.
2. **Receitas customizadas:** `configs/ferdium/recipes/`, linkadas como a pasta `recipes/dev` do Ferdium por `modules/shared/ferdium.nix`. O módulo entra só nos workstations (`macmini`, `nitro5`, `nitro5-vm`).
3. **Receita `discord-vencord`:** a receita oficial do Discord mais o Vencord (build de userscript), com cache diário fora do repositório. A injeção pelo `webview.js` chegou tarde no primeiro teste; agora a receita registra um preload na sessão do serviço (`@electron/remote`) e o Vencord entra no início do documento. Testado no Mac: o Vencord carrega.
5. **`ferdium-server` (rpi3):** a loja de receitas dava 500 porque o servidor lê de `/app/build/recipes` e o entrypoint clona em `/app/recipes`. O volume agora é montado nos dois caminhos; falta o deploy.
4. **Thunderbird nativo removido** (cask no Mac): o e-mail passa para o Ferdium, num workspace com um serviço por conta (Gmail, Thundermail, SnappyMail).

**Decisões e pendências:** em `configs/ferdium/HANDOFF-discord-vencord.md` (corrida do Vencord com o webpack, áudio no compartilhamento de tela do Linux, opções de e-mail, workspaces).

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
