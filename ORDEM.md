# Ordem de trabalho

Definida em 2026-10-13. Este arquivo diz **o que vem agora e em que ordem**. O detalhe de cada item continua no `TODO.md`; o que depende de lugar ou momento, no `reminders.md`. Quando um bloco terminar, marque aqui e siga para o próximo.

## 1. Fechar o rpi3

Estado em 2026-10-13: a geração nova (26.11, sops-nix) está ativa, mas o Pi-hole e o cloudflared não subiram nela, porque as imagens estavam sem `docker.io/` no nome. A correção está em `hosts/rpi3/services.nix` e já foi construída no `nix-builder`; falta ativar. O Tailscale está instalado e **deslogado**.

- [x] Deploy da geração nova (sops-nix, tags fixas, `rclone-backup`).
- [ ] **Redeploy com a correção das imagens**: `./scripts/deploy.sh rpi3 root@rpi3 --nix`. Validar com `ssh root@rpi3 'podman ps'` e `dig @10.0.0.10 example.com +short`.
- [ ] **Apagar os segredos antigos** no Pi depois de validar: `/var/lib/pihole/secrets.env` e `/var/lib/cloudflared/token.env` (cópias em texto puro do que agora vem de `/run/secrets/`).
- [ ] **`git push`** dos 4 commits locais (builder, sops-nix do rpi3, Homebrew, docs), junto com o commit da correção.
- [ ] **Pi-hole como DNS e DHCP da LAN**: ligar o DHCP do Pi-hole, desligar o do roteador e conferir que os clientes recebem `10.0.0.10` como DNS. Fazer antes do subnet router.
- [ ] **Tailscale**: `ssh root@rpi3 tailscale up --advertise-routes=10.0.0.0/24` (o `ip_forward` já está ligado em `hosts/rpi3/services.nix`), aprovar a rota no painel e desligar a expiração da chave do nó.
- [ ] **Registrar o IP `100.x`** do Pi em `docs/network_ip_ranges.md` e `docs/infrastructure_inventory.md`.
- [ ] **`ferdium-server`**: a imagem tem build `arm64`. Onde roda (rpi3 ou macmini) e como é exposto ainda estão em aberto.
- [x] `initialPassword` removido de `hosts/rpi3/` e de `hosts/nitro5/default.nix`. Numa instalação nova o usuário nasce sem senha: definir com `ssh root@<host> passwd zirondi` (no nitro5 isso é necessário para o login gráfico e o `sudo`).

Fica para depois do bloco 2: wildcard TLS `*.rpi3.leazirondi.com.br`, que depende do Pi no tailnet e do Traefik unificado.

## 2. Traefik em um stack só

Feito em 2026-10-13 no `hetzner`.

- [x] Submódulo `services/` como única cópia de trabalho (regra no `AGENTS.md` §9); `mail` e `vaultwarden` trazidos para ele.
- [x] Stack `traefik-cloudflared` → `traefik`, com os dois `cloudflared` no mesmo compose.
- [x] Redes: `cloudflared-network`, `tunnel-network` e `public-network`. A `edge-network` antiga ainda existe no servidor só porque os containers parados do RISE e da SECComp estão presos a ela.
- [x] Três entrypoints: `web` (túnel), `websecure` (preso ao IP do Tailscale) e `public` (preso ao IP público, 443 ainda fechada no firewall).
- [x] Wildcard `*.hetzner.leazirondi.com.br` emitido pela CA de produção; piloto `whoami.hetzner.leazirondi.com.br` respondendo pelo tailnet.
- [x] `AGENTS.md` (§9, §10, §14), `services/.template` e `scripts/test-compose.sh` atualizados.
- [ ] **Push** dos commits do `services` (branch `dev`) e do `dotfiles`.
- [ ] **Limpar o checkout irmão** `~/repos/github/me/public/services`: tirar `mail/` e `vaultwarden/` de lá e dar `git pull` depois do push. Ele guarda segredos decriptados em `secrets/`, então conferir antes de apagar.
- [ ] **Stacks parados na troca de redes** (`rise-website`, `rise-seccomp`, `seccomp-points`, `rise-aula-man`): para voltarem, trocar `edge-network` por `tunnel-network` no compose de cada repositório e reenviar.
- [ ] **zirondi.tech**: o token de DNS da Cloudflare precisa de permissão de edição nessa zona antes do primeiro certificado.
- [ ] Kanidm segue desligado (container removido, dados em `~/volumes/kanidm`) até o bloco de identidade.

## 3. Oracle: conseguir a instância Always Free

- [ ] Script em `scripts/` que tenta criar a instância pela API da OCI e repete enquanto a resposta for "Out of host capacity", parando no primeiro sucesso e avisando.
  - Shape `VM.Standard.A1.Flex` (ARM) em São Paulo; intervalo entre tentativas com folga para não bater no limite de requisições.
  - Parâmetros por argumento ou ambiente (compartment, subnet, imagem, AD, shape); nada fixo no script (`AGENTS.md` §5).
  - A pubkey autorizada na criação é a `main` (trocar pela `sol` no bloco 5).
- [ ] `oci-cli` declarado em `modules/shared/cli-dev.nix`.
- [ ] **A decidir:** onde fica a chave de API da OCI (`~/.oci/` em disco, como as chaves SSH hoje, ou no cofre). Vale a regra do `AGENTS.md` §16.
- [ ] Depois de criada: host novo no flake (`aarch64-linux`, então o build roda no `nix-builder` como o do rpi3), alias em `configs/ssh/config`, Tailscale, host key no `.sops.yaml` dos repositórios de serviços e inventários em `docs/`.

## 4. Kaly42

Só depois do bloco 2. Registro `*.kaly` (DNS only), 443 aberta no `hetzner` e stack do Docmost na `public-network`. Detalhe no `TODO.md`.

## 5. Chaves e cofre

Em andamento pelo usuário: organização do cofre. Nesta ordem:

1. Chaves `sol`, `luna` e `terra` (gerar, publicar, autorizar ao lado da `main`, testar, remover a `main`).
2. Inventário dos segredos no cofre.
3. Teste do `rbw-menu` e os commits pendentes (`reminders.md`).
4. Chaves SSH servidas pelo `rbw-agent`.

## Estacionado de propósito

Não mexer até o usuário retomar:

- Stacks do `private-services` que ainda não subiram.
- Clash Party: falta um desenho para várias chaves e túneis por programa.
- Nobreak do macmini: antes, testar o religamento com uma tomada inteligente.
- CTFs do RISE no `hetzner`: parados de propósito.
- NixOS no nitro5 e o tiling unificado.
- Backup incremental e redundância do Vaultwarden (dependem do bloco 3).

## Pontas soltas pequenas

- [ ] Refazer o login do `gh` na sessão gráfica (token em texto puro em `~/.config/gh/hosts.yml`).
- [ ] Trocar a senha de VNC do Mac e apagar `~/.gemini/antigravity/brain/1459407b-*`, que a repete em texto claro.
- [ ] Apagar o túnel e o Access antigos do acesso remoto ao Mac na Cloudflare.
