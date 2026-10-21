# Ordem de trabalho

Atualizada em 2026-10-21. **O que só o usuário pode fazer** (senha de app do CalDAV e `vdirsyncer discover` nas duas máquinas, 2FA do Nextcloud, senha do Restic no papel e no cofre, chave age no cofre, conta do Ferdium, `~/volumes` do Mac, túnel e Access antigos da Cloudflare) está no wizard `scratch/wizards/upkeep.sh`, rodado num terminal local. No fim ele lista o que foi feito: marcar aqui e no `TODO.md`, e, se a conta do Ferdium foi criada, fechar o cadastro (bloco 1). Este arquivo diz **o que vem agora e em que ordem**. O detalhe de cada item continua no `TODO.md`; o que depende de lugar ou momento, no `reminders.md`. Quando um bloco terminar, marque aqui e siga para o próximo.

## Agora

0. **Nextcloud** (bloco 6): no ar desde 2026-10-15; faltam as contas, o backup e a saída do SnappyMail.
1. **Oracle** (bloco 3): o script está tentando criar a VM. Quando conseguir, provisionar o host.
2. **Kaly42** (bloco 4): já desbloqueado pelo Traefik unificado.
3. **Chaves e cofre** (bloco 5): em andamento pelo usuário.
4. **Em casa** (bloco 1): DHCP no Pi-hole e os aparelhos Tuya.
5. **nitro5 e desktop unificado** (2026-10-17): NixOS instalado e reconstruído; design system em `configs/design/` aplicado nas duas plataformas em 2026-10-20 e conferido no nitro5. Falta conferir o Mac na tela, fechar as lacunas da spec e o setup do CalDAV (`scratch/wizards/upkeep.sh`; pendências no `TODO.md`, "Design system do desktop").

## 1. rpi3

Geração 26.11 ativa, com sops-nix. Roda Pi-hole e cloudflared; está no tailnet como `100.69.134.71` e anuncia `10.0.0.0/24` (rota aprovada e expiração da chave desligada).

- [x] Deploy da geração nova. Duas correções foram necessárias em `hosts/rpi3/services.nix`: imagens com `docker.io/` no nome e `--cap-add=NET_RAW` no Pi-hole.
- [x] Segredos antigos em texto puro apagados do Pi.
- [x] Tailscale como subnet router; IP registrado em `docs/network_ip_ranges.md`.
- [x] Home Assistant removido (usava 360 MB). Os dados continuam em `/var/lib/homeassistant` no Pi.
- [x] `initialPassword` removido de `hosts/rpi3/` e de `hosts/nitro5/default.nix`. Numa instalação nova o usuário nasce sem senha: definir com `ssh root@<host> passwd zirondi` (no nitro5 isso é necessário para o login gráfico e o `sudo`).
- [ ] **Pi-hole como DHCP da LAN** (em casa): ligar o DHCP do Pi-hole, desligar o do roteador e conferir que os clientes recebem `10.0.0.10` como DNS. Dá para declarar no Nix com variáveis `FTLCONF_dhcp_*` no container; confirmar os nomes na documentação do Pi-hole v6 antes.
- [ ] **Automação Tuya** (em casa): lâmpada Elgin e tomada inteligente, com um script `tinytuya` no Pi. Passos: confirmar o protocolo com a lâmpada ligada, pegar as chaves locais (conta de desenvolvedor da Tuya), e escrever a rotina que religa o macmini pela tomada quando ele parar de responder. Substitui o teste de nobreak por enquanto. Observado em 2026-10-20: a lâmpada fica com o Bluetooth ligado 24/7 (aparece no scan do nitro5 como `TUYA_`/`TY`). Ver se o Bluetooth dela pode ser desligado depois de configurada no Wi-Fi (opção no app da Tuya ou no firmware) ou se é o anúncio BLE de provisionamento que não desliga; incluir no setup do `tinytuya`.
- [x] `ferdium-server` 2.0.13 no Pi, atrás do Traefik do Pi (limite de 256 MB; dados em `/var/lib/ferdium-server`, incluídos no `rclone-backup`). O DNS interno do Podman foi desligado no Pi, porque disputava a porta 53 com o Pi-hole.
- [x] **Loja de receitas do Ferdium**: `/v1/recipes` dava 500 porque o servidor lê de `/app/build/recipes` e o entrypoint clona em `/app/recipes`. O volume agora é montado nos dois caminhos em `hosts/rpi3/services.nix`; aplicado em 2026-10-15 e respondendo 200.
- [x] **Chave do `ferdium-server` recriada em 2026-10-15**: o `FERDIUM_APP_KEY.txt` foi apagado à mão, e na reinicialização do deploy o entrypoint gerou outro. Isso invalida as sessões dos clientes (faixa "Could not load services and user information"), que voltam saindo e entrando de novo no Ferdium; o banco não é afetado. O entrypoint escreve a chave no journal a cada início.
- [ ] **Backup do Pi inativo**: o `rclone-backup` só roda com `/root/.config/rclone/rclone.conf`, que ainda não existe; o `ferdium-server` não tem cópia nenhuma. Entra no trabalho de backup.
- [ ] **Fechar o cadastro do Ferdium**: o servidor não tem página de cadastro na web; a conta se cria pelo app do Ferdium, com o servidor personalizado `https://ferdium.rpi3.leazirondi.com.br`. Depois, trocar `IS_REGISTRATION_ENABLED` para `"false"` em `hosts/rpi3/services.nix` e fazer o deploy.
- [x] Traefik no Pi como serviço do NixOS (`services.traefik`), só pelo tailnet: `ferdium.rpi3.leazirondi.com.br` e `pihole.rpi3.leazirondi.com.br`. O painel do Pi-hole saiu das portas 80 e 443 e tem um acesso reserva pela LAN em `http://10.0.0.10:8081/admin`.
- [x] Certificado `*.rpi3.leazirondi.com.br` emitido pela CA de produção, com um token de DNS próprio do Pi (`traefik_env`).
- [x] Registro `A` curinga `*.rpi3.leazirondi.com.br` → `100.69.134.71` (DNS only).

## 2. Traefik em um stack só

Concluído em 2026-10-13 no `hetzner`, commitado e enviado.

- [x] Submódulo `services/` como única cópia de trabalho (regra no `AGENTS.md` §9); `mail` e `vaultwarden` trazidos para ele.
- [x] Stack `traefik-cloudflared` → `traefik`, com os dois `cloudflared` no mesmo compose.
- [x] Redes `cloudflared-network`, `tunnel-network` e `public-network`; a `edge-network` não existe mais.
- [x] Entrypoints `web` (túnel), `websecure` (preso ao IP do Tailscale) e `public` (preso ao IP público; a 443 segue fechada no firewall até o Kaly42).
- [x] Wildcard `*.hetzner.leazirondi.com.br` pela CA de produção; `whoami.hetzner.leazirondi.com.br` responde pelo tailnet.
- [x] Stacks do RISE e da SECComp removidos do `hetzner`. Os arquivos do servidor ficaram em `hetzner-backup-2026-10-13/` dentro do repositório local de cada um, fora do git.

Sobrou:

- [x] Checkout irmão `~/repos/github/me/public/services` limpo e igual ao submódulo; fica como espelho somente leitura.
- [ ] **RISE e SECComp**: para voltarem, o compose de cada repositório precisa trocar `edge-network` por `tunnel-network`. Organizar os backups.
- [ ] **zirondi.tech**: dar ao token de DNS da Cloudflare permissão de edição nessa zona antes do primeiro certificado.
- [ ] Kanidm segue desligado (container removido, dados em `~/volumes/kanidm`) até o trabalho de identidade.

## 3. Oracle: instância Always Free

Em andamento. `scripts/oci-launch.sh` roda no macmini, na sessão `tmux` chamada `oci`, uma tentativa por minuto; até agora só "no capacity".

- [x] Chave de API em `~/.oci/` e `oci-cli` instalado pelo `modules/shared/cli-dev.nix`.
- [x] VCN `vcn01` em `10.20.0.0/16` (pública `10.20.0.0/24`, privada `10.20.1.0/24`). A faixa original do wizard, `10.0.0.0/16`, colidia com a LAN de casa e foi trocada pela API.
- [x] Script validado contra a API real.
- [x] **Relançado** em 2026-10-15 às 21:34, depois do reboot do Mac às 17:14 que derrubou a sessão anterior. O script só escreve no terminal; o `tee` do comando abaixo é o que alimenta o `launch.log`. No sucesso, o `NOTIFY_CMD` chama `~/.oci/notify.sh` (fora do repositório), que manda um push pelo ntfy (o tópico está no arquivo) e uma notificação no Mac. Rodar o comando num terminal próprio, não pelo `!` do Claude Code, que encerra o `tmux` junto.
- [ ] **Acompanhar**: `tmux attach -t oci` ou `tail -f ~/.oci/launch.log`. Se o Mac reiniciar, a sessão some; o comando para relançar está no fim deste bloco.
- [ ] **Upgrade para Pay As You Go** quando o cartão virar: melhora a chance de capacidade e tira a conta da regra de recuperação de instâncias ociosas. Criar um budget com alerta e ficar nos limites gratuitos (4 OCPUs, 24 GB, 200 GB de disco).
- [ ] **A decidir:** a chave de API da OCI vai para o cofre junto com as outras (bloco 5)?
- [ ] **Depois de criada:** alias em `configs/ssh/config`, host novo no flake (`aarch64-linux`, então o build roda no `nix-builder` como o do rpi3), instalação do NixOS por cima do Ubuntu, Tailscale, host key no `.sops.yaml` dos repositórios de serviços e inventários em `docs/`. Só então o backup e a redundância do Vaultwarden.

```sh
tmux new -d -s oci 'NOTIFY_CMD=~/.oci/notify.sh ~/dotfiles/scripts/oci-launch.sh --subnet ocid1.subnet.oc1.sa-saopaulo-1.aaaaaaaaem3nmnzyck4koknn3wxckjtmlq66fl6fasrxlybbazbt6yzj6tca --ssh-key ~/.ssh/main.pub 2>&1 | tee -a ~/.oci/launch.log'
```

## 4. Kaly42

Desbloqueado. Falta tudo:

- [ ] Registro `*.kaly.leazirondi.com.br` (DNS only) para o IP público do `hetzner`.
- [ ] Abrir a 443 em `hosts/hetzner/default.nix` e fazer o deploy do NixOS.
- [ ] Stack do Docmost na `public-network`, com o bloco 3 de `services/.template/traefik-label-template.yml`, segredos em SOPS e os cabeçalhos de segurança que o entrypoint `public` já aplica.

## 5. Chaves e cofre

Em andamento pelo usuário: organização do cofre. Nesta ordem:

1. Chaves `sol`, `luna` e `terra` (gerar, publicar, autorizar ao lado da `main`, testar, remover a `main`).
2. Inventário dos segredos no cofre.
3. Teste do `rbw-menu` contra o cofre real (já commitado; roteiro no fim do `TODO.md`).
4. Chaves SSH servidas pelo `rbw-agent`. Enquanto isso não existe, `git push` e assinatura fora da sessão gráfica precisam da chave explícita (ver `reminders.md`).

## 6. Nextcloud (e-mail, agenda e contatos)

No ar em 2026-10-15 no `hetzner`, só pelo tailnet: `https://nextcloud.hetzner.leazirondi.com.br` (stack `services/nextcloud`, Nextcloud 35 com Postgres 17 e Redis). Usuário `zirondi`; a senha inicial sai de `sops -d services/nextcloud/secrets/admin_password.sops.yaml`, rodado num terminal próprio (nunca pelo agente, ver `AGENTS.md` §17), e deve ir para o cofre. Apps Mail, Calendar e Contacts instalados, cron em modo `cron`, HSTS pelo `security-headers@file`. O `hetzner` ganhou 2 GB de swap no mesmo dia.

- [ ] **Contas no Nextcloud Mail**: em Configurações de administração → Groupware, preencher a integração do Gmail e a da Microsoft (tenant `common`), registrando nos apps OAuth os redirect URIs que essa tela mostra. Proton só com a Bridge (plano pago); sem ela, fica na receita `proton-mail` do Ferdium.
- [ ] **Agenda e contatos**: importar o `.ics` e o `.vcf` exportados do Google; no Android, DAVx5 apontando para o Nextcloud com o Tailscale ligado.
- [ ] **Ferdium**: serviço Nextcloud (receitas `nextcloud`/`nextcloud-calendar`) no workspace E-mail, no lugar das contas separadas.
- [ ] **Backup**: coberto pelo bloco 7 (dumps do Postgres do Nextcloud e do n8n antes de cada cópia).
- [ ] **Tirar o SnappyMail** (`webmail` em `services/mail`) depois de validar as contas no Nextcloud Mail; o Stalwart fica.
- [ ] **2FA** no usuário do Nextcloud (o próprio setup check sugere).

Aviso: um deploy `--nix` no `hetzner` reinicia o `podman.socket` do usuário, e o provedor Docker do Traefik passa alguns segundos sem resposta (503 do `socket-proxy`). Se um stack novo não aparecer no Traefik, reiniciar o `socket-proxy`.

## 7. Backup (Restic → Google Drive)

Em andamento desde 2026-10-15. Decisões: Restic com rclone para o Drive, um repositório por host (`gdrive:backups/<host>`), retenção 7 diários / 4 semanais / 12 mensais, diário às 04:00. Módulo `modules/nixos/backup.nix`; o que cada host copia está em `hosts/<host>/backup.nix`. Os jobs antigos (`backup-volumes` no `hetzner`, `rclone-backup` no Pi) saíram.

- [x] Módulo e configuração do `hetzner` (dumps do Nextcloud e do n8n com `pg_dump`, Vaultwarden com `.backup`, Nextcloud em manutenção e Stalwart parado durante a cópia) e do `rpi3` (Ferdium com `.backup`, configuração do Pi-hole, sobra do Home Assistant). Comandos de dump testados como root no `hetzner`.
- [x] Senha do Restic gerada direto nos arquivos SOPS (`hosts/hetzner/secrets.sops.yaml`, novo, e `hosts/rpi3/secrets.sops.yaml`), a mesma nos dois.
- [ ] **Cópia da senha no papel e no cofre**: `sops -d --extract '["restic_password"]' hosts/hetzner/secrets.sops.yaml`, num terminal próprio. Sem ela, nenhum backup é restaurável.
- [ ] **OAuth do Drive** (bloqueado em 2026-10-21: o login Google quebra no Zen, no Mac e no nitro5; fazer pelo Chrome ou pelo Helium, ver `TODO.md`, "Login Google quebrado no Zen"): três clients "Desktop" no projeto do Google Cloud (`rclone-backup` e `rclone-minecraft` com `drive.file`, `rclone-mount` com `drive`); para este bloco, o `rclone-backup`, Drive API ativada, app publicado em produção (em teste, o token expira em 7 dias). No Mac, `rclone config` com o remote `gdrive`, `scope = drive.file`.
- [ ] **`rclone_conf` nos dois arquivos SOPS** (o agente faz, sem ler o conteúdo), deploy `--nix` dos dois hosts e primeiro backup manual (`systemctl start restic-backups-gdrive`), com `restic snapshots` e um restore de teste.
- [ ] **Mac**: Restic pelo launchd (nix-darwin) só para o que não está em repositório: `~/.config/sops`, `~/.ssh`, `~/.oci`, `~/.config/containers`, estado dos agentes de IA (`~/.claude*`, `~/.codex`, `~/.gemini`, `~/.config/opencode`), `~/.sparrow`.
- [ ] **Chave age do Mac** no cofre e numa cópia offline (é a que decifra os segredos de todos os repositórios).
- [ ] **Depois do Oracle**: segunda cópia dos repositórios lá, failover do Vaultwarden e um Stalwart secundário (MX de prioridade menor que guarda e repassa quando o `hetzner` cai).
- [ ] **Servidor de Minecraft** (Debian, fora do flake): kit pronto em `configs/minecraft/` (boot pelo systemd no `screen`, backup diário com `scripts/mc-backup.sh`, testado num Debian em container). Instalar seguindo o README de lá.
- [ ] **Montar o Drive** (e talvez o Proton) com `rclone mount` no Mac e no Nitro 5, declarado no Nix, com o client `rclone-mount`. O CloudMounter saiu do Homebrew.
- [ ] **Repositórios sem remote** (`rise-*`, `curriculum`, `site-base`, `gitea/me/private`): decidir um a um.

## Estacionado de propósito

Não mexer até o usuário retomar:

- Stacks do `private-services` que ainda não subiram.
- Clash Party: falta um desenho para várias chaves e túneis por programa.
- Nobreak do macmini: fica atrás do teste com a tomada inteligente (bloco 1).
- Backup incremental e redundância do Vaultwarden (dependem do bloco 3).

## Pontas soltas pequenas

- [ ] **Apagar o `~/volumes` do Mac** (`n8n`, `snappymail`, `stalwart`, `traefik`): quase certamente sobras de testes locais; confirmar e apagar.
- [x] ~~Remover o LaunchAgent `com.zirondi.mac-remote-access`~~: decidido em 2026-10-20 que fica. Ele sobe o Guacamole do Mac pelo tailnet (`modules/darwin/podman.nix`); as correções estão no `TODO.md`, "Guacamole do Mac pelo tailnet".

- [ ] **Trocar a senha de VNC do Mac**: considerada comprometida. Ela aparece em texto claro em conversas antigas do Antigravity (`~/.gemini/antigravity/` e `~/.gemini/antigravity-cli/`), que o usuário decidiu manter por enquanto.
- [ ] Refazer o login do `gh` na sessão gráfica (token em texto puro em `~/.config/gh/hosts.yml`).
- [ ] Apagar o túnel e o Access antigos do acesso remoto ao Mac na Cloudflare.
