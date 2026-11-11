# Skills disponíveis

Mapa das skills que o Claude Code (e, em parte, o Antigravity) tem neste ambiente: o que cada uma faz, onde elas se atropelam e quando vale lembrar de usá-las. A coluna **Sugerir quando** é o gatilho que o Claude usa para perguntar "usar a skill X aqui?" quando você não chamou nenhuma (regra em `~/repos/CLAUDE.md`, seção "Skill suggestions").

Levantamento de 2026-10-28. Ao instalar ou remover uma skill, atualize este arquivo.

## De onde vêm

| Origem | Onde fica | Quem vê | Como atualiza |
| :--- | :--- | :--- | :--- |
| Plugins (`/plugin`) | `~/.claude/plugins/cache/` | Só o Claude | `/plugin`, depois `/reload-plugins` |
| skills.sh (`npx skills`) | `~/.agents/skills/`, com symlink em `~/.claude/skills/` | Claude **e** Antigravity (`configs/antigravity/skills.json`) | `npx skills update -g`; lock em `configs/agents/.skill-lock.json` |
| Do projeto | `.claude/skills/` do repo | Claude, só nesse repo | Commit no repo |
| Embutidas | Claude Code e conta claude.ai | Só o Claude | Vêm com o produto |

**Manual** na tabela = `disable-model-invocation: true`: só roda quando você chama (`/nome`), não ocupa contexto e nunca dispara sozinha.

## Interferências e quem ganha

Onde duas skills disputam o mesmo pedido, vale a regra abaixo. As marcadas *(recomendação)* são escolha minha, não do autor da skill.

1. **`impeccable`: skill ligada, hooks desligados.** O plugin está ativo, mas `IMPECCABLE_HOOK_DISABLED=1` no `env` de `~/.claude/settings.json` faz o detector automático sair sem rodar. A skill e o `/impeccable` funcionam normalmente. Para ligar o detector num projeto de UI, rode `/impeccable hooks on` dentro dele. A variável de ambiente vence a configuração, então para isso é preciso também tirar a variável do `env`. A `taste-skill` foi removida em 2026-10-28, porque disputava os mesmos pedidos com regras opostas.
2. **Motion: a família da Emil × `impeccable animate`.** A Emil começa por "isso deve animar?" e aceita zero animação como resposta. *(recomendação)* Para decidir e implementar motion, a família da Emil ganha (`animate` → `review-animations` → `animation-performance`). Ela é a mais rigorosa e as skills se referenciam entre si. Use `impeccable animate` só dentro de um trabalho que já está na `impeccable`.
3. **Design system deste repo × `impeccable init/document`.** A `impeccable` cria `PRODUCT.md` e `DESIGN.md` na raiz do projeto e passa a tratá-los como fonte da verdade. No dotfiles a fonte é `configs/design/` (AGENTS.md §3): não rode `init`/`document` aqui. Em outros projetos, tudo bem.
4. **Hooks do `impeccable`.** São três: `SessionStart`, todo `PostToolUse` e `Stop`. Com o detector ligado, eles injetam avisos de design após cada edição de `.tsx`, `.css`, `.html`, etc., e fazem uma passada completa no fim da sessão. Desligados, ainda disparam, mas saem na hora.
5. **`emil-design-eng` tem regras de formato.** Chamada sem pergunta, ela só responde uma frase de apresentação, e toda review de UI sai em tabela Before/After. Não é bug.
6. **Três revisões de código diferentes.** Não são intercambiáveis:
   - `code-review` (embutida): caça bugs no diff;
   - `mattpocock-skills:code-review`: confere padrões (`CODING_STANDARDS.md`) e spec, e é a que o dotfiles adota (CLAUDE.md, "Agent skills");
   - `simplify`: qualidade e reuso, e já aplica as correções;
   - `security-review`: segurança.
   Para um diff grande, rode a do Matt e a embutida.
7. **Dois `prototype`.** Os dois se complementam. `mattpocock-skills:prototype` responde a uma pergunta de design (lógica ou UI) com um protótipo descartável. `/prototype` da Emil (manual) faz várias versões de um componente com um seletor para comparar.
8. **Pesquisa.** `mattpocock-skills:research` grava um `.md` no repo, a partir de fontes primárias. `anthropic-skills:deep-research` gera um relatório narrativo e dispara subagentes. Como você não quer subagentes sem pedir, a do Matt é o padrão.
9. **Antigravity.** `cc-antigravity-plugin:antigravity` e `antigravity-integration` fazem a mesma coisa (a ponte para o AGY). O hook do plugin injeta "delegue todo código ao AGY" em toda sessão, mas a política que vale é a do CLAUDE.md do dotfiles ("Delegating to Antigravity").
10. **Browser.** `claude-in-chrome` e `anthropic-skills:chrome-browser` cobrem a mesma extensão. `built-in-browser` é outro navegador, o painel do app desktop. `computer-use` controla a tela inteira: anuncie antes de cada screenshot (sua regra de consentimento).
11. **Dashboards.** `dataviz` é para o gráfico em si (cores, marcas, eixos). A tela em volta é da `impeccable`. Use as duas juntas, cada uma no seu pedaço.
12. **`karpathy-guidelines`** dispara em quase toda tarefa de código. É curta (2,5 KB) e só reforça cautela, então não conflita com nada. Em tarefa trivial, ignore.

## Design e front-end

| Skill | O que faz | Sugerir quando |
| :--- | :--- | :--- |
| `impeccable:impeccable` | Direção de design para UI e páginas: `shape`, `critique`, `audit`, `polish`, `harden`, `onboard`, `bolder`/`quieter` | Criar ou refazer tela, página, formulário, empty state; "deixa melhor", "tá feio". |
| `emil-design-eng` | Filosofia de polish e componentes da Emil Kowalski: easing, springs, popovers, botões | Detalhe de componente que "não parece certo"; revisar polish de UI |
| `apple-design` | Princípios da Apple para a web: gestos, springs, materiais, tipografia | Sheet, drag/swipe, interação com momentum, translucidez |
| `animate` | Constrói uma animação na ordem certa, começando por "deve animar?" | Pedido de "anima isso", transição, "dar vida" |
| `review-animations` *(manual)* | Revisão rigorosa de motion; aprovação só se merecida | Antes de dar por pronta uma feature com animação |
| `improve-animations` | Auditoria de motion do codebase inteiro, com planos executáveis | "Melhora as animações do app" |
| `find-animation-opportunities` | Onde falta motion e onde não deve haver (só leitura) | "O que dá pra animar aqui?" |
| `animation-performance` | Animação que trava ou perde frames | Jank, `will-change`, CSS × JS por performance |
| `animation-vocabulary` | Glossário reverso: descreve o efeito, recebe o nome | "Como chama aquele efeito que…" |
| `mobile-native` | Web app parecendo nativo no celular (100vh, tap highlight, safe area) | Página que vai ser usada no celular; PWA |
| `break-ui` | Testa UI com dados de pior caso (nomes longos, listas vazias) | Antes de entregar componente que mostra dados de usuário |
| `pick-ui-library` *(manual)* | Escolhe biblioteca curada (toast, charts, DnD, OTP) | Antes de escrever na mão um componente que já existe pronto |
| `prototype` *(manual, Emil)* | Várias versões de uma peça de UI com seletor | Dúvida entre abordagens visuais |
| `ask-sonner` | Guia da lib de toast Sonner | Projeto usando Sonner |
| `animate-expo` | Animação em React Native/Expo | Só em app Expo |
| `dataviz` | Gráficos, paletas, stat tiles, dashboards | Qualquer gráfico, em qualquer lib |
| `artifact-design` / `artifact-diagramming` / `artifact-capabilities` | Páginas publicadas como Artifact no claude.ai | Pedido de página compartilhável; diagrama |

## Programação e engenharia

| Skill | O que faz | Sugerir quando |
| :--- | :--- | :--- |
| `mattpocock-skills:tdd` | Red-green-refactor | Feature ou bug com lógica testável (scripts, apps) |
| `mattpocock-skills:diagnosing-bugs` | Loop de diagnóstico para bug difícil | Bug que já resistiu a uma tentativa; "tá lento" |
| `mattpocock-skills:code-review` | Review de padrões + spec desde um ponto fixo | Antes de você agrupar commits; fim de feature |
| `code-review` | Caça bugs no diff, com níveis de esforço | Diff grande ou arriscado (deploy, secrets) |
| `simplify` | Limpeza de reuso e simplificação, aplicada | Depois que a feature funciona e antes do review |
| `security-review` | Revisão de segurança das mudanças | Mexeu em exposição, auth, secrets, firewall |
| `mattpocock-skills:codebase-design` | Vocabulário de módulos profundos e seams | Desenhar interface de módulo; refactor estrutural |
| `mattpocock-skills:domain-modeling` | Glossário e ADRs (`GLOSSARY-MAP.md`) | Nomear conceito novo; decisão de arquitetura |
| `mattpocock-skills:prototype` | Protótipo descartável para responder a uma dúvida | Incerteza sobre modelo de estado ou fluxo |
| `mattpocock-skills:pr` | Corpo de PR | Abrir PR |
| `mattpocock-skills:wizard` | Script bash interativo para passos que só você faz | Provisionar, credenciais, painel de terceiro, cutover |
| `andrej-karpathy-skills:karpathy-guidelines` | Mudanças cirúrgicas, premissas explícitas | Dispara sozinha; não precisa sugerir |
| `write-swift` | Swift moderno, concorrência do Swift 6 | Só com Swift |
| `claude-api` | API e SDK da Anthropic | Código que chama Claude |
| `cc-antigravity-plugin:antigravity` | Delega leitura ou escrita grande ao AGY (Gemini) | Ler mais de 100 KB ou mais de 20 arquivos; geração em massa; front-end grande |

## Infra e ops

| Skill | O que faz | Sugerir quando |
| :--- | :--- | :--- |
| `nix-best-practices` | Flakes, overlays, módulos | Módulo ou host novo; `flake.nix` |
| `docker-compose-orchestration` | Compose, redes, volumes | Stack novo ou alterado (junto com `docs/agents/compose.md`) |
| `cloudflare:cloudflare` | Roteador para os produtos Cloudflare | Qualquer coisa de tunnel, Zero Trust, Workers; leva à skill específica |
| `cloudflare:cloudflare-one` | Zero Trust e Access | Expor serviço com Access na frente |
| `cloudflare:wrangler`, `workers-best-practices`, `web-perf` e as demais `cloudflare:*` | Workers, perf e produtos específicos | Quando o roteador apontar |

## Pesquisa, planejamento e escrita

| Skill | O que faz | Sugerir quando |
| :--- | :--- | :--- |
| `mattpocock-skills:grilling` | Interrogatório de um plano (via AskUserQuestion, em lotes de até 4) | Plano grande antes de implementar; decisão com muitas pontas |
| `mattpocock-skills:research` | Pesquisa em fonte primária, gravada em `.md` no repo | Comparar ferramentas, levantar fatos de docs antes de decidir |
| `anthropic-skills:deep-research` | Relatório narrativo com subagentes | Só quando você pedir pesquisa ampla |
| `mattpocock-skills:writing-for-agents` | Escrever skills, AGENTS.md, CLAUDE.md | Editar AGENTS.md, CLAUDE.md, GEMINI.md |
| `anthropic-skills:skill-creator` | Criar e avaliar skill nova | Pedido de skill própria |
| `egm:*` *(manual)* | Documentação e review de docs em enxame (`/egm-bootstrap`, `/egm-review`…) | README por diretório; revisar doc longo |

## Documentos e arquivos

| Skill | O que faz | Sugerir quando |
| :--- | :--- | :--- |
| `anthropic-skills:docs` | Doc editável no claude.ai (exporta Word, PDF, Google Docs) | Documento para compartilhar, que não pertence ao repo |
| `anthropic-skills:pdf` / `docx` / `xlsx` / `pptx` | Ler e gerar esses formatos | Arquivo nesse formato na entrada ou na saída |
| `anthropic-skills:google-workspace` | Editar Docs, Sheets, Slides no Drive | Mudar arquivo Google existente |

## Browser e computador

| Skill | O que faz | Sugerir quando |
| :--- | :--- | :--- |
| `claude-in-chrome` / `anthropic-skills:chrome-browser` | Seu Chrome, com seus logins | Painel web (Cloudflare, Hetzner), testar site |
| `anthropic-skills:built-in-browser` | Painel de browser do app desktop | Sessão no app desktop |
| `anthropic-skills:computer-use` | Controle de apps do Mac | Ajuste em app nativo; sempre anunciando o screenshot |

## Claude Code

| Skill | O que faz | Sugerir quando |
| :--- | :--- | :--- |
| `update-config` | Hooks, permissões, env no `settings.json` | "Sempre que X, faça Y" (precisa de hook, não de memória) |
| `fewer-permission-prompts` | Allowlist a partir do histórico | Muitos prompts de permissão repetidos |
| `keybindings-help` | Atalhos do Claude Code | Remapear tecla |
| `loop` / `schedule` | Repetir uma tarefa no intervalo; agente agendado na nuvem | Acompanhar deploy ou CI; tarefa recorrente |
| `run` | Sobe o app e confere a mudança rodando | Validar UI ou CLI de verdade, não só testes |
| `init` | Gera CLAUDE.md | Repo novo sem CLAUDE.md |

## Lacunas

Skills em `~/.agents/skills` **sem** symlink em `~/.claude/skills`, que só o Antigravity enxerga:

- `code-security`: útil para o Claude também. Para dar acesso: `ln -s ../../.agents/skills/code-security ~/.claude/skills/code-security`.
- `tailscale` e `design-doc-mermaid` foram removidas em 2026-10-28.
- `code-review`, `research`, `grill-me`, `improve-codebase-architecture`, `teach`: cópias antigas das skills do Matt. O Claude já tem as versões do plugin; para ele, ignore.
- `brainstorming` declara "You MUST use this before any creative work". No AGY ela pode disparar em quase tudo. Se o Gemini começar a fazer brainstorm sem motivo, remova (`npx skills remove -g brainstorming`).
- `find-skills`: descobre skills novas no skills.sh.
