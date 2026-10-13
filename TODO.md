## 🗓️ Ordem de execução

A ordem atual e o estado de cada frente ficam em `ORDEM.md` (rpi3, Traefik, Oracle, Kaly42, chaves e cofre). Este arquivo guarda o detalhe de cada item; lembretes ligados a lugar ou momento ficam em `reminders.md`.

---

## 🚀 Backlog Futuro

### Scripts & Automação
- [x] **`just` (`Justfile`)**: receitas `check`, `lint`, `fmt`, `switch`, `deploy`, `update`, `clean`, `secrets`, `test-compose` e `vm-test` encapsulam os scripts de `scripts/` (`just --list`).

### Linux Environments (NixOS)
- [ ] **Config de tiling unificada (i3 + AeroSpace)**: fazer antes do NixOS no nitro5. Criar `configs/i3/config` e `configs/aerospace/aerospace.toml` (ambos via `mkOutOfStoreSymlink`) com o mesmo mapa de atalhos, `Super` no Linux espelhando `Cmd` no macOS (AGENTS.md §2). O AeroSpace é inspirado no i3 mas usa TOML, então a paridade é de atalhos e workspaces, não de arquivo. Instalar o AeroSpace pelo `modules/darwin/` e validar no macmini primeiro. Reservar `Cmd/Super+Ctrl+P` para o `rbw-menu`.

- [ ] **Instalar o NixOS no nitro5** (hoje roda Ubuntu), a partir do macmini e por cima do sistema existente, via Tailscale (`100.92.60.6`, nó `zirondi-nitro-an515-43`). Pontos em aberto:
  - Método: `nixos-anywhere` + `disko` (apaga o disco; o instalador via kexec sai do tailnet, então precisa de uma imagem com Tailscale ou de acesso pela LAN) ou `NIXOS_LUSTRATE` (mantém as partições e o `/home` em `/old-root`, sem fase de kexec).
  - `hosts/nitro5/hardware-configuration.nix` ainda é um template com UUIDs fictícios; gerar o real na máquina.
  - Garantir rede e Tailscale no primeiro boot (Wi-Fi ou cabo; reaproveitar `/var/lib/tailscale` para manter o nó).
  - `configs/ssh/config` aponta para `nitro5.local`, que só resolve na LAN; o acesso por chave a partir do macmini ainda não funciona.
  - O build é `x86_64-linux`: compilar no próprio nitro5, não no Mac.
  - Depende de: config de tiling unificada (item acima).
  - Em casa, com cabo de rede e o Mac na mesma LAN, o `nixos-anywhere` funciona direto, sem imagem com Tailscale.
  - Bloqueia: Flashy Sudo Prompt e `rbw-menu` no nitro5.

- [ ] **Flashy Sudo Prompt** (depende do NixOS no nitro5): Implementar `SUDO_ASKPASS` pareado com `zenity` ou `rofi` para comandos de terminal que exigem sudo dispararem alertas visuais na interface gráfica do i3.

- [ ] **`rbw-menu` no nitro5**: criar `configs/i3/config` (symlink fora da store) com `bindsym $mod+Ctrl+p exec kitty --class rbw-menu -e rbw-menu` e a regra de janela flutuante; rodar `rbw-menu setup`; validar `keyd`, `pinentry-curses` e `xclip`. Desenho em `scratch/handoffs/HANDOFF-rbw-password-menu.md`.

### Senhas & Identidade
- [ ] **Testar o `rbw-menu` no Mac Mini** contra o cofre real (passo a passo na seção "Como testar o `rbw-menu` no Mac Mini", no fim deste arquivo).
- [x] **Cofre familiar**: decidido em 2026-10-07 continuar no Vaultwarden e não avaliar Psono/Passbolt agora. Comparativo guardado na seção 7 de `scratch/handoffs/HANDOFF-rbw-password-menu.md`.
- [ ] **Reestruturar as chaves SSH em `sol`, `luna` e `terra`** (antes de levar as chaves ao cofre): trocar o uso único da `main` por três chaves com papéis separados, publicadas em `static/` do repositório `zirondi` e servidas por `sol|luna|terra.leazirondi.com.br`. Decidido em 2026-10-07:
  - `sol`: principal. Hosts pessoais (`hetzner`, `rpi3`, `nitro5`), GitHub pessoal e assinatura de commits.
  - `luna`: faculdade. Organizações do CACCo e da SECComp e servidores de CTF.
  - `terra`: automações e acessos temporários.
  - O Kindle continua com a `kindle_rsa`: o OpenSSH antigo dele exige RSA.
  - As três privadas antigas não existem mais; gerar as três de novo, com passphrase, e republicar. O `static/luna` atual está corrompido (termina em `;9u`).
  - Nos hosts, referenciar cada chave por `fetchurl` do link com hash fixo, no lugar da pubkey literal. Não buscar o link em tempo de execução: sem o hash, quem controlar o repositório `zirondi` ou o DNS ganha login nos servidores, e uma queda do GitHub tranca o acesso.
  - Lugares a trocar: `hosts/hetzner/default.nix`, `hosts/rpi3/default.nix`, `hosts/rpi3/initial-configuration.nix`, `hosts/nitro5/default.nix`, `docs/nixos_anywhere_guide.md` e o `signingkey` de `configs/git/config` (não aceita URL; apontar para um arquivo `.pub` local).
  - `configs/ssh/config`: uma `IdentityFile` por papel, com `IdentitiesOnly yes`, e hosts separados para o GitHub pessoal e o das organizações.
  - Rotação sem se trancar para fora: autorizar as chaves novas ao lado da `main`, aplicar, testar o login, e só então remover a `main`.
  - No GitHub: cadastrar a `sol` para autenticação e assinatura; manter a `main` como chave de assinatura para os commits antigos continuarem "Verified".
- [ ] **Chaves SSH no cofre, servidas pelo `rbw-agent`** (depois de aprovar o `rbw-menu`; exige estar no Mac): passos na seção 8 de `scratch/handoffs/HANDOFF-rbw-password-menu.md`.
  - Hoje `~/.ssh/main` não tem passphrase e serve para tudo: login nos hosts, GitHub e assinatura dos commits (`user.signingkey`). A migração precisa cobrir os três usos.
  - Validar que a assinatura de commits funciona pelo agent (`git commit -S` com `SSH_AUTH_SOCK` apontando para o `rbw-agent`).
  - Decidido em 2026-10-07: o agent atende só a sessão local. Em sessões SSH para o Mac, `git push` e deploy não funcionam. Opcional, ainda não decidido: manter a `terra` como arquivo no Mac, limitada ao que o deploy precisa, para o deploy remoto continuar possível.
  - Só remover os arquivos de `~/.ssh/` depois de testar `ssh`, `git push`, assinatura e `scripts/deploy.sh`.
- [ ] **Inventário dos segredos a guardar no cofre**: levantar o que hoje só existe em disco e salvar no Vaultwarden. Candidatos já vistos: as chaves `sol`, `luna`, `terra` e `kindle_rsa`, a chave age do sops (`~/.config/sops/age/keys.txt`, sem ela só os hosts decriptam os segredos), o token novo da Cloudflare, os tokens dos túneis, o bot do Telegram e o `rclone.conf` quando existir.
- [ ] **Kanidm e OpenBao**: identidade com passkeys e CA de SSH com certificados curtos.

### Infrastructure & Networking
- [ ] **Serviços do rpi3**: em 2026-10-13 o Pi roda Pi-hole e cloudflared (o Home Assistant saiu). Faltam o DHCP no Pi-hole, a automação Tuya e o `ferdium-server` (a imagem tem build `arm64` e usa cerca de 134 MB; cabe). Texto original do item: Ideia a avaliar: um agregador de redes sociais/mensageiros open source no estilo Franz (ex.: Ferdium). Atenção: o Ferdium é um app de desktop; no Pi (1 GB de RAM, sem tela) só caberia o `ferdium-server`, que sincroniza a configuração entre clientes.
- [x] **TLS wildcard por host (`servico.<host>.leazirondi.com.br`)**: desenho confirmado em 2026-10-07 (plano em `scratch/handoffs/HANDOFF-dotfiles-tls.md`). O Traefik de cada host emite um wildcard Let's Encrypt por DNS-01 (token da Cloudflare); esses nomes só respondem via Tailscale e os nomes públicos de um nível continuam no Cloudflare Tunnel. Começa só pelo `hetzner`.
  - [x] `hetzner` no tailnet (`100.115.88.115`). O `rpi3` entrou em 2026-10-13 (`100.69.134.71`).
  - [x] Preparado no submódulo em 2026-10-07, sem deploy: entrypoint `websecure`, resolver DNS-01 (CA de staging), middleware `tailnet-only`, stub do secret, imagem fixada em `traefik:v3.7` e `INSTANCE_HOST` no `deploy.sh`.
  - [x] Token da Cloudflare gravado no secret (2026-10-07). O token antigo foi apagado na Cloudflare pelo usuário.
  - [x] Registro `A` `*.hetzner.leazirondi.com.br` → `100.115.88.115` criado e resolvendo (2026-10-07).
  - [x] E-mail ACME confirmado: `acme@leazirondi.com.br`.
  - [x] Criar `~/volumes/traefik/certs` no `hetzner` antes do deploy.
  - [x] Piloto com `whoami`, depois trocar para a CA de produção. O Podman rootless pode esconder o IP de origem; se o `tailnet-only` bloquear tudo, removê-lo (o firewall continua barrando o acesso público).
- [ ] **Kaly42: wiki do grupo em `*.kaly.leazirondi.com.br`**: espaço do grupo de trabalho que está recriando o teclado de código aberto kaly42. Uso: o grupo escreve junto enquanto pesquisa, como um Google Docs grande organizado por pastas e tópicos, de preferência com graph view. Acesso só com login; não é um site aberto ao público.
  - Decidido em 2026-10-07: exposição direta pela 443, com registro DNS only para o IP público do host e wildcard `*.kaly` emitido pelo Traefik com o mesmo resolver DNS-01. Sobe com TLS e cabeçalhos de segurança básicos; o CSP por hashes entra depois, quando o `csp-watcher` existir.
  - Ferramenta: Docmost como primeira opção (edição simultânea, pastas, login próprio; o graph view não é requisito). A confirmar: o login via OIDC (Kanidm) parece ser recurso da edição paga; se o login pelo Kanidm virar requisito, a alternativa é o Outline, que só funciona com OIDC.
  - Host: `hetzner`, na `public-network`, sem entrar na `tunnel-network` nem na `socket-proxy`. Rever quando a Oracle existir.
  - Um único Traefik, que entra também nessa rede. Dois entrypoints separados pelo IP de escuta: um público (IP público do host, porta 443 aberta no firewall) e o `websecure` atual preso ao IP do Tailscale. Isso dispensa depender do IP de origem no `tailnet-only`.
- [x] **Renomear as redes de containers por tipo de exposição** (nomes aprovados em 2026-10-07; primeiro item da ordem de execução):
  - `tunnel` → `cloudflared-network` (Traefik ↔ `cloudflared`).
  - `edge-network` → `tunnel-network` (Traefik ↔ serviços que saem pelo Cloudflare Tunnel).
  - Nova `public-network` (Traefik ↔ serviços expostos direto na 443). O nome `edge-network` deixa de existir, para que uma referência esquecida falhe com erro em vez de cair na rede exposta.
  - Alcance: 5 stacks do submódulo `services` e o template, `mail` e `vaultwarden` no checkout irmão, os stacks de CTF e da SECComp em outros repositórios e `scripts/test-compose.sh`.
  - Reescrever o AGENTS.md (§9, §10 e §14), que hoje manda todo serviço roteado entrar na `edge-network`; mudança aprovada pelo usuário.
  - Em produção a rede não é renomeada no lugar: todos os containers ligados a ela precisam ser recriados, com uma janela curta fora do ar.
  - No mesmo esforço, renomear o stack `traefik-cloudflared` para `traefik` (o nome só fazia sentido quando havia dois Traefiks): pasta no repositório `services`, `name:` do compose, referências em `scripts/`, `README.md` e `docs/`, e a pasta `~/services/traefik-cloudflared` no `hetzner`. O projeto do compose muda de nome, então parar o stack antigo antes de subir o novo. Os volumes em `~/volumes/traefik` não mudam.
  - No mesmo commit do submódulo, dar `git add` no secret `cloudflare_dns_api_token.sops.yaml`, que foi editado depois de ir para o stage.
- [x] **Submódulo `services`: commitar o trabalho pendente** (simples): verificado em 2026-10-07 que o submódulo está íntegro (gitlink, `origin/dev` e checkout no mesmo commit `1792f35`; um clone novo com `--recurse-submodules` funciona), então não precisa ser recriado. Falta commitar o que está em stage nele (`calibre-web`, `kanidm`, `trilium`, `traefik-cloudflared/config/dynamic/{dashboard,kanidm}.yml`) e reconciliar com o checkout irmão `~/repos/github/me/public/services`, que tem `mail` e `vaultwarden` não commitados.
- [x] **Commitar `mail` e `vaultwarden`**: os dois já rodam em produção no `hetzner`, mas os arquivos só existem, sem commit, em `~/repos/github/me/public/services` (`mail/` em stage com alterações, `vaultwarden/` não rastreado). Levar para o repositório `services` junto com o trabalho pendente do submódulo.
- [ ] **Backup incremental para o Google Drive**: plano em `scratch/handoffs/HANDOFF-backup-failover.md` (Restic + Rclone, não aprovado nem implementado). Hoje existe só o `scripts/backup-volumes.sh` com o timer `backup-volumes` no `hetzner`, que fica inativo enquanto não houver `~/.config/rclone/rclone.conf`. Falta configurar o remote `gdrive` do rclone.
- [ ] **Servidor Oracle em São Paulo e redundância do Vaultwarden** (em 2026-10-13: rede e chave de API prontas, `scripts/oci-launch.sh` tentando criar a VM; ver `ORDEM.md`): provisionar a VM (free tier) como host novo do flake e manter o Vaultwarden replicado entre Oracle e Hetzner. O SQLite exige um único escritor ativo mais replicação; opções no mesmo handoff de backup. Depende do TLS por host e do backup.
- [ ] **Kanidm desligado no `hetzner`** (decisão de 2026-10-13: fica parado até o bloco de identidade; o container foi removido e os dados estão em `~/volumes/kanidm`). Histórico: em loop de reinício desde 2026-10-07. O log do Traefik acusa `servers transport not found kanidm-transport@file`: o `config/dynamic/kanidm.yml` está em stage no submódulo e não chegou ao servidor. Verificar também o log do próprio Kanidm (`podman logs kanidm` trava enquanto ele reinicia; usar `--since` ou parar o container antes).
- [ ] **TLS A+ e CSP por hashes (`csp-watcher`)**: para serviços que possam ser expostos fora da Cloudflare. Faz parte do mesmo trabalho no Traefik, depois do wildcard por host. Rascunho em `scratch/services_drafts/csp-watcher/` (hoje só recebe `report-uri` e repassa ao Telegram).
  - TLS: opções do Traefik para nota A+ nos sites de teste (TLS 1.2+ com cifras fortes, `sniStrict`, HSTS) e cabeçalhos de segurança; validar com SSL Labs e Mozilla Observatory.
  - CSP: subir cada serviço em `Content-Security-Policy-Report-Only`, coletar no `csp-watcher` o que ele pede, registrar (Telegram e um log consultável) e só então liberar a política final por hashes.
  - Lembrete ao atualizar: uma imagem nova pode mudar os scripts inline e invalidar os hashes; ligar isso ao aviso de atualização de imagens.
  - Limites: o relatório de violação não traz o hash pronto, e scripts inline gerados dinamicamente só funcionam com nonce, que o proxy não injeta.
  - Desenho combinado em 2026-10-07, três fontes: (1) relatórios do navegador durante o uso real; (2) o watcher busca a URL reportada e calcula os hashes dos blocos inline; (3) navegador headless com sessão para as páginas autenticadas, rodado ao instalar ou atualizar um serviço.
  - O watcher grava a política de cada serviço como middleware na config dinâmica do Traefik (o file provider já recarrega sozinho). Hashes novos só entram sozinhos numa janela de aprendizado aberta de propósito; fora dela, cada hash novo vira um pedido de aprovação no Telegram.

### Ferramentas de Segurança & Boas Práticas
- [x] **`shellcheck`**: roda em `nix flake check`, `just lint` e no GitHub Actions (`.github/workflows/check.yml`).
- [ ] **`just scan`** (simples): receita que varre as imagens referenciadas nos `compose.yml` em busca de CVEs (ex.: `trivy image`). Só local, sem CI. O `trivy` não valida arquivos Compose, apenas as imagens.
- [ ] **Aviso de atualização de imagens** (simples): subir um serviço que notifique quando houver versão nova das imagens em uso, já que as tags estão fixas. Há um rascunho do Diun em `scratch/services_drafts/diun/compose.yml`; enviar os avisos pelo Telegram (AGENTS.md §4).
- [x] **Deploy keys**: decidido em 2026-10-07 não cadastrar. O `deploy.sh` envia tudo por `rsync` a partir do Mac e o `setup.sh` clona o `dotfiles` por HTTPS; nenhum servidor faz `git pull`. Reavaliar só se um nó precisar clonar `services-private` sem o Mac.

### Pendências da auditoria de 2026-10-06
- [x] **Deploy do rpi3** (feito em 2026-10-13; os dois arquivos antigos já foram apagados do Pi): sops-nix (`hosts/rpi3/secrets.sops.yaml`), tags de imagem fixas e ajuste do `rclone-backup` estão prontos no repositório. Aplicar com `./scripts/deploy.sh rpi3 root@rpi3 --nix` (build no Mac, ver AGENTS.md §15) mantendo uma sessão SSH aberta no Pi. Após validar, apagar no Pi os arquivos antigos `/var/lib/pihole/secrets.env` e `/var/lib/cloudflared/token.env`.
- [x] **Homebrew**: `upgrade`/`autoUpdate` desligados (atualizar com o alias `update-brew`) e `cleanup = "uninstall"` ligado em `modules/darwin/homebrew.nix`; aplicado no macmini em 2026-10-07.
- [x] **`nixfmt`**: árvore inteira formatada em 2026-10-07 (derivações dos cinco sistemas idênticas antes e depois) e `checks.nixfmt` adicionado ao flake; corrigir com `just fmt`.
- [ ] **Token do `gh` em texto puro**: o login feito via SSH gravou o token em `~/.config/gh/hosts.yml` (o Keychain do macOS não fica acessível numa sessão SSH). Depois de recriar o repositório: refazer o login na sessão gráfica do Mac (`gh auth logout && gh auth login`, que usa o Keychain) e não manter o escopo `delete_repo`.

---

## 🔑 Como testar o `rbw-menu` no Mac Mini

Implementado em 2026-10-07 e ainda **não testado contra o cofre real**. Contexto e alternativas avaliadas: `scratch/handoffs/HANDOFF-rbw-password-menu.md`.

### 1. Instalar
- [ ] `rbw --version` e `which pinentry-mac` respondem.

### 2. Configurar (uma vez por máquina)
- [ ] `rbw-menu setup <email-da-conta> <url-do-cofre>` — a senha mestra (e o 2FA, se houver) é pedida pelo pinentry.
- [ ] `rbw list` mostra as entradas do cofre.

### 3. O fluxo que falhava na extensão: gerar e salvar
- [ ] `rbw-menu gen`, com o nome `teste-rbw`. Deve aparecer "salva e confirmada no servidor".
- [ ] A entrada `teste-rbw` aparece no web vault com a mesma senha que foi para o clipboard.

### 4. Editar
- [ ] `rbw-menu`, escolher `teste-rbw`, `Ctrl-E`, trocar a senha (primeira linha) e salvar.
- [ ] A senha nova aparece no web vault.

### 5. Atalho global
- [ ] `Cmd+Ctrl+P` em qualquer app abre a janela do Kitty com o menu.
- [ ] `Enter` copia a senha e a janela fecha; colar em um campo do navegador funciona.
- [ ] `Ctrl-U` copia o usuário; `Ctrl-T` copia o TOTP de uma entrada que tenha TOTP.

### 6. Segurança
- [ ] 45 s depois de copiar, o clipboard está vazio.
- [ ] `rbw lock` e depois `Cmd+Ctrl+P`: a senha mestra é pedida de novo.

### 7. Limpar
- [ ] `rbw remove teste-rbw`.

### Se algo falhar
- **Login recusado como dispositivo desconhecido**: rodar `rbw register` e tentar o `setup` de novo.
- **O atalho não abre nada**: conferir no Karabiner-Elements se a regra aparece em Complex Modifications, e rodar `open -na kitty --args zsh -lc rbw-menu` no terminal para isolar o problema.
- **A janela abre e mostra erro**: ela fica aberta até uma tecla ser pressionada, para dar tempo de ler a mensagem.
- **Desfazer tudo**: tirar `rbw` e os pinentry de `modules/shared/cli-dev.nix`, remover a regra do Karabiner e rodar `rbw purge`.

Depois de aprovado no Mac, seguir para o item do nitro5 em "Linux Environments (NixOS)".
