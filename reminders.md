# Lembretes

Coisas que dependem de um momento ou lugar específico. O backlog de tarefas fica em `TODO.md`.

## Quando estiver fisicamente no Mac Mini

- [ ] **Testar o `rbw-menu`** contra o cofre real (passo a passo no fim do `TODO.md`).
- [ ] **Rodar os commits pendentes**, depois do teste e nesta ordem. O index já contém só o `rbw-menu`; não rodar `git add -A` antes do primeiro commit.
  1. `git commit -m "feat(rbw-menu): add password menu backed by rbw"`
  2. `git add '*.nix' && git commit -m "style(nix): format the tree with nixfmt and check it in the flake"`
  3. `git add TODO.md agent_logs.md reminders.md && git commit -m "docs: update TODO, reminders and handoff log"`
  - Se o teste exigir correções no `rbw-menu`, dar `git add` nelas antes do passo 1.
  - Mudanças em arquivos `.nix` feitas até lá entram junto no passo 2; separar com `git add -p` se necessário.
- [ ] **Refazer o login do `gh`** na sessão gráfica (`gh auth logout && gh auth login`), sem o escopo `delete_repo`. O token atual está em texto puro em `~/.config/gh/hosts.yml`.

## Bots do Telegram e o watcher do e-SAJ

Desenho combinado em 2026-10-07: bots só de envio, um por fronteira de confiança, cada um postando num supergrupo com Tópicos. Os nomes vêm de cartas de Yu-Gi-Oh. Para o watcher rodar bastam o bot e o grupo pessoais; o de infra pode ficar para quando o primeiro serviço dele existir.

- [ ] **Criar os bots** no `@BotFather` (`/newbot`). O username não aceita `@` e precisa terminar em `bot`; o nome de exibição é livre.
  - Infra: **Kurikurinku @Bot**, username `kurikurinku_at_bot` (sem página no `t.me` em 2026-10-07; o BotFather confirma). Foto: arte da Kurikurinku @Ignister.
  - Pessoal: **Patrol Robo**. Foto: arte da carta.
  - Deixar o modo de privacidade ligado (padrão) e não tornar nenhum bot admin.
- [ ] **Criar os grupos**, ligar Tópicos nas configurações de cada um e adicionar o bot correspondente como membro.
  - **Cynet Universe** (infra, bot Kurikurinku):

    | Tópico | Para quê |
    | :--- | :--- |
    | Link Infra-Flier | uptime (Uptime Kuma) |
    | RAM Clouder | recursos (Netdata) |
    | Honeybot | logins SSH e segurança |
    | Firewall Dragon | CSP (`csp-watcher`) |
    | Backup Secretary | backups |
    | Update Jammer | imagens novas |
    | Garbage Collector | limpeza e manutenção |

  - **SPYRAL Resort** (pessoal, bot Patrol Robo):

    | Tópico | Para quê |
    | :--- | :--- |
    | Solemn Judgment | processos (`esaj-watch`) |
    | SPYRAL GEAR - Drone | `insta-monitor` |

  - Ficam para depois: bot interativo **Decode Talker** (n8n, precisa de token só dele) e o grupo **Duel Academy** com bot próprio para o CACCo.
- [ ] **Anotar os ids** do tópico Solemn Judgment: copiar o link de uma mensagem dele, no formato `https://t.me/c/<grupo>/<tópico>/<mensagem>`. O `chat_id` é `-100<grupo>` e o thread id é `<tópico>`.
- [ ] **Criar os segredos do `esaj-watch`** (token do Patrol Robo):
  ```sh
  cd ~/dotfiles && ./scripts/init-secrets.sh esaj-watch
  cd ~/repos/github/me/private/private-services
  for s in TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID ESAJ_PROCESSOS; do
    sops --input-type binary --output-type binary "esaj-watch/secrets/$s.sops.yaml"
  done
  ```
  `ESAJ_PROCESSOS` leva um processo por linha, no formato `NNNNNNN-DD.AAAA.8.26.OOOO/NN` (o `/NN` é o incidente, ex.: o precatório). Os `.sops.yaml` dessa pasta não entram no git (o `.gitignore` do `private-services` ignora `secrets/`).
- [ ] **Preencher `TELEGRAM_THREAD_ID`** em `private-services/esaj-watch/compose.yml` com o id do tópico.
- [ ] **Subir o watcher**: `cd ~/dotfiles && ./scripts/deploy.sh hetzner --svc esaj-watch`. Se reclamar da pasta do volume: `ssh hetzner mkdir -p ~/volumes/esaj-watch/data`.
- [ ] **Validar**: deve chegar "Monitorando o processo…" no tópico Solemn Judgment. Se não chegar: `ssh hetzner podman logs esaj-watch`.

## Quando estiver em casa, com o nitro5

- [ ] **Instalar o NixOS no nitro5** a partir do macmini, com cabo de rede e os dois na mesma LAN (detalhes no `TODO.md`). Fazer antes a config de tiling unificada.

## Quando o rpi3 voltar a responder na rede

O Pi parou de responder em 2026-10-07 (~21h): sem ping, SSH, DNS nem Home Assistant em `10.0.0.10`. O sistema novo já está construído no builder do Mac (`nix-builder`), então o deploy só copia e ativa.

- [ ] **Religar o Pi** na tomada se estiver travado. Ele volta na geração antiga, que funcionava.
- [ ] **Conferir que voltou**: `ping -c 2 10.0.0.10` e `ssh root@rpi3 'podman ps'` (Pi-hole, cloudflared e Home Assistant de pé).
- [ ] **Abrir uma sessão SSH de segurança** em outro terminal e deixá-la aberta: `ssh root@rpi3`.
- [ ] **Fazer o deploy** a partir do Mac (não compila nada no Pi):
  ```sh
  cd ~/dotfiles && ./scripts/deploy.sh rpi3 root@rpi3 --nix
  ```
  É a primeira vez que a cópia e a ativação rodam pelo builder, e a primeira vez do sops-nix no Pi.
- [ ] **Validar**:
  ```sh
  ssh root@rpi3 'readlink /run/current-system; podman ps; ls -l /run/secrets/'
  dig @10.0.0.10 example.com +short
  ```
  O `readlink` deve mostrar `...-nixos-system-rpi3-26.11.20261005.aa48d34` e `/run/secrets/` deve ter `pihole_env` e `cloudflared_env`.
- [ ] **Apagar os segredos antigos** no Pi, só depois de validar:
  ```sh
  ssh root@rpi3 'rm /var/lib/pihole/secrets.env /var/lib/cloudflared/token.env'
  ```
- [ ] **Se algo der errado**, voltar à geração anterior: `ssh root@rpi3 'nixos-rebuild switch --rollback'`.
- [ ] **Push dos commits** do builder e do rpi3 (`git push`) depois do deploy validado.

## Depois que o deploy do rpi3 terminar

- [ ] **Configurar os serviços do rpi3**, incluindo avaliar o `ferdium-server`.
