# Ordem de trabalho

Este arquivo diz **o que vem agora e em que ordem**. O detalhe de cada item fica no `TODO.md`; o que depende de lugar ou momento, no `reminders.md`. Marque `[x]` ao terminar e siga a ordem; quando um item sair do plano, mova-o para "Estacionado" com o motivo.

Refeito com o usuário em 2026-11-11, depois do sprint de 23 a 25/10 (o que ele fechou está no `agent_logs.md` de 28/10). Legenda: **[A]** o agente faz sozinho · **[U]** precisa do usuário (navegador, segredo, presença, decisão). Os passos [U] estão nos wizards de `scratch/wizards/`, rodados num terminal local: `navegador.sh` (AliasVault primeiro, depois contas e Nextcloud), `ssh.sh` (de longe) e `presencial.sh` (em casa).

## Semana de provas, 11 a 18/11: nada além do urgente

Aula/prova em 12/11, trabalho de Análise de Algoritmos em 17/11, prova de Cálculo 2 (séries e EDO) em 18/11. Até lá, só o que leva minutos:

- [ ] [U] **Oracle: upgrade para Pay As You Go.** A conta ainda é `FREE_TIER` em trial (`upgrade-state` `PROMO`, desde 13/10); o trial de 30 dias acaba por volta de 12/11, e o limite de A1 cai de 41 OCPUs para o Always Free. Fazer o upgrade quando o cartão virar e, junto, um budget com alerta; login e passo a passo em `scratch/handoffs/HANDOFF-oracle.md`. Depois, relançar a busca (comando na Referência, já com 2 OCPUs / 12 GB por padrão).
- [x] [A] **AliasVault 0.31.3 e no backup** (deploy feito em 11/11, com ok: migração aplicada, snapshot com `aliasvault.pgdump`; restore de teste do snapshot conferido no mesmo dia, 39 tabelas): as imagens oficiais já têm o .NET corrigido (0.31.2 com 10.0.14, o fix do Brotli; 0.31.3 com 10.0.15, o patch de novembro), então os builds locais saem (`build-images.sh` guardado em `scratch/services_drafts/`). A 0.31.3 traz uma migração de banco (renomeia tabelas), e o AliasVault não estava no backup do `hetzner`: entra um `pg_dump` em `hosts/hetzner/backup.nix`. Ordem: `pg_dump` à mão, `just deploy hetzner --nix`, `just deploy hetzner --svc aliasvault`, conferir login, um backup novo e `restic snapshots`.

## Bloco 1, a partir de 19/11: o cofre (AliasVault e `deleteme`)

Prioridade decidida em 2026-11-11. O plano é `~/repos/deleteme/README.md`, que trata todo o Vaultwarden como comprometido; a pasta tem dados pessoais e não é versionada nem sincronizada. Três cofres: **AliasVault** principal (logins pessoais e senhas dos servidores), **Vaultwarden** (`rbw`) só com os segredos que os scripts leem, e **Bitwarden cloud** como cópia fria das senhas dos servidores, fora da infra.

- [ ] [U] **`navegador.sh`, estágios 1 a 6**: Fase 0 (Gmails, chip, BC Protege+), AliasVault endurecido (admin, usuário e 2FA novos), extensão e app, importação (`.zip` do Bitwarden; o JSON criptografado fica como backup à parte), conta no Bitwarden cloud e troca das senhas da infra na ordem da seção 6 do `deleteme`.
- [ ] [A] **Segredos que não são senha** (seção 7 do `deleteme`), depois das senhas: chave age nova e `sops updatekeys` nos três repos, com troca dos valores (o histórico do git abre com a chave velha); chaves SSH novas (absorve o item `sol`/`luna`/`terra` do Estacionado, a decidir); `restic key add`/`remove` nos três hosts; client novo do rclone; chave nova da API da OCI.
- [ ] [A] **Cópia fria em dia**: desenhar como o Bitwarden cloud acompanha as trocas (export periódico ou `bw` CLI).
- [ ] [U] **`deleteme`, fases 1 e 2** (descobrir e triagem do `inventario-vaultwarden.csv`), no ritmo do usuário. Terceiros e contas do CACCo e da SECComp (seção 8) vão para os donos.

## Bloco 2: repo em dia

- [ ] [U] **Os dois commits locais** (`70d57a7` modo RISE no nitro5, `835a86f` terminal `aula`), de 04/11: subir no próximo push.
- [ ] [A] **Lotes de commit** (o `just check` passou em 11/11) das mudanças sem commit (Ollama e OpenCode de 05/11, XERJ, `SKILLS.md`, `oci-launch.sh` com 2 OCPUs / 12 GB) e `nix eval` do `macmini`; depois, proposta de lotes de commit.
- [ ] [U] **Testar o OpenCode local** (`just test-llm`; decidido em 2026-11-11 manter `modo-llm.sh`, `test-llm.sh` e os agentes `etapas`/`executor`): se não servir, apagar.
- [ ] [A] `agent_logs.md` com esta virada de plano.

## Bloco 3: decidir a máquina principal

O AeroSpace foi abandonado no Mac (multimonitor atrapalhando, bugs abertos no `TODO.md`), e o usuário vai comprar um MacBook. Falta decidir **qual máquina é a principal**: o MacBook ou um PC torre com NixOS. A decisão mexe em regras do `AGENTS.md` §3 (macOS como referência da paridade, `KEYMAP.md`, tiling nas duas plataformas).

- [ ] [U+A] **Conversa (grilling)** sobre a máquina principal: o que cada uma faz, onde rodam o LLM local e os builds, o papel do macmini depois (servidor? some?), e se a paridade de tiling continua. Resultado num ADR em `docs/adr/` e no `AGENTS.md`.
- [ ] [A] Depois dela: rever os bugs do macmini e do AeroSpace no `TODO.md` (sai o que deixar de valer) e a pauta da sessão de desktop ao vivo.

## Bloco 4: arquitetura do flake

Revisão de 2026-11-09 em `scratch/handoffs/architecture-review-20261109.html` (cinco candidatos, `file:line` em cada um). Um por vez, cada um validado com `nix eval` dos hosts tocados:

- [x] [A] **2. Cópia segura do SQLite como uma opção do módulo de backup** (feito em 11/11: `backup.sqlite.<nome> = { path; owner; }`; os dumps do rpi3 passam a `ferdium.sqlite3` e `gitea.sqlite3`; vale no próximo deploy do `hetzner` e do `rpi3`) (recomendação principal: falha calada até um restore; hoje está escrita à mão em `hetzner`, `rpi3` e `gitea.nix`).
- [ ] [A] **1. Módulo `workstation`** (`cli-dev`, `ferdium`, `calendar` uma vez só; `nitro5-vm` derivado do `nitro5`). Esperar o Bloco 3, que pode mudar quais máquinas são workstations.
- [ ] [A] **4. Exposição no tailnet do rpi3 como uma declaração** (router, backend, porta e nome por serviço).
- [ ] [A] **3. Política de backup única com adaptadores** systemd e launchd (vem quase de graça depois do 2).
- [ ] [A] **5. Contrato de início do stack** compartilhado entre `deploy.sh` e `test-compose.sh` (toca o `private-services` também).

## Bloco 5: o que sobrou do sprint, por lugar

- [ ] [U] **`navegador.sh`, estágios 7 a 16**: Gitea (admin e token, depois o agente cria e confere os espelhos), Nextcloud (Mail, agenda e contatos, 2FA, CalDAV), `rbw` no nitro5, DAVx5, mail de ponta a ponta (DNS já conferido em 28/10), limpeza do projeto `gdrive-backups-504706`, XML do Lattes (depois o agente faz o currículo e publica o README do perfil).
- [ ] [U] **`ssh.sh`**: restore de teste no rpi3 e remoção do `rclone.conf` antigo do Pi (token com escopo `drive` completo).
- [ ] [U] **`presencial.sh`**: DHCP pelo Pi-hole, login do `gh` no Keychain (o token está em texto puro em `~/.config/gh/hosts.yml`), testes do nitro5; com o agente, `rclone mount` e a sessão de desktop ao vivo (depois do Bloco 3).
- [ ] [A] **Tunnel do Mac**: o `nixpkgs-unstable` já tem o `cloudflared` 2026.10.7 (11/11); falta um `just update` (o `flake.lock` é de 07/10) e ligar `services.cloudflaredTunnel.enable` no Mac.

## Estacionado

Cada item volta quando o gatilho acontecer; o detalhe está no `TODO.md`.

- **Oracle, depois da VM**: host no flake, NixOS por cima do Ubuntu, segunda cópia dos backups, failover do Vaultwarden e um Stalwart secundário (o failback ainda não foi desenhado). Volta quando a VM existir; o Always Free agora é 2 OCPUs / 12 GB no total.
- **Kaly42** (Docmost na `public-network`, `*.kaly`, porta 443): prazo de 10–11/10 perdido e o OIDC pode ser recurso pago. Volta quando houver data nova.
- **Chaves `sol`, `luna` e `terra`** e chaves SSH servidas pelo `rbw-agent`: a troca das chaves no Bloco 1 decide se elas nascem já nesse desenho.
- **Kanidm e OpenBao**: o Kanidm segue desligado (dados em `~/volumes/kanidm` no `hetzner`).
- **Clash Party**: falta o desenho para várias chaves e túneis por programa.
- **Tuya** (lâmpada e tomada que religa o macmini) e o nobreak atrás dela.
- **Projetos do `lembretes.md`** além do perfil e do currículo: `site-base`, site pessoal, site da SECComp.
- **SECComp-Points**: vai virar parte do site novo da SECComp. Até lá fica como está (o commit parado no stage não sobe); quando migrar, guardar o banco e a lista de presença e só então apagar o repositório local.
- **RISE e SECComp no `hetzner`**: para voltarem, os composes trocam `edge-network` por `tunnel-network`. Conteúdo das aulas (checklists do laboratório, NotebookLM, demo de OOM) sem data marcada.
- **Submódulos para `configs/` e `scripts/`**: discussão aberta no `TODO.md`.
- **Minecraft**: kit em `configs/minecraft/`, instalar quando o Debian estiver acessível.
- **Design v2**: animações (ADR novo), rolagem de texto nas barras, IPs no item de rede. Espera o Bloco 3.
- **webtop**: saiu do sprint em 24/10 pelo CVE da libbrotli do Debian. Volta quando o `libbrotli1` da imagem estiver corrigido (`private-services/agent_logs.md`).

## Referência

**rpi3.** Tailnet `100.69.134.71`, anuncia `10.0.0.0/24`. Traefik nativo do NixOS só pelo tailnet (`*.rpi3.leazirondi.com.br`, certificado próprio com o token `traefik_env`); painel reserva do Pi-hole em `http://10.0.0.10:8081/admin`. O DNS interno do Podman fica desligado (disputava a porta 53 com o Pi-hole). Numa instalação nova o usuário nasce sem senha: `ssh root@<host> passwd zirondi`. Apagar o `FERDIUM_APP_KEY.txt` faz o entrypoint gerar outra chave e derruba as sessões dos clientes (saem e entram de novo); o entrypoint escreve a chave no journal a cada início.

**hetzner.** Um deploy `--nix` reinicia o `podman.socket` do usuário, e o provedor Docker do Traefik passa alguns segundos sem resposta (503 do `socket-proxy`); se um stack novo não aparecer no Traefik, reiniciar o `socket-proxy`. À mão, o `podman-compose` precisa de `INSTANCE_HOST=hetzner`, que o `deploy.sh` exporta.

**Backup.** Restic com rclone para o Drive, um repositório por host (`gdrive:restic` dentro de `servers/backup-<host>`, com `root_folder_id` no `rclone_conf`; um projeto do Google Cloud e uma senha por host), retenção 7 diários / 4 semanais / 12 mensais, diário às 04:00. Módulo `modules/nixos/backup.nix`; o que cada host copia está em `hosts/<host>/backup.nix`. Sem o `rclone_conf` no SOPS o build falha, por isso o `backup.enable` só volta junto com ele.

**Oracle.** Região `sa-saopaulo-1`, um único AD, com falta crônica de A1 (6.243 tentativas de 13 a 20/10 sem capacidade; outros relatos iguais em 31/10). O padrão do script é 2 OCPUs / 12 GB, o teto do Always Free: acima disso, numa conta PAYG, cobra; numa conta free, as instâncias A1 são desligadas. O script morre a cada reboot do Mac (parou em 20/10 sem ninguém ver): conferir com `tmux ls` e `tail ~/.oci/launch.log`. Relançar a busca num terminal próprio (não pelo `!` do Claude Code, que encerra o `tmux`):

```sh
tmux new -d -s oci 'NOTIFY_CMD=~/.oci/notify.sh ~/dotfiles/scripts/oci-launch.sh --subnet ocid1.subnet.oc1.sa-saopaulo-1.aaaaaaaaem3nmnzyck4koknn3wxckjtmlq66fl6fasrxlybbazbt6yzj6tca --ssh-key ~/.ssh/main.pub 2>&1 | tee -a ~/.oci/launch.log'
```
