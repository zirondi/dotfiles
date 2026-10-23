# Ordem de trabalho

Este arquivo diz **o que vem agora e em que ordem**. O detalhe de cada item fica no `TODO.md`; o que depende de lugar ou momento, no `reminders.md`. Marque `[x]` ao terminar e siga a ordem; quando um item sair do plano, mova-o para "Estacionado" com o motivo.

## Sprint de 23 a 25/10

Decidido com o usuário em 2026-10-23 (inventário de ORDEM, TODO, reminders, agent_logs, handoffs, `private-services`, `lembretes.md` e repositórios da faculdade). Regra: entra o que é pequeno ou médio e não depende de nada pendente; o grande ou bloqueado fica em "Estacionado", com o gatilho para voltar; o velho ou já feito sai dos arquivos. Commits e deploys desta semana: o agente propõe por lote e executa depois do ok do usuário para aquele lote.

Legenda: **[A]** o agente faz sozinho · **[U]** precisa do usuário (navegador, segredo, presença, decisão). Os passos [U] estão no wizard `scratch/wizards/sprint.sh`, rodado num terminal local; o do AliasVault continua em `scratch/wizards/aliasvault.sh`.

### Sexta, 23/10: o agente prepara

Limpeza (nada disso muda os hosts):

- [x] [A] **Contradições e itens velhos** no `TODO.md`, `reminders.md` e `agent_logs.md`: backup "não implementado", guarda-chuva do rpi3, instalação do NixOS no nitro5, Polybar/Plank/`BAT1`, `configs/i3/config` "a criar", pendências velhas dos logs. Referências `AGENTS.md §N` que não existem mais (a regra de segredos agora é §1.2).
- [x] [A] **Handoffs** terminados para `scratch/handoffs/archive/`, depois de passar o que sobra para o `TODO.md`: failback do Vaultwarden (`HANDOFF-backup-failover.md`), itens menores do mail (`HANDOFF-dotfiles-mail.md`) e os dois do RISE para o `rise-aulas`.
- [x] [A] Apagar `scratch/services_drafts/traefik-public/secrets/cloudflare_dns_api_token` (texto puro de um token já rotacionado) e o `~/volumes` do Mac (`n8n`, `snappymail`, `stalwart`, `traefik`: sobras de testes locais, confirmado pelo usuário).
- [x] [A] `services/README.md` atualizado (stacks, hosts, comando de deploy); espelho `~/repos/github/me/public/services` com `git pull --ff-only`.
- [x] [A] Conferir no `hetzner`, só leitura, se Trilium e Calibre-Web estão no ar e anotar (nunca subiram; o alvo é a Oracle).

Mudanças de configuração, validadas com `just check` e `nix eval`, sem deploy:

- [x] [A] **Mail sem a porta 587**: compose do `mail`, firewall do `hetzner` e `MAIL_INTEGRATION.md` (os clientes usam a 465).
- [x] [A] **Tags fixas** no lugar de `:latest` nos stacks de `services/`.
- [x] [A] **Ferdium sem cadastro**: `IS_REGISTRATION_ENABLED = "false"` em `hosts/rpi3/services.nix` (a segunda conta não é mais necessária).
- [x] [A] **Gitea no rpi3** como espelho do GitHub: `services.gitea` nativo com SQLite, só no tailnet em `gitea.rpi3.leazirondi.com.br` pelo Traefik do Pi, no backup do Pi. Script que cria os espelhos (pull mirror) de todos os repositórios pessoais e das orgs pela API, com o token do sábado.
- [x] [A] **Diun** no `hetzner` (avisa versão nova das imagens): stack em `services/diun` a partir de `scratch/services_drafts/diun/`, observando o repositório das imagens com tag fixa, mais o file provider para as imagens do Pi (cloudflared, Pi-hole, Ferdium). Aviso pelo Telegram, com o segredo do sábado.
- [x] [A] **Pi-hole como DHCP**: variáveis `FTLCONF_dhcp_*` prontas em `hosts/rpi3/services.nix` (nomes conferidos na documentação do Pi-hole v6), desligadas até a troca no roteador no sábado.
- [x] [A] **Tunnel do Mac no repo**: `cloudflared` como serviço do launchd no nix-darwin, com o token num arquivo SOPS. O tunnel continua sem rota publicada; a configuração fica pronta para quando houver uma.
- [x] [A] **Backup do Mac** (Restic pelo launchd no nix-darwin): `~/.config/sops`, `~/.ssh`, `~/.oci`, `~/.config/containers`, estado dos agentes de IA (`~/.claude*`, `~/.codex`, `~/.gemini`, `~/.config/opencode`), `~/.sparrow` e `~/UNESP`. Desligado até o `rclone.conf` existir.
- [x] [A] **Pacotes do Mac**: cask `helium-browser` (o app instalado à mão sai antes do switch) e o NotProton (https://github.com/NotProtonNot/NotProton/releases, substituto do Proton na Steam do Mac para usar o CrossOver), pelo Homebrew se houver cask, senão empacotado no Nix.
- [x] [A] **AGY**: correções 1 e 2 feitas (leitura sem terminal, limite do `--files`); a 3 (terminal no sandbox) segue no `TODO.md`.
- [x] [A] **Reescrita do `AGENTS.md`** fechada: o que falta da `scratch/handoffs/spec-agents-rewrite.md` (hook de git, bloco "Agent skills" no `CLAUDE.md`, sonda e rastreio de regras).
- [x] [A] **Consertos pequenos** do `TODO.md` (o clique no ícone do Ferdium no tray ficou para a sessão ao vivo): `just sync` com `-sshargs`, `IdentityFile` do nitro5 no `configs/ssh/config`, sync falhando alto quando pula arquivos, xremap recarregando por `systemd.paths`, ícone duplicado do Bluetooth, clique no ícone do Ferdium no tray, erro do `jq` no `menus.sh` da SketchyBar, receita `just scan`, linhas novas no `CAPABILITIES.md`.
- [x] [A] **Inventário dos segredos** que só existem em disco, como lista para o usuário guardar no sábado (sem ler valores).

Repositórios:

- [x] [A] **`private-services`**: `.gitignore` liberando os `*.sops.yaml`; `insta-monitor` e `ig-warmer` para `archive/` (e o handoff de `~/repos/gitea/private/instagram-watcher` junto); `esaj-watch` e `webtop` prontos esperando os segredos; README atualizado.
- [x] [A] **Faculdade**, só local e sem push: `git init` em `rise-aulas` (a estrutura o usuário organiza à mão; `hetzner-backup-*` e `flags.env` fora do git), commits iniciais dos repos `rise-*` que nunca tiveram commit, modo do `terminal-aula.sh` no `rise-docker-lab`, referências quebradas entre os HANDOFF do `rise-aulas`. `art-styles`: `git init`, repositório privado em `zirondi` e espelho no Gitea. Os quatro arquivos soltos do `trabalhos/analise-empirica-ordenacao` vão para `~/UNESP/26-2/Analise_de_Algos`.
- [x] [A] **Rascunhos**: README do perfil `zirondi` e esqueleto do `curriculum` (o conteúdo vem do XML do Lattes).
- [ ] [A] **Lote 1 de commits** (`dotfiles`, `services`, `private-services`), proposto ao usuário antes.

### Sábado, 24/10: o usuário, com o wizard

Navegador (Chrome ou Helium; o login Google quebra no Zen):

- [ ] [U] **OAuth do Drive**: três clients "Desktop" (`rclone-backup` e `rclone-minecraft` com `drive.file`, `rclone-mount` com `drive`), Drive API ativada, app publicado em produção (em teste o token expira em 7 dias); `rclone config` no Mac com o remote `gdrive`. O wizard grava o `rclone.conf` nos arquivos SOPS dos hosts sem mostrar o conteúdo.
- [ ] [U] **Nextcloud**: contas no Mail (integração do Gmail e da Microsoft com tenant `common`, redirect URIs da tela de Groupware), `.ics` e `.vcf` do Google, 2FA, senha de app do CalDAV no cofre e `vdirsyncer discover` nas duas máquinas; no Android, DAVx5 com o Tailscale ligado. No Ferdium, o serviço Nextcloud no workspace E-mail no lugar das contas separadas.
- [ ] [U] **GitHub**: token fine-grained só de leitura (conteúdo e metadados de todos os repositórios, inclusive das orgs) para os espelhos do Gitea.
- [ ] [U] **Telegram**: bots e grupos com tópicos (`reminders.md`), ids anotados, token do bot no SOPS do Diun e do `esaj-watch`.
- [ ] [U] **Cloudflare**: token do tunnel do Mac para o SOPS; permissão de edição da zona `zirondi.tech` no token de DNS.

Segredos e cofre:

- [ ] [U] Senha do Restic no papel e no cofre; chave age do Mac no cofre e numa cópia offline; chave de API da OCI no cofre; os itens do inventário de sexta.
- [ ] [U] Trocar a senha de VNC do Mac; refazer o login do `gh` na sessão gráfica; teste do `rbw-menu` contra o cofre real (roteiro no fim do `TODO.md`).
- [ ] [U] Segredos do `esaj-watch` (processos) e do `webtop` (chave WireGuard da Proton só para ele, senha pelo `rbw-menu gen`), depois `webtop` no ar no Mac e IP de saída conferido.
- [ ] [U] XML do Lattes exportado para o currículo.

Em casa:

- [ ] [U] **DHCP**: desligar o do roteador quando o do Pi-hole subir (deploy do rpi3 junto); conferir que os clientes recebem `10.0.0.10` como DNS.
- [ ] [U] **AliasVault**: `scratch/wizards/aliasvault.sh` (admin, deploy, tunnel, MX, relay no Stalwart, convite e e-mail de teste).
- [ ] [U+A] **Sessão de desktop ao vivo**, primeiro no nitro5 e depois no Mac: o agente propõe, o usuário decide na tela, o agente aplica. Pauta no `TODO.md`: transparência da dock, rolagem natural, lockscreen, áudio do fone, notificações com botões, Keep Awake, `Caps+B` no i3, limite do aviso do `update-brew`, workspaces do AeroSpace (restaurar, segundo monitor, `just switch` reorganizando janelas), corte do título da SketchyBar, lacunas da spec, conferir o Mac na tela (permissões da SketchyBar e do icalBuddy), Caps como Hyper key, `Super+Shift+3/4` no nitro5, Flashy Sudo Prompt.

### Domingo, 25/10: deploys, verificação e fechamento

- [ ] [A] **Ligar o que esperava segredo**, depois que o wizard de sábado gravou `rclone_conf` e os segredos do Mac: `backup.enable = true` no `hetzner`, no `rpi3` e no `macmini`, `services.cloudflaredTunnel.enable = true` no Mac e `FTLCONF_dhcp_active = "true"` se o usuário estiver em casa; builds conferidos.
- [ ] [U] **Deploy do rpi3** (`just deploy rpi3 --nix`; a ativação pede a senha do sudo): Gitea, DHCP, Ferdium sem cadastro, backup.
- [ ] [A] **Deploys do `hetzner`**, com ok do lote: `--nix` (backup, firewall sem a 587), `--svc mail diun esaj-watch`.
- [ ] [A] **Primeiro backup** nos dois hosts (`systemctl start restic-backups-gdrive`), `restic snapshots` e um restore de teste; Restic do Mac ligado (`just switch`, com ok).
- [ ] [A] **Espelhos do Gitea** criados e conferidos.
- [ ] [U+A] **Mail de ponta a ponta**: enviar do Gmail e para o Gmail; o agente confere SPF, DKIM, DMARC e PTR.
- [ ] [A] **Currículo** a partir do Lattes e README do perfil publicado.
- [ ] [A] **Montar o Drive** com `rclone mount` no Mac e no nitro5 (client `rclone-mount`), se o OAuth de sábado saiu.
- [ ] [A] **Lote final de commits**, `agent_logs.md` e este arquivo atualizados para depois do sprint.

## Estacionado

Cada item volta quando o gatilho acontecer; o detalhe está no `TODO.md`.

- **Kaly42** (Docmost na `public-network`, `*.kaly`, porta 443): prazo de 10–11/10 perdido e o OIDC pode ser recurso pago. Volta quando houver data nova.
- **Oracle**: a VM depende de capacidade (`scripts/oci-launch.sh` no `tmux` `oci` do macmini; comando abaixo) e o Pay As You Go, do cartão. Depois dela: host no flake, NixOS por cima do Ubuntu, segunda cópia dos backups, failover do Vaultwarden e um Stalwart secundário (o failback ainda não foi desenhado).
- **Chaves `sol`, `luna` e `terra`** e chaves SSH servidas pelo `rbw-agent`: trabalho grande; volta depois do inventário dos segredos.
- **Kanidm e OpenBao**: o Kanidm segue desligado (dados em `~/volumes/kanidm` no `hetzner`).
- **Clash Party**: falta o desenho para várias chaves e túneis por programa.
- **Tuya** (lâmpada e tomada que religa o macmini) e o nobreak atrás dela.
- **Projetos do `lembretes.md`** além do perfil e do currículo: `site-base`, site pessoal, site da SECComp.
- **SECComp-Points**: vai virar parte do site novo da SECComp. Até lá fica como está (o commit parado no stage não sobe); quando migrar, guardar o banco e a lista de presença e só então apagar o repositório local.
- **RISE e SECComp no `hetzner`**: para voltarem, os composes trocam `edge-network` por `tunnel-network`. Conteúdo das aulas (checklists do laboratório, NotebookLM, demo de OOM) sem data marcada.
- **Submódulos para `configs/` e `scripts/`**: discussão aberta no `TODO.md`.
- **Minecraft**: kit em `configs/minecraft/`, instalar quando o Debian estiver acessível.
- **Design v2**: animações (ADR novo), rolagem de texto nas barras, IPs no item de rede.
- **AliasVault**: compartilhamento entre contas ainda não existe no self-hosted; retestar quando sair.

## Referência

**rpi3.** Tailnet `100.69.134.71`, anuncia `10.0.0.0/24`. Traefik nativo do NixOS só pelo tailnet (`*.rpi3.leazirondi.com.br`, certificado próprio com o token `traefik_env`); painel reserva do Pi-hole em `http://10.0.0.10:8081/admin`. O DNS interno do Podman fica desligado (disputava a porta 53 com o Pi-hole). Numa instalação nova o usuário nasce sem senha: `ssh root@<host> passwd zirondi`. Apagar o `FERDIUM_APP_KEY.txt` faz o entrypoint gerar outra chave e derruba as sessões dos clientes (saem e entram de novo); o entrypoint escreve a chave no journal a cada início.

**hetzner.** Um deploy `--nix` reinicia o `podman.socket` do usuário, e o provedor Docker do Traefik passa alguns segundos sem resposta (503 do `socket-proxy`); se um stack novo não aparecer no Traefik, reiniciar o `socket-proxy`. À mão, o `podman-compose` precisa de `INSTANCE_HOST=hetzner`, que o `deploy.sh` exporta.

**Backup.** Restic com rclone para o Drive, um repositório por host (`gdrive:backups/<host>`), retenção 7 diários / 4 semanais / 12 mensais, diário às 04:00. Módulo `modules/nixos/backup.nix`; o que cada host copia está em `hosts/<host>/backup.nix`. Sem o `rclone_conf` no SOPS o build falha, por isso o `backup.enable` só volta junto com ele.

**Oracle.** Relançar a busca de capacidade num terminal próprio (não pelo `!` do Claude Code, que encerra o `tmux`):

```sh
tmux new -d -s oci 'NOTIFY_CMD=~/.oci/notify.sh ~/dotfiles/scripts/oci-launch.sh --subnet ocid1.subnet.oc1.sa-saopaulo-1.aaaaaaaaem3nmnzyck4koknn3wxckjtmlq66fl6fasrxlybbazbt6yzj6tca --ssh-key ~/.ssh/main.pub 2>&1 | tee -a ~/.oci/launch.log'
```
