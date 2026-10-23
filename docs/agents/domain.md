# Domain Docs

How the engineering skills consume this repo's domain documentation.

## Before exploring, read these

- **`GLOSSARY-MAP.md`** at the repo root. It points at one glossary per context: infrastructure (`docs/GLOSSARY.md`) and desktop (`configs/design/GLOSSARY.md`). Read each one relevant to the topic.
- **ADRs** in the area you are about to work in: `docs/adr/` (infrastructure, created with the first decision) and `configs/design/decisions/` (desktop).

If a file does not exist yet, proceed silently. `/domain-modeling` creates glossaries and ADRs lazily, when a term or decision is actually resolved.

## Use the glossary's vocabulary

When your output names a domain concept (a `TODO.md` item, a commit message, a refactor proposal, a hypothesis), use the term as the glossary defines it, and none of the words it lists under _Avoid_.

A concept you need that the glossary lacks is a signal: either you are inventing language the project does not use (reconsider), or there is a real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, say so explicitly rather than silently overriding it:

> _Contradicts ADR-0003 (no motion in v1), but worth reopening because…_
