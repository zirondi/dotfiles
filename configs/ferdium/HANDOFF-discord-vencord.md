# Handoff: Ferdium com Discord + Vencord

Contexto para retomar o trabalho no cliente Ferdium: a receita do Discord com Vencord, o áudio no compartilhamento de tela do Linux e a organização dos workspaces.

## Onde as coisas estão

| O quê | Onde |
| :--- | :--- |
| Servidor (contas, serviços, workspaces) | `ferdium-server` no rpi3, `hosts/rpi3/services.nix`. URL `https://ferdium.rpi3.leazirondi.com.br`, painel em `/user/login` |
| Cliente no Mac | cask `ferdium` em `modules/darwin/homebrew.nix` |
| Cliente no Nitro 5 | pacote `ferdium` em `hosts/nitro5/default.nix` (só existe para Linux no nixpkgs) |
| Receitas customizadas | `configs/ferdium/recipes/<id>/` |
| Link das receitas | `modules/shared/ferdium.nix`, só nos workstations. Linka `configs/ferdium/recipes` como a pasta `recipes/dev` do Ferdium: `~/Library/Application Support/Ferdium/recipes/dev` no Mac, `~/.config/Ferdium/recipes/dev` no Linux |

O servidor sincroniza conta, lista de serviços com as configurações deles e workspaces. Cookies, sessões e os arquivos das receitas customizadas ficam em cada máquina. Por isso as receitas vivem neste repositório.

## Decisões tomadas

- **Mod:** Vencord, sozinho. Equicord e shelter foram descartados. Nenhum desses mods traz segurança; todos rodam código de terceiros na sessão do Discord, e o Equicord tem curadoria mais solta.
- **Build do Vencord:** `Vencord.user.js` (o build de userscript), baixado de `github.com/Vendicated/Vencord/releases/download/devbuild/`. O `browser.js` não serve: ele espera a extensão mandar a URL do CSS (`vencord:meta`), enquanto o userscript traz o CSS embutido.
- **Atualização:** a receita baixa do GitHub no máximo uma vez por dia e guarda o cache em `<userData do Ferdium>/vencord-cache/`, fora do repositório. A versão nova entra na próxima recarga; se o download falhar, continua valendo a cópia em cache. Na primeira execução, sem cache, a receita baixa e recarrega a página.
- **Receita própria:** id `discord-vencord`, nome "Discord (Vencord)". A receita oficial (`discord`) continua disponível. Badge, links e compatibilidade de notificações foram copiados da oficial (ferdium-recipes, MIT).
- **Áudio no compartilhamento de tela do Linux:** fica para quando o Nitro 5 estiver com Nix (ver abaixo).

## Como a receita funciona

- `webview.js` roda no preload do Ferdium, mas só depois de uma troca de mensagens com o host: o preload manda `hello` com `setTimeout(100)` e o host responde `initialize-recipe` (`src/webview/recipe.ts` no ferdium-app). Nesse ponto o Discord já iniciou o webpack, e o Vencord precisa chegar antes, porque intercepta `Function.prototype.m` (`src/webpack/patchWebpack.ts` no Vencord). Confirmado no primeiro teste: a injeção direta pelo `webview.js` deu `too-late`.
- Por isso o `webview.js` só chama `setup()` em `vencord.js`. Essa função pega a sessão do serviço com `@electron/remote` e registra `preload.js` nela com `session.registerPreloadScript`. O Ferdium habilita o remote nas webviews dos serviços (`enableWebContents` em `src/index.ts`), e o módulo é carregado de dentro do `app.asar`. Na primeira vez, `setup()` recarrega a página.
- `preload.js` roda no início de cada documento, antes dos scripts da página, e injeta o Vencord com `webFrame.executeJavaScript`, como o Vencord desktop faz. Isso também fura o CSP do Discord.
- Testado no Mac em 2026-10-15: o console mostra `[discord-vencord] loaded` e o `WebpackPatcher` do Vencord encontra o webpack do Discord.
- O preload de sessão fica só na memória, então cada abertura do Ferdium custa um reload do Discord.
- O userscript espera `unsafeWindow` e `GM_xmlhttpRequest`. O primeiro é a própria `window`. O segundo é uma ponte por `postMessage` até o preload, que faz a requisição com o `https` do Node. O build de userscript troca todo `fetch` do Vencord por essa função, e o CSP do Discord (`connect-src`) bloquearia, por exemplo, os badges e temas do Vencord. A ponte só aceita `https:`.
- Mensagens no console do serviço com o prefixo `[discord-vencord]`: `preload registered…; reloading`, depois `loaded`. Se aparecer `too-late` mesmo com o preload, o problema está na ordem de execução do preload de sessão.

**Alternativa, se o preload de sessão não funcionar:** ao detectar `too-late`, navegar para uma página do mesmo domínio sem os scripts do Discord (por exemplo `/robots.txt`), injetar o Vencord, buscar o HTML de `/app` com `fetch`, ajustar a URL com `history.replaceState` e trocar o documento com `document.open()`, `document.write(html)` e `document.close()`. O porém: `document.open()` apaga os listeners do documento e da janela, inclusive os do preload do Ferdium.

## Servidor: loja de receitas

`/v1/recipes` respondia 500 (`/app/build/recipes/all.json: ENOENT`). O entrypoint da imagem clona e empacota as receitas em `/app/recipes`, mas o servidor (`build/server.js`) lê de `/app/build/recipes`. A correção em `hosts/rpi3/services.nix` monta o mesmo diretório nos dois caminhos.

## Pendente: áudio no compartilhamento de tela do Linux

O Legcord usa o venmic, um módulo nativo no processo principal do Electron que cria um microfone virtual no PipeWire com o áudio dos apps escolhidos (`src/discord/venmic.ts` no Legcord). Uma receita não alcança o processo principal do Ferdium, então o venmic não entra. O plano:

1. **PipeWire (NixOS, `modules/nixos/common.nix` ou `hosts/nitro5`):** um sink virtual para a transmissão, cujo monitor aparece no Chromium como entrada de áudio, e um loopback dele para a saída padrão, para você continuar ouvindo. Os apps que vão para a transmissão são escolhidos no `pavucontrol`, que já está instalado no Nitro 5.
2. **Receita:** o Ferdium substitui `navigator.mediaDevices.getDisplayMedia` por uma versão que pede só vídeo (`audio: false`, em `src/webview/screenshare.ts` no ferdium-app). A receita envolve essa função: chama a do Ferdium para o vídeo, depois `getUserMedia` com o `deviceId` da fonte virtual e `echoCancellation`, `noiseSuppression` e `autoGainControl` desligados, e junta as faixas no mesmo stream. O shim do Ferdium é instalado depois da receita, então o wrapper deve envolver no momento da chamada ou interceptar a atribuição.
3. Testar no Nitro 5 com i3 (X11).

## E-mail

Decidido: o e-mail fica dentro do Ferdium, num workspace "E-mail" com um serviço por conta: receitas `gmail` e `thundermail`, mais o SnappyMail (`https://webmail.leazirondi.com.br`, de `services/mail`) para o domínio próprio. Para o SnappyMail, use a receita `rainloop` com URL customizada; o SnappyMail é um fork do RainLoop, então o badge provavelmente funciona. Se não funcionar, ajuste numa receita própria em `configs/ferdium/recipes/`.

Futuro, quando houver Nextcloud: o Nextcloud Mail pode virar o único serviço de e-mail no Ferdium, com várias contas e XOAUTH2 para Google e Microsoft (o administrador registra um app em cada provedor), além de Calendar e Contacts. O SnappyMail não serve para isso: os plugins OAuth dele (`login-gmail`, `login-o365`) valem só para a conta principal e são experimentais, e contas adicionais só entram com senha. O Outlook.com pessoal recusa senha de app desde setembro de 2024. Em qualquer opção, o Proton só sai por IMAP pela Proton Mail Bridge, que exige plano pago; sem ela, fica na receita `proton-mail`.

O Thunderbird nativo saiu do Mac (cask) e não foi instalado no Nitro 5. O `cleanup = "uninstall"` do Homebrew remove o app, mas mantém o perfil em `~/Library/Thunderbird`.

## Workspaces planejados

- **Comunicação:** WhatsApp, Telegram, Android Messages, Discord (Vencord) e Instagram DM (Custom Website em `https://www.instagram.com/direct/inbox/`).
- **Redes sociais:** Instagram (feed) e Facebook, com notificações desligadas.
- **E-mail:** Gmail, Thundermail e SnappyMail (um serviço por conta), mais Google Calendar e Google Contacts.
- **Ferramentas:** Bitwarden (apontando para `https://vault.leazirondi.com.br`), IT-Tools, Hacker News.
- **Admin**, todos como Custom Website e com notificações desligadas: Vaultwarden `https://vault.leazirondi.com.br/admin`, Stalwart `https://mail-admin.leazirondi.com.br`, SnappyMail `https://webmail.leazirondi.com.br/?admin`.

## Limitações conhecidas

- Sem extensões do Chrome no Ferdium, então sem adblock nem extensão do Bitwarden. Para senhas, use o `rbw-menu` (`Cmd+Ctrl+P`). Anúncios do Instagram e do Facebook vêm do próprio domínio; só um `user.css` por receita os esconderia. O Ferdium carrega `user.css` e `user.js` da pasta de qualquer receita.
- Não há sincronização de cookies. O Chromium criptografa os cookies com uma chave do sistema (Keychain ou libsecret), então copiar entre Mac e Linux não funciona.
- Lembrete: desligar `IS_REGISTRATION_ENABLED` no `ferdium-server` depois de criar as contas.
