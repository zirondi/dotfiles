# AI Agent Handoff Logs

Este arquivo serve como um registro contínuo ("passagem de bastão") entre diferentes sessões de IA. O objetivo é manter o contexto sobre decisões de arquitetura e modificações recentes antes que elas sejam agrupadas em commits formais pelo usuário.

*Aviso: Este arquivo deve ser limpo periodicamente pelo usuário após realizar commits significativos, mantendo apenas o histórico recente para poupar o consumo de contexto (tokens).*

---

## [2026-09-29] - Auditoria Completa e Reorganização dos Documentos Markdown

**Contexto:** Realizada a varredura completa de todos os arquivos de texto (.md) da raiz e de `docs/`. Identificadas inconsistências (falta de README na raiz, caminhos desatualizados e duplicatas) e executado o saneamento aprovado pelo usuário.

**O que foi feito:**
1. **Criação do [README.md](file:///Users/zirondi/repos/github/me/public/dotfiles/README.md) Principal:**
   - Criada a vitrine oficial do monorepo, detalhando arquitetura multi-OS (Nix Flakes, nix-darwin, NixOS, Home Manager), tabela de hosts, mapa de diretórios, convenções de segurança SOPS/Age e guia de início rápido.
2. **Reorganização de Guias Transutórios:**
   - Movidos os guias soltos na raiz para a pasta de documentação: `Guia_de_Transicao.md` -> [docs/guia_de_transicao.md](file:///Users/zirondi/repos/github/me/public/dotfiles/docs/guia_de_transicao.md) e `guia-ghcr-submodules.md` -> [docs/guia_ghcr_submodules.md](file:///Users/zirondi/repos/github/me/public/dotfiles/docs/guia_ghcr_submodules.md) (com limpeza de tags cruas de citação).
3. **Eliminação de Duplicatas e Atualização de Runbooks:**
   - Removido `docs/AGENTS.md`, mantendo unicamente a fonte da verdade em [AGENTS.md](file:///Users/zirondi/repos/github/me/public/dotfiles/AGENTS.md) na raiz do repositório.
   - Corrigidos caminhos obsoletos (`system/nixos` -> `hosts/`) em [docs/host-management.md](file:///Users/zirondi/repos/github/me/public/dotfiles/docs/host-management.md) e atualizado [docs/rpi_setup_guide.md](file:///Users/zirondi/repos/github/me/public/dotfiles/docs/rpi_setup_guide.md).
   - Reescrito [docs/contributing.md](file:///Users/zirondi/repos/github/me/public/dotfiles/docs/contributing.md) para refletir o fluxo de validação real do monorepo (`nix flake check`, `nixfmt`, `test-compose.sh`).
4. **Limpeza do [TODO.md](file:///Users/zirondi/repos/github/me/public/dotfiles/TODO.md):**
   - Removidas as tarefas já concluídas, mantendo estritamente a lista ativa de commits e o backlog futuro.

---

## [2026-09-29] - Conclusão das Ações Pré-Commit: Higiene de Secrets, Skills.sh e Polkit i3

**Contexto:** Executadas todas as ações prioritárias de pré-commit aprovadas pelo usuário antes do início dos commits formais no monorepo e nos repositórios de serviços.

**O que foi feito:**
1. **Higiene Crítica de Segurança em `public/services`:**
   - Criado [public/services/.gitignore](file:///Users/zirondi/repos/github/me/public/services/.gitignore) para ignorar estritamente segredos não criptografados, logs e overrides locais.
   - Criptografados com Age via SOPS os segredos pendentes: `traefik-public/secrets/cloudflare_dns_api_token.sops.yaml`, `mac-remote-access/secrets/tunnel_token.sops.yaml`, `csp-watcher/secrets/TELEGRAM_*.sops.yaml`, `vaultwarden_*/secrets/*.sops.yaml`.
   - Removidos do staging Git todos os arquivos de segredos em texto puro (`git rm --cached`).
2. **Sincronização Declarativa de Skills de IA via `skills.sh`:**
   - Preservado o lockfile com as 12 habilidades globais em [configs/agents/.skill-lock.json](file:///Users/zirondi/repos/github/me/public/dotfiles/configs/agents/.skill-lock.json) sem poluir o Git com o cache de código baixado (`skills/` adicionado ao `.gitignore`).
   - Declarado link simbólico `~/.agents/.skill-lock.json` e script de ativação condicional com fallback offline em [modules/shared/home.nix](file:///Users/zirondi/repos/github/me/public/dotfiles/modules/shared/home.nix).
   - Criado script auxiliar [scripts/sync-skills.sh](file:///Users/zirondi/repos/github/me/public/dotfiles/scripts/sync-skills.sh) e adicionado alias `sync-skills` em [configs/zsh/shared/aliases.zsh](file:///Users/zirondi/repos/github/me/public/dotfiles/configs/zsh/shared/aliases.zsh).
3. **Suporte a Polkit no Nitro 5 (i3):**
   - Configurado `polkit_gnome` e o serviço systemd de usuário `polkit-gnome-authentication-agent-1` em [hosts/nitro5/default.nix](file:///Users/zirondi/repos/github/me/public/dotfiles/hosts/nitro5/default.nix) para prover caixas de diálogo gráficas de autenticação root no i3.
   - Avaliação Nix verificada com sucesso (`.drv` gerado limpo).
4. **Atualização do [TODO.md](file:///Users/zirondi/repos/github/me/public/dotfiles/TODO.md):**
   - Todas as 4 pendências pré-commit foram marcadas como concluídas. O repositório está pronto para o ciclo de commits.

---

## [2026-09-29] - Refatoração de Scripts, Paridade SSH e Higienização de Testes

**Contexto:** Revisão completa dos scripts de manutenção e deploy em `scripts/`. Identificada redundância na especificação de alvos SSH vs. Flake hosts, além de portas hardcodeadas que quebravam deploys para máquinas diferentes da Hetzner.

**O que foi feito:**
1. **Refatoração do `deploy.sh` & `update.sh`:**
   - Eliminada a porta 42721 hardcodeada (`ssh -p 42721` e `rsync -e "ssh -p 42721"`). Agora a porta, usuário e chave são lidos diretamente do `configs/ssh/config`.
   - Simplificado o parsing de argumentos: `./deploy.sh <flake-host>` assume automaticamente que o destino SSH é o alias de mesmo nome (ex: `./deploy.sh nitro5`), com suporte a sobrescrita manual opcional.
   - Adicionado alias `hetzner helsinki` em `configs/ssh/config` para interoperabilidade total.
   - Implementada cadeia de busca de serviços (`find_service_dir`): busca primeiro em `$SERVICES_DIR`, depois na pasta local de trabalho `~/repos/.../services` e `private-services`, e por fim no submódulo `$DOTFILES_FLAKE/services`.
2. **Simplificação do `clean.sh` & Remoção de `investigate.sh`:**
   - `clean.sh` atualizado para aceitar alias de host do SSH diretamente (com default para `localhost`) e execução remota com `sudo`.
   - Removido `scripts/investigate.sh`, pois era um wrapper redundante sobre o comando nativo `ssh <host>`.
3. **Higienização do Monorepo:**
   - Excluídos arquivos de teste órfãos da raiz: `patch.py`, `test_kitty.sh`, `test_secret.sops.yaml` e `test_secret.txt`.
   - Incluídos no rastreamento: `scripts/start-comfyui.sh` e `configs/clash-party/.gitkeep`.
4. **Governança (`AGENTS.md`):**
   - Adicionada a regra **11. SSH & Host Parity in Custom Scripts**, proibindo portas hardcodeadas e determinando o `~/.ssh/config` como autoridade única de conectividade.

---

## [2026-09-29] - Consolidação dos Dotfiles Legados (`configs/`) no Monorepo Definitivo

**Contexto:** Realizada a análise comparativa entre as pastas legadas em `public/configs/` (`dotfiles-1`, `dotfiles-2` e `server-stuff`) e o monorepo consolidado `public/dotfiles/`. A máquina Acer Nitro 5 foi recentemente formatada, o que exigiu separar arquivos obsoletos (UUIDs estáticos de disco e LUKS pré-formatação) das configurações de hardware e desktop reais a serem preservadas.

**O que foi feito:**
1. **Resgate de Configurações Críticas do Nitro 5 (`hosts/nitro5/`):**
   - Configurado teclado físico ABNT2 (`console.keyMap = "br-abnt2"`, `xkb = { layout = "br"; variant = "nodeadkeys"; }`).
   - Adicionada suíte de desktop para o ambiente i3: `networkmanagerapplet`, `pavucontrol` e `nemo`.
   - Habilitado suporte completo ao 1Password (`programs._1password` e `_1password-gui` com `polkitPolicyOwners = [ "zirondi" ]`).
   - Atualizado `nixpkgs.config.allowUnfreePredicate` dinâmico para cobrir 1Password e drivers NVIDIA (`nvidia-*`).
   - Atualizado [hosts/nitro5/nvidia.nix](file:///Users/zirondi/repos/github/me/public/dotfiles/hosts/nitro5/nvidia.nix) com os PCI Bus IDs reais testados no hardware (`amdgpuBusId = "PCI:5:0:0"`, `nvidiaBusId = "PCI:1:0:0"`) e drivers `[ "amdgpu" "nvidia" ]`.
2. **Camada de Áudio e Locais no NixOS (`modules/nixos/common.nix`):**
   - Habilitado áudio via PipeWire (`alsa`, `alsa.support32Bit`, `pulse`, `rtkit`).
   - Configurado `i18n.extraLocaleSettings` com `pt_BR.UTF-8` para formatação de moeda, datas e medidas brasileiras.
   - Adicionados utilitários essenciais de hardware/disco: `pciutils`, `cryptsetup`, `parted`.
   - Desativado PipeWire explicitamente em hosts headless e de memória restrita (`rpi3` com 1GB RAM e `hetzner` VPS).
3. **Módulos Compartilhados Universais (`modules/shared/`):**
   - Adicionado `download-buffer-size = 256 * 1024 * 1024;` em `modules/shared/common.nix`.
   - Adicionadas ferramentas de diagnóstico e monitoramento universais (`btop`, `htop`, `tree`, `lsof`) em `modules/shared/cli-tools.nix`.
   - Corrigido symlink de `~/.zshrc_essentials` em `modules/shared/home.nix`.
4. **Integração no Flake (`flake.nix`):**
   - Adicionados inputs `vscode-server` (`github:nix-community/nixos-vscode-server`) e `zen-browser` (`github:youwen5/zen-browser-flake`).
   - Configurado `services.vscode-server` com `nodejsPackage = pkgs.nodejs` para mitigar a remoção do Node.js 20 no nixpkgs-unstable.
   - Injetado `zen-browser` no host `nitro5`.
5. **Documentação Resgatada (`docs/`):**
   - Copiados os guias `rpi_setup_guide.md` e `rpi_tailscale_setup.md` da pasta legada `server-stuff/rpi/` para `docs/`.
   - Adicionados ao controle do Git via `git add` para conformidade com a avaliação do Flake.

**Decisões de Arquitetura:**
- O template [hosts/nitro5/hardware-configuration.nix](file:///Users/zirondi/repos/github/me/public/dotfiles/hosts/nitro5/hardware-configuration.nix) permanece como placeholder/template: o script `setup.sh` do bootstrap cuidará da geração limpa com os novos UUIDs na reinstalação física da máquina.
- As pastas em `public/configs/` (`dotfiles-1`, `dotfiles-2`) permanecem intocadas até que o usuário autorize seu arquivamento para `archive/`.

---

## [2026-09-29] - Auto-Patch Dinâmico de Contexto do Ollama & Sincronização OpenCode

**Contexto:** O modelo `deepseek-r1:8b` (e qualquer novo modelo baixado via `ollama pull`) vinha com o padrão de fábrica de 4.096 tokens. Quando o OpenCode consome o Ollama via endpoint OpenAI (`/v1`), o Ollama ignora variáveis globais e impõe o limite de contexto do modelo original, causando erros de `exceed_context_size_error`. Além disso, Modelfiles estáticos geravam falhas de rede (503) durante o rebuild e retrabalho manual.

**O que foi feito:**
1. **Auto-Patch Dinâmico e Idempotente (`modules/shared/home.nix`):**
   - Substituídos os arquivos estáticos de Modelfile por uma rotina no hook `home.activation.buildOllamaModels`.
   - O hook varre todos os modelos locais retornados por `ollama list`.
   - Verifica via `ollama show <modelo> --modelfile` se o modelo já possui `num_ctx 32768`.
   - Caso não possua, aplica o patch de 32.768 tokens em tempo de execução via pipe (`printf "FROM %s\nPARAMETER num_ctx 32768\n" | ollama create <modelo> -f /dev/stdin`).
   - Se todos os modelos já estiverem com 32k, a execução é instantânea e 100% offline (elimina o erro 503 do Ollama registry).
2. **Sincronização do OpenCode (`configs/opencode/opencode.json`):**
   - Adicionada a flag `"reasoning": true` explicitamente aos modelos `deepseek-r1:14b` e `deepseek-r1:8b`, permitindo que o OpenCode gerencie corretamente o streaming das tags `<think>` e o parâmetro `reasoningEffort`.
3. **Limpeza de Arquivos Estáticos:**
   - Removidos os links do `home.file` e deletados os arquivos estáticos em `configs/ollama/*.Modelfile`.

**Decisões de Arquitetura:**
- O Nix agora cuida do teto de contexto de forma transparente: qualquer modelo baixado no futuro receberá automaticamente os 32k tokens no próximo `darwin-rebuild switch`.
- OpenCode mantém a política restrita de provedores locais (`allow: ollama-local`, `deny: *`), agora com total suporte aos modelos de reasoning locais.

---

## [2026-09-27] - Paridade de Teclado macOS ↔ NixOS

**Contexto:** O usuário deseja uniformizar a experiência de teclado entre o Mac Mini M1 (nix-darwin) e o Acer Nitro 5 (NixOS com i3). O foco principal é: Home/End como início/fim de linha no macOS, CapsLock→Escape em ambos os sistemas, e manter muscle memory do macOS no Linux via Kitty.

**O que foi feito:**
1. **`modules/darwin/keyboard.nix`** (NOVO):
   - `system.keyboard.enableKeyMapping = true` + `remapCapsLockToEscape = true` via hidutil.
   - `targets.darwin.keybindings` (home-manager) gera `~/Library/KeyBindings/DefaultKeyBinding.dict`:
     Home/End = linha, Cmd+Home/End = documento, com variantes Shift para seleção.
   - Importado no `flake.nix` (macmini modules).

2. **`modules/nixos/keyd.nix`** (NOVO):
   - CapsLock → Escape, Shift+CapsLock → CapsLock via `services.keyd`.
   - **Decisão Crítica:** NÃO fazemos swap Super↔Ctrl system-wide porque:
     (a) i3 usa Super como $mod — swap quebraria o WM.
     (b) keyd opera no evdev (kernel), antes do Kitty interceptar — Super+C viraria Ctrl+C = SIGINT.
     (c) Kitty's `linux.conf` já provê paridade macOS (Super/cmd+C = copy, etc.)
   - Importado em `hosts/nitro5/default.nix`.

3. **`configs/zsh/shared/keybindings.zsh`** (NOVO):
   - Bindkeys para Home, End, Delete, Ctrl+Left/Right (word jump), Ctrl+Backspace (word delete).
   - Cobre tanto xterm-style quanto application-mode escape sequences.
   - Auto-carregado pelo loop `shared/*.zsh` do `.zshrc`.

4. **`configs/kitty/kitty.conf`** (MODIFICADO):
   - Adicionados mapeamentos universais: Home/End → escape sequences de linha, Ctrl+Home/End → scroll_home/scroll_end.

5. **`hosts/nitro5/default.nix`** (MODIFICADO):
   - Habilitado i3 como WM + LightDM como display manager + dmenu/i3status/i3lock.
   - Configurado key repeat para paridade com macOS: `autoRepeatDelay = 225`, `autoRepeatInterval = 33`.

**Decisões de Arquitetura:**
- Configurações Darwin-only vivem em `modules/darwin/` (não em `home.nix` compartilhado).
- `home-manager.users.zirondi` é mergido pelo Nix module system — keyboard.nix adiciona `targets.darwin.keybindings` sem conflitar com o home.nix compartilhado.
- Navegação de documento no macOS usa `@` (Cmd) ao invés de `^` (Ctrl), alinhando com a filosofia macOS.

**Pendências / Ações Futuras:**
- **i3 config:** Apenas habilitado com defaults. Uma configuração customizada completa (`configs/i3/config`) com keybindings, gaps, e estética deve ser criada em uma sessão futura.
- **Conflito i3 × Kitty:** `cmd+1-9` (goto_tab) no `linux.conf` do Kitty conflita com `$mod+1-9` (workspace) do i3, pois ambos usam Super. O usuário precisará decidir como resolver (ex: Alt+1-9 para tabs no Kitty).

*(Atualização: Karabiner-Elements já foi adicionado ao macmini com mapeamento de CapsLock → Escape e Shift+CapsLock → CapsLock).*

---

## [2026-09-08] - Reestruturação de Serviços, Suporte a Podman e Host Hetzner

**Contexto:** Nas últimas iterações, houve um esforço coordenado para estruturar o monorepo de forma a acomodar uma nova máquina na nuvem (Hetzner) e implantar um catálogo abrangente de serviços containerizados, rodando nativamente via Podman no NixOS.

**O que foi feito:**
1. **Infraestrutura e Provisionamento:** 
   - Adicionada a configuração inicial para a VPS `hetzner` (`hosts/hetzner/`).
   - Escrito um guia para provisionamento remoto usando `nixos-anywhere` (`docs/nixos_anywhere_guide.md`).
   - Atualizados os inputs/outputs do `flake.nix` para incluir a nova máquina.
2. **Runtime de Containers (Podman):** 
   - Criado e importado o módulo `modules/nixos/podman.nix` habilitando Podman + Podman Compose como o motor padrão para NixOS.
3. **Catálogo de Serviços Compose:**
   - Criada a infraestrutura base na pasta `services/`, contendo templates, guia de uso (`README.md`) e script unificado de deploy (`scripts/deploy.sh`).
   - Implementada arquitetura segura de proxy reverso (`traefik-public`, `traefik-cloudflared` e `socket-proxy`).
   - Adicionados diversos stacks de aplicações (ex: `homeassistant`, `pihole`, `n8n`, `calibre-web`, `duplicati`, `csp-watcher`, entre outros).
4. **Governança de Agentes:** 
   - `AGENTS.md` atualizado com a nova regra de "Agent Handoff Logging" (o que originou este arquivo).
5. **Dotfiles Pessoais:** 
   - Pequenos ajustes de workflow em `configs/ssh/config` e aliases no ZSH.

**Pendências / Ações Requeridas pelo Usuário:**
- Realizar o agrupamento e o commit destas modificações que estão pendentes na *working tree* local.
- Limpar/resetar este log caso considere que o novo "estado zero" no Git dispensa este contexto para as próximas sessões.

## [2026-09-08] - Sops-Nix Secrets & Testagem Local (Mac/Podman)

**Contexto:** O usuário precisava testar as dezenas de `docker-compose` da pasta `services/` localmente em seu Mac e estabelecer a arquitetura criptográfica para gerenciar os arquivos de *secrets*.

**O que foi feito:**
1. **Arquitetura SOPS (sops-nix):**
   - Adicionado o input `sops-nix` no `flake.nix` e integrado nos módulos NixOS (Hetzner, RPi3, Nitro5) e darwin (Mac Mini).
   - Criado o arquivo raiz `.sops.yaml` orientando a criptografia para as pastas de serviço (`services/**/*.sops.yaml`) utilizando exclusivamente chaves `age` (ED25519).
   - As chaves `age` dos hosts foram derivadas das chaves `ssh_host_ed25519_key` automaticamente (`ssh-keyscan | ssh-to-age`), eliminando a necessidade de gerenciar o `age-keygen` no lado do servidor.
2. **Ambiente Mac / Darwin (Podman):**
   - Removido o `docker-desktop` do `modules/darwin/homebrew.nix` e substituído pelo ecosistema Podman (`podman`, `podman-compose`, `podman-desktop`).
   - Adicionados aliases nativos para que o `docker` aponte para o `podman` no macOS, mantendo o `socket-proxy` seguro.
3. **Script de Testagem Local:**
   - Escrito `scripts/test-compose.sh` que provisiona automaticamente as redes base (`edge-network`, `socket-proxy`), cria stubs para secrets pendentes e roda o motor de containers (Podman) localmente.
   - Adicionado suporte a emulação forçada para x86 (`--amd64`) caso seja necessário burlar os manifestos arm64 no Apple Silicon.
4. **Governança:**
   - Adicionada a seção 10 no `AGENTS.md` descrevendo o uso do `test-compose.sh` e a estrutura do `sops-nix`.

## [2026-09-08] - Deploy Iterativo, Fix SELinux/Podman, Unificação Cloudflared

**Contexto:** O usuário queria deployar serviços individualmente por host (em vez de sincronizar todos), testar localmente no Mac via Podman, e entender o fluxo completo de secrets (local vs produção).

**O que foi feito:**
1. **Deploy Iterativo (`deploy.sh`):**
   - Reescrito para aceitar `--svc <svc1> <svc2>` com rsync isolado por serviço (não toca serviços existentes no host).
   - Validação pré-deploy: verifica se os `.sops.yaml` existem antes de enviar.
   - Decriptação automática via SSH no host remoto + auto-start com `podman-compose up -d`.
2. **Gerador de Secrets (`init-secrets.sh`):**
   - Novo script que escaneia `compose.yml`, detecta secrets declarados, e cria stubs SOPS criptografados automaticamente.
3. **Fix Crítico: SELinux no Podman Machine (Mac):**
   - Descoberto que o erro 503 do socket-proxy era causado pelo SELinux do Fedora CoreOS (VM do Podman), não por permissões Unix.
   - `test-compose.sh` agora gera um `compose.override.yml` temporário com `label=disable` para serviços que montam o docker.sock.
   - `socket-proxy/compose.yml` usa `${DOCKER_SOCK:-/var/run/docker.sock}` para flexibilidade Mac/Linux.
4. **Unificação Cloudflared:**
   - `cloudflared` movido para dentro de `traefik-cloudflared/compose.yml` na rede `tunnel` (antes usava `network_mode: host` separado).
   - Convertido de `env_file` para Docker `secrets:` (compatível com fluxo SOPS).
   - `n8n/compose.yml`: labels do Traefik alterados de `websecure` (TLS/443) para `web` (HTTP/80) para compatibilidade com tunnel.
5. **Melhorias no `test-compose.sh`:**
   - Abas automáticas do Kitty com logs (`kitty @ launch`) usando `zsh -lc` para carregar PATH correto.
   - Imagem do N8N trocada para `n8nio/n8n` (evita rate limit do registry custom `docker.n8n.io`).

**Decisões de Arquitetura:**
- **Modelo de segurança escolhido:** Cloudflare Tunnel (Zero Trust) — firewall do Helsinki totalmente fechado, sem portas expostas além de SSH.
- **Secrets:** Arquivos `.sops.yaml` individuais por secret (1:1 mapping), decriptados no host remoto pelo `deploy.sh`.
- **Separação Local/Produção:** `test-compose.sh` para Mac (dummy secrets, SELinux bypass), `deploy.sh` para Helsinki (SOPS real).

**Próximos Passos:**
- Criar tunnel no painel Cloudflare Zero Trust e gerar o `TUNNEL_TOKEN`.
- Rodar `init-secrets.sh` para gerar os stubs SOPS e preencher com valores reais.
- Verificar pré-requisitos no Helsinki (sops, podman-compose, chave age derivada do SSH).
- Deploy final: `./deploy.sh hetzner helsinki --svc socket-proxy traefik-cloudflared n8n`.

## [2026-09-12] - Fix mDNS DDoS Vulnerability on Hetzner Host (BSI Abuse Report)

**Contexto:** O usuário recebeu um alerta do CERT-Bund (BSI Alemanha) informando que o IP do Hetzner VPS (`helsinki`) estava anunciando informações de Workstation publicamente na internet via mDNS (porta 5353 UDP aberta), configurando risco de "DDoS reflection attacks".

**O que foi feito:**
1. **Identificação da Falha:** Identificado que o módulo `modules/nixos/common.nix` habilitava o `services.avahi` e explicitamente expunha a porta 5353 (`networking.firewall.allowedUDPPorts = [ 5353 ]`) na interface externa. Como o Hetzner compartilha este módulo comum de NixOS, ele publicava o mDNS na internet pública inadvertidamente.
2. **Resolução de Segurança:** Modificado especificamente o arquivo `hosts/hetzner/default.nix` para desabilitar agressivamente (com `lib.mkForce`) a stack do Avahi e fechar as portas UDP abertas (sobrescrevendo para `[]`) exclusivamente no node da VPS, preservando a utilidade do mDNS nos setups caseiros (Nitro5, RPi3, MacMini).

**Pendências / Ações Requeridas pelo Usuário:**
- Realizar deploy imediato destas configurações para o servidor Hetzner (ex: `./deploy.sh hetzner <target-ip/host> --nix`) para cessar o anúncio inseguro do mDNS e sanar o "Abuse Report" ativamente.

## [2026-09-16] - Mac Mini Remote Access Stack (Temporário)

**Contexto:** O usuário precisava acessar o Mac Mini M1 remotamente via browser (terminal SSH + desktop VNC) de forma temporária e segura, usando Cloudflare Tunnel + Access OTP como camada de autenticação.

**O que foi feito:**
1. **Stack `services/mac-remote-access/`:**
   - Criado `compose.yml` com 4 containers: `cloudflared` (túnel standalone dedicado), `wetty` (terminal SSH web), `guacd` + `guacamole` (desktop VNC web, modo leve sem DB).
   - Rede isolada `mac-remote-net` (não usa `edge-network` de produção).
   - Sem portas expostas no host. VNC (5900) e SSH (22) acessíveis apenas via rede Docker interna.
   - `TUNNEL_TOKEN_FILE=/run/secrets/tunnel_token` para leitura segura do token via Docker secrets.
   - `security_opt: [no-new-privileges=true]` em todos os containers.
2. **Configuração Guacamole:**
   - `guacamole.properties` mínimo (sem PostgreSQL).
   - `user-mapping.xml.example` como template (`.gitignore` protege a versão real com senhas).
3. **Documentação:**
   - `README.md` completo com checklists de setup (macOS Screen Sharing/Remote Login, Cloudflare Dashboard tunnel/access, Guacamole, troubleshooting).

**Decisões de Arquitetura:**
- **Túnel standalone** (não reutiliza o `traefik-cloudflared` de produção) — isolamento total, fácil de criar/destruir.
- **Rotas via Dashboard Cloudflare** (sem `config.yml` local) — mais prático para setup temporário.
- **Wetty preserva config completa do terminal** — faz SSH real no macOS, carregando zsh/starship/aliases/home-manager.
- **Cloudflare Access OTP** como autenticação principal para ambos os endpoints (terminal + desktop).

**Estado do Runtime:**
- Docker Desktop instalado mas parado no Mac Mini.
- Podman 6.1.1 instalado (VM `podman-machine-default` nunca iniciada).
- Usuário precisa iniciar Docker Desktop ou `podman machine start` antes de subir o stack.

**Pendências / Ações Requeridas pelo Usuário:**
- Iniciar Docker Desktop (ou Podman).
- Seguir checklist do `README.md` para configurar macOS, Cloudflare, e Guacamole.
- Criar túnel no Cloudflare Zero Trust Dashboard e salvar token em `secrets/tunnel_token`.


## [2026-09-17] - Apresentação "Por Dentro do Linux" (Linux SECCOMP)

**Contexto:** O usuário solicitou a criação de um novo material de apresentação baseado no formato `presenterm` (visto em `rise-seccomp`), porém totalmente adaptado para rodar em um notebook Ubuntu em uma palestra ao vivo ("Mão na massa").

**O que foi feito:**
1. **Estrutura Base:** Criada a pasta `services/linux-seccomp` para abrigar a nova apresentação.
2. **Slides e Roteiro:** 
   - Gerado `slides.md` tematizado (dark, rosa/azul) aproveitando o formato do `presenterm` com `<!-- pause -->` e alinhamentos.
   - Construído `ROTEIRO_PROFESSOR.md` formatado em tabela para controle fluído de comandos pelo palestrante.
3. **Isolamento de Terminal (`apresentar.sh`):**
   - Adaptado script para `kitty` no Ubuntu. Removemos as flags de Mac.
   - **Decisão Crítica (Paridade UX):** A regra do repositório (`AGENTS.md` Rule 2) exige paridade com o macOS. Mantivemos os atalhos como `cmd+<num>`, garantindo compatibilidade com o mapeamento nativo `Super` do host Linux.
   - Cores e tema visual injetados *inline* no comando para que a aula tenha estilo Ubuntu (roxo/laranja) sem afetar os arquivos globais do `home-manager`/`kitty` da máquina.
4. **Scripts Práticos (Demonstração):**
   - Escritos `scripts/zombie.py`, `scripts/mem_leak.py` e `scripts/io_test.sh` automatizando testes pesados (OOM, defunct, I/O) mencionados nos slides.
   - Definidos com permissão de execução explícita (`chmod +x`).
5. **Dependências:**
   - O usuário escolheu usar o binário CLI puro do Ubuntu em vez do `nix run`. O `apresentar.sh` foi atualizado de acordo. O comando de setup `apt` foi providenciado no chat.

**Pendências / Ações Requeridas pelo Usuário:**
- Instalar as dependências via apt (`htop`, `strace`, `lsof`, `sysstat`, `tmux`, `kitty`).
- Instalar o executável do `presenterm` (via release do GitHub ou cargo) uma vez que foi removido o proxy por Nix.

---

## [2026-09-28] - Setup Clash Party (Mihomo) & Automação de Secrets com Age

**Contexto:** O usuário precisava configurar roteamento de tráfego por aplicativo (per-app / split-tunneling) e múltiplos túneis WireGuard simultâneos no macOS, integrando de forma segura os segredos no monorepo de dotfiles sem expor chaves privadas no Git.

**O que foi feito:**
1. **Homebrew & Cask (`modules/darwin/homebrew.nix`):**
   - Identificada a renomeação oficial do `mihomo-party` para `clash-party` no Homebrew Cask oficial.
   - Removido tap incorreto/redundante (`mihomo-party-org/mihomo-party`) e atualizado cask para `clash-party`.
2. **Automação de Segredos (`scripts/init-secrets.sh`):**
   - Expandido o script para suportar `./scripts/init-secrets.sh clash-party [--encrypt|--decrypt]`.
   - Gera template dummy em `configs/clash-party/config.yaml` com suporte a múltiplos túneis WireGuard e regras `PROCESS-PATH-REGEX` para Electron (Discord).
   - Criptografa/descriptografa o arquivo utilizando a chave pública/privada do SOPS (`admin_zirondi`) via `age`.
3. **Segurança de Versionamento (`.gitignore`):**
   - Adicionada regra ignorando `configs/clash-party/*.yaml` e permitindo apenas `*.age` e `.gitkeep`.
4. **Estrutura Base Criada:**
   - Criada a pasta `configs/clash-party/` com `.gitkeep` e o `config.yaml` dummy pronto para ser editado e criptografado.
