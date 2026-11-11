# TODO do design (v2)

Plano da v2 do design system do desktop, em fases, com a skill que faz cada parte (`SKILLS.md`). O detalhe de cada pedido continua no item correspondente do `TODO.md`; aqui fica a ordem, o método e o estado. Criado em 2026-10-28.

**Método:** as skills de design trabalham sobre o protótipo (`prototype/index.html`), a decisão vira token no `THEME.md` e cada plataforma traduz o token com o que tem: no eww, transições do GTK e a `revealer`; na SketchyBar, o `--animate`. O AeroSpace não anima, e cada lacuna vira uma linha no `CAPABILITIES.md`. Spec primeiro, depois as configs (`README.md`); mudança grande no Linux passa pelo `nitro5-vm` antes do bare metal.

**Premissas de plataforma (2026-10-28):**
- **Mac = MacBook (Air), uma tela, muitas vezes na bateria.** A barra é desenhada para uma tela estreita, e motion e polling custam bateria.
- **Linux = PC fixo, várias telas, sempre na tomada.** Pode animar à vontade, e o trabalho é multi-monitor.
- **A bateria do nitro5 é temporária:** ele é o substituto do PC. Corrigir só o necessário agora; o popup de bateria se desenha para o MacBook.
- O ADR 0004 precisa decidir se motion é *look* (o Linux pode mais) ou *behavior* (igual nos dois).

**Handoff:** `scratch/handoffs/HANDOFF-design-v2.md` traz o estado, os achados, as decisões pendentes e como tirar screenshots do protótipo.

**A confirmar:** o eww usa CSS do GTK3, que até onde se sabe não tem `transform`. Nesse caso, "popover crescendo do botão" vira fade/slide da `revealer`.

## Fase 1: diagnóstico (sem mexer nas configs)

- [ ] **Pior caso no protótipo** (`break-ui`): título de aba enorme, muitos ícones no tray, nome de Bluetooth longo, bateria em 0% e carregando, IPv6, muitos workspaces. Avança o título que invade o relógio na SketchyBar (`TODO.md`, Mac #9) e a rolagem de texto da v2.
  - **Feito em 2026-10-28, falta decidir as correções.** O protótipo ganhou os conjuntos de dados Demo / Worst case / Empty / Huge (seletor na barra de baixo, `?data=`); os dados entram só pelo objeto `DATA` do script.
  - **Quebrou (Broken):**
    - no Mac, os menus do app passam por baixo do relógio (reproduz o Mac #9);
    - a notificação com URL longa sai pela borda;
    - a dock com 22 apps sobe por baixo da barra.
  - **Feio (Ugly):**
    - o título no Linux é cortado no meio da letra, sem reticências;
    - as estatísticas em 100% empurram a barra;
    - "Hoje" sem eventos fica como cabeçalho órfão;
    - Wi-Fi e Bluetooth vazios não mostram nenhuma mensagem;
    - a dock vazia vira uma pílula sem nada.
  - **Divergências spec × eww:**
    - título: 360 px no protótipo, 60 caracteres no eww;
    - eventos: quebram linha no protótipo, cortados em 30 caracteres no eww;
    - o eww mostra o IP na barra, o protótipo só no tooltip;
    - o eww não tem menu de Wi-Fi.
- [ ] **Crítica dos tokens** (`impeccable critique`, só a crítica; `init`/`document` não rodam neste repo): contraste e hierarquia sobre o wallpaper. Avança a dock mais transparente (`TODO.md`, nitro5 #3) e as lacunas da spec.
- [ ] **Custo do que roda e anima** (`animation-performance`): orçamento de bateria do **Mac**, com o polling da SketchyBar (`update_freq` de 3 a 5 s em menus, mídia, privacidade e stats) e o `hover.sh` animando `padding_left`. No Linux (PC na tomada), o `defpoll` do eww só entra se atrapalhar a resposta. A bateria do nitro5 (`TODO.md`, nitro5 #5) é temporária e fica fora daqui.

Saída: cada achado vira token novo, linha no `CAPABILITIES.md` ou item no `TODO.md`.

## Fase 2: ADR 0004, motion

Substitui `decisions/0003-no-motion-in-v1.md`.

- [ ] **O que anima** (`emil-design-eng`, `animate`):
  - sim: barra e dock sumindo e voltando, menus e popups, hover, troca de cor do workspace pill, rolagem de texto;
  - não: troca de workspace e de janelas, porque o AeroSpace não anima e a paridade manda.
- [ ] **Tokens no `THEME.md`**: `motion-fast` (hover, ~150 ms), `motion-base` (entrar e sair, ~200–250 ms), `ease-out` para entrar, saída mais rápida que a entrada, velocidade e pausa da rolagem, `reduced-motion`.
- [ ] **Nomes dos efeitos no `GLOSSARY.md`** (`animation-vocabulary`).
- [ ] **Ensaio no protótipo**, depois `/review-animations` antes de portar.

## Fase 3: aplicar, uma superfície por vez

- [ ] **Barra e dock com transição** no `Caps+B`, no `cover.sh` e no reload (`TODO.md`, "Animações").
- [ ] **Menus e popups da barra** (Wi-Fi, Bluetooth, bateria), com origem e interrupção pela `apple-design`.
- [ ] **Hover e workspace pill** com transição de cor, nas duas plataformas.
- [ ] **Rolagem do texto cortado**, só no hover (`TODO.md`, "Rolagem de texto longo").
- [ ] **Carrossel de IP** LAN ↔ tailnet ↔ público, com alvos separados para trocar o IP e abrir as configurações (`TODO.md`, "IP do tailnet"; `break-ui` para IPv6).

## Fase 4: superfícies a redesenhar

- [ ] **Lockscreen**: `grilling` sobre o que incomoda, `/prototype` com 3–4 variantes da `lock` no protótipo, escolha na tela, porte para o `i3lock-color` (`TODO.md`, nitro5 #10).
- [ ] **Notificações com botões**: `research` compara `xfce4-notifyd` e `deadd`, depois a variante `notification` no protótipo, com os tokens da v2 (`TODO.md`, "Notificações com botões").
- [ ] **Popup da bateria**: `impeccable shape` + `break-ui` (sem bateria no VM, estado desconhecido) (`TODO.md`, nitro5 #5).

## Fora do desktop

- **Site do CACCo**: `impeccable audit` + `mobile-native`; vale ligar o detector do `impeccable` nesse projeto.
- **`art-styles`**: `/pick-ui-library`, `find-animation-opportunities` → `improve-animations`.
- **`site-base` e `curriculum`**: `impeccable shape` antes do código.
- **Sessão de desktop ao vivo** (`ORDEM.md`): `wizard` para as permissões do Mac (SketchyBar, icalBuddy) e a conferência do JankyBorders.
- **Bugs**: `diagnosing-bugs` para o `just switch` que reorganiza o AeroSpace (`TODO.md`, Mac #1) e o screenshot do nitro5.
- **Scripts do desktop** (`configs/eww/scripts`, `configs/sketchybar/plugins`): `code-review` do Matt contra o `CODING_STANDARDS.md`, depois `simplify`.
