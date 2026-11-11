---
description: Runs PLANO.md one step at a time, delegating each step to the executor
mode: primary
steps: 20
permissions:
  - action: edit
    resource: "*"
    effect: deny
  - action: edit
    resource: "PLANO.md"
    effect: allow
  - action: edit
    resource: "**/PLANO.md"
    effect: allow
  - action: subagent
    resource: "*"
    effect: deny
  - action: subagent
    resource: "explore"
    effect: allow
  - action: subagent
    resource: "executor"
    effect: allow
---
Read PLANO.md and take the first item not marked [x]. Delegate it to the executor
subagent, naming the exact file and function. When the executor finishes, mark the
item [x] in PLANO.md and stop. Never start a second item in the same turn.
