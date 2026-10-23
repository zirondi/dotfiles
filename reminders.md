# Lembretes

Coisas que dependem de um momento ou lugar específico. O backlog de tarefas fica em `TODO.md`.

## Quando estiver fisicamente no Mac Mini

- [ ] **Testar o `rbw-menu`** contra o cofre real (passo a passo no fim do `TODO.md`).
- [ ] **Push ou commit assinado fora da sessão gráfica**: sem ssh-agent (por SSH ou Guacamole), passar a chave explicitamente até as chaves irem para o `rbw-agent`:
  ```sh
  GIT_SSH_COMMAND='ssh -i ~/.ssh/main -o IdentitiesOnly=yes' git push
  git -c user.signingkey="$HOME/.ssh/main" commit
  ```
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
- [ ] **Segredos do `esaj-watch` e `TELEGRAM_THREAD_ID`**: gravados pelo `scratch/wizards/sprint.sh sabado` (estágios 8 e 9), a partir do link de uma mensagem do tópico e de um arquivo com um processo por linha (`NNNNNNN-DD.AAAA.8.26.OOOO/NN`, o `/NN` é o incidente). Os `.sops.yaml` entram no git desde 2026-10-23.
- [ ] **Subir o watcher**: `cd ~/dotfiles && ./scripts/deploy.sh hetzner --svc esaj-watch`. Se reclamar da pasta do volume: `ssh hetzner mkdir -p ~/volumes/esaj-watch/data`.
- [ ] **Validar**: deve chegar "Monitorando o processo…" no tópico Solemn Judgment. Se não chegar: `ssh hetzner podman logs esaj-watch`.

## Quando estiver em casa, com o rpi3 e os aparelhos

O Pi está na geração nova e no tailnet (referência no `ORDEM.md`).

- [ ] **Ligar o DHCP no Pi-hole** e desligar o do roteador; conferir num cliente que o DNS recebido é `10.0.0.10`.
- [ ] **Ligar a lâmpada Elgin** no interruptor e confirmar que ela é Tuya (parear no app Smart Life ou ver os anúncios na rede).
- [ ] **Configurar a tomada inteligente** e ligar o macmini nela.
- [ ] **Se o Pi-hole parar** depois de um deploy: `ssh root@rpi3 'podman ps; podman logs --tail 30 pihole'`. Voltar à geração anterior com `ssh root@rpi3 'nixos-rebuild switch --rollback'`.

## Enquanto a VM da Oracle não sai

- [ ] **Conferir o script** de vez em quando: `tmux attach -t oci` no macmini, ou `tail ~/.oci/launch.log`. Depois de um reinício do Mac, relançar com o comando do `ORDEM.md` (Referência, Oracle).
- [ ] **Quando o cartão virar**: fazer o upgrade da conta para Pay As You Go e criar um budget com alerta.
