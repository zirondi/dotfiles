# Ordem de trabalho

Atualizada em 2026-10-13. Este arquivo diz **o que vem agora e em que ordem**. O detalhe de cada item continua no `TODO.md`; o que depende de lugar ou momento, no `reminders.md`. Quando um bloco terminar, marque aqui e siga para o próximo.

## Agora

1. **Oracle** (bloco 3): o script está tentando criar a VM. Quando conseguir, provisionar o host.
2. **Kaly42** (bloco 4): já desbloqueado pelo Traefik unificado.
3. **Chaves e cofre** (bloco 5): em andamento pelo usuário.
4. **Em casa** (bloco 1): DHCP no Pi-hole e os aparelhos Tuya.

## 1. rpi3

Geração 26.11 ativa, com sops-nix. Roda Pi-hole e cloudflared; está no tailnet como `100.69.134.71` e anuncia `10.0.0.0/24` (rota aprovada e expiração da chave desligada).

- [x] Deploy da geração nova. Duas correções foram necessárias em `hosts/rpi3/services.nix`: imagens com `docker.io/` no nome e `--cap-add=NET_RAW` no Pi-hole.
- [x] Segredos antigos em texto puro apagados do Pi.
- [x] Tailscale como subnet router; IP registrado em `docs/network_ip_ranges.md`.
- [x] Home Assistant removido (usava 360 MB). Os dados continuam em `/var/lib/homeassistant` no Pi.
- [x] `initialPassword` removido de `hosts/rpi3/` e de `hosts/nitro5/default.nix`. Numa instalação nova o usuário nasce sem senha: definir com `ssh root@<host> passwd zirondi` (no nitro5 isso é necessário para o login gráfico e o `sudo`).
- [ ] **Pi-hole como DHCP da LAN** (em casa): ligar o DHCP do Pi-hole, desligar o do roteador e conferir que os clientes recebem `10.0.0.10` como DNS. Dá para declarar no Nix com variáveis `FTLCONF_dhcp_*` no container; confirmar os nomes na documentação do Pi-hole v6 antes.
- [ ] **Automação Tuya** (em casa): lâmpada Elgin e tomada inteligente, com um script `tinytuya` no Pi. Passos: confirmar o protocolo com a lâmpada ligada, pegar as chaves locais (conta de desenvolvedor da Tuya), e escrever a rotina que religa o macmini pela tomada quando ele parar de responder. Substitui o teste de nobreak por enquanto.
- [x] `ferdium-server` 2.0.13 no Pi, em `http://rpi3:3333`, publicado só no endereço do tailnet (limite de 256 MB; dados em `/var/lib/ferdium-server`, incluídos no `rclone-backup`). O DNS interno do Podman foi desligado no Pi, porque disputava a porta 53 com o Pi-hole.
- [ ] **Fechar o cadastro do Ferdium**: depois de criar a conta em `http://rpi3:3333/user/signup`, trocar `IS_REGISTRATION_ENABLED` para `"false"` em `hosts/rpi3/services.nix` e fazer o deploy.
- [ ] Wildcard TLS `*.rpi3.leazirondi.com.br`, quando houver um serviço web no Pi que precise.

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
- [ ] **Acompanhar**: `tmux attach -t oci` ou `tail -f ~/.oci/launch.log`. Se o Mac reiniciar, a sessão some; o comando para relançar está no fim deste bloco.
- [ ] **Upgrade para Pay As You Go** quando o cartão virar: melhora a chance de capacidade e tira a conta da regra de recuperação de instâncias ociosas. Criar um budget com alerta e ficar nos limites gratuitos (4 OCPUs, 24 GB, 200 GB de disco).
- [ ] **A decidir:** a chave de API da OCI vai para o cofre junto com as outras (bloco 5)?
- [ ] **Depois de criada:** alias em `configs/ssh/config`, host novo no flake (`aarch64-linux`, então o build roda no `nix-builder` como o do rpi3), instalação do NixOS por cima do Ubuntu, Tailscale, host key no `.sops.yaml` dos repositórios de serviços e inventários em `docs/`. Só então o backup e a redundância do Vaultwarden.

```sh
tmux new -d -s oci '~/dotfiles/scripts/oci-launch.sh --subnet ocid1.subnet.oc1.sa-saopaulo-1.aaaaaaaaem3nmnzyck4koknn3wxckjtmlq66fl6fasrxlybbazbt6yzj6tca --ssh-key ~/.ssh/main.pub'
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

## Estacionado de propósito

Não mexer até o usuário retomar:

- Stacks do `private-services` que ainda não subiram.
- Clash Party: falta um desenho para várias chaves e túneis por programa.
- Nobreak do macmini: fica atrás do teste com a tomada inteligente (bloco 1).
- NixOS no nitro5 e o tiling unificado.
- Backup incremental e redundância do Vaultwarden (dependem do bloco 3).

## Pontas soltas pequenas

- [ ] **Trocar a senha de VNC do Mac**: considerada comprometida. Ela aparece em texto claro em conversas antigas do Antigravity (`~/.gemini/antigravity/` e `~/.gemini/antigravity-cli/`), que o usuário decidiu manter por enquanto.
- [ ] Refazer o login do `gh` na sessão gráfica (token em texto puro em `~/.config/gh/hosts.yml`).
- [ ] Apagar o túnel e o Access antigos do acesso remoto ao Mac na Cloudflare.
