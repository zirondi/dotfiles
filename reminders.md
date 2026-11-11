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

Desenho combinado em 2026-10-07: bots só de envio, um por fronteira de confiança, cada um postando num supergrupo com Tópicos. Os bots e as fotos dos grupos vêm de cartas de Yu-Gi-Oh. Para o watcher rodar bastam o bot e o grupo pessoais; o de infra pode ficar para quando o primeiro serviço dele existir.

- [x] **Criar os bots** no `@BotFather` (`/newbot`). O username não aceita `@` e precisa terminar em `bot`; o nome de exibição é livre.
  - Infra: **Kurikurinku @Bot**, username `kurikurinku_at_bot` (sem página no `t.me` em 2026-10-07; o BotFather confirma). Foto: arte da Kurikurinku @Ignister.
  - Pessoal: **Orbital 7** (o Patrol Robo saiu em 2026-10-24: sem arte boa, e os usernames dele estavam tomados). O nome remete à fala dele, "You got it, boss!" (no japonês, "Kashikomarimashita, Kaito-sama"). Foto: arte da carta. Username a confirmar no BotFather; livres no `t.me` em 2026-10-24: `you_got_it_boss_bot`, `kashikomari_bot`, `orbital_7_bot` (o `orbital7_bot` existe).
  - Deixar o modo de privacidade ligado (padrão) e não tornar nenhum bot admin.
- [x] **Criar os grupos**, ligar Tópicos nas configurações de cada um e adicionar o bot correspondente como membro. As cartas ficam só nos bots e nos grupos, que têm foto; os tópicos têm nome descritivo (decisão do usuário: o ícone de um tópico é só um emoji, e achar um assunto pelo nome da carta confundia). Crie agora só os tópicos que já têm serviço; os outros entram quando o serviço existir.
  - Grupo de infra, com a arte do **Cynet Universe** como foto (bot Kurikurinku):

    | Tópico | Para quê | Quando |
    | :--- | :--- | :--- |
    | Imagens novas | Diun | agora |
    | Uptime | Uptime Kuma | quando subir |
    | Recursos | Netdata | quando subir |
    | SSH e segurança | logins SSH | quando subir |
    | CSP | `csp-watcher` | quando subir |
    | Backups | Restic | quando houver aviso de backup |
    | Manutenção | limpeza e manutenção | quando subir |

  - Grupo pessoal, com a arte do **SPYRAL Resort** como foto (bot Orbital 7):

    | Tópico | Para quê | Quando |
    | :--- | :--- | :--- |
    | Processos | `esaj-watch` | agora |

  - Ficam para depois: bot interativo **Decode Talker** (n8n, precisa de token só dele) e o grupo **Duel Academy** com bot próprio para o CACCo.
- [x] **Anotar os ids** do tópico Processos: copiar o link de uma mensagem dele, no formato `https://t.me/c/<grupo>/<tópico>/<mensagem>`. O `chat_id` é `-100<grupo>` e o thread id é `<tópico>`.
- [x] **Segredos do `esaj-watch` e `TELEGRAM_THREAD_ID`** (feito em 2026-10-24; o processo foi testado com `--dry-run`): gravados pelo `scratch/wizards/sprint.sh sabado` (estágios 8 e 9), a partir do link de uma mensagem do tópico e de um arquivo com um processo por linha (`NNNNNNN-DD.AAAA.8.26.OOOO/NN`, o `/NN` é o incidente). Os `.sops.yaml` entram no git desde 2026-10-23.
- [x] **Subir o watcher** (feito em 2026-10-28): `cd ~/dotfiles && ./scripts/deploy.sh hetzner --svc esaj-watch`. Se reclamar da pasta do volume: `ssh hetzner mkdir -p ~/volumes/esaj-watch/data`.
- [x] **Validar** (confirmado em 2026-10-28): deve chegar "Monitorando o processo…" no tópico Processos. Se não chegar: `ssh hetzner podman logs esaj-watch`.

## Em datas marcadas

- [ ] **Antes de 24/10/2027: renovar os tokens do GitHub dos espelhos do Gitea.** São três fine-grained só de leitura (`zirondi`, `SECComp-UNESP-RC`, `CACCo-UNESP-RC`), no cofre como "GitHub Gitea mirror <dono>". Vencidos, o Gitea do `rpi3` para de atualizar os espelhos sem avisar. Em cada um: Regenerate token no GitHub (o máximo é um ano a partir do dia), `rbw edit "GitHub Gitea mirror <dono>"` e atualizar o token salvo em cada espelho do Gitea (`scripts/gitea-mirror.sh` só cria espelhos novos).

## Quando estiver em casa, com o rpi3 e os aparelhos

O Pi está na geração nova e no tailnet (referência no `ORDEM.md`).

- [ ] **Ligar o DHCP no Pi-hole** e desligar o do roteador; conferir num cliente que o DNS recebido é `10.0.0.10`.
- [ ] **Ligar a lâmpada Elgin** no interruptor e confirmar que ela é Tuya (parear no app Smart Life ou ver os anúncios na rede).
- [ ] **Configurar a tomada inteligente** e ligar o macmini nela.
- [ ] **Se o Pi-hole parar** depois de um deploy: `ssh root@rpi3 'podman ps; podman logs --tail 30 pihole'`. Voltar à geração anterior com `ssh root@rpi3 'nixos-rebuild switch --rollback'`.

## Enquanto a VM da Oracle não sai

- [ ] **Conferir o script** de vez em quando: `tmux attach -t oci` no macmini, ou `tail ~/.oci/launch.log`. Depois de um reinício do Mac, relançar com o comando do `ORDEM.md` (Referência, Oracle).
- [ ] **Quando o cartão virar**: fazer o upgrade da conta para Pay As You Go e criar um budget com alerta. Login, menus e o que fazer depois em `scratch/handoffs/HANDOFF-oracle.md`. O trial acaba por volta de 12/11; depois dele a conta segue Always Free (2 OCPUs / 12 GB de A1), sem perder nada.
