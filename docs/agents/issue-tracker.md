# Issue tracker: ORDEM.md, TODO.md and reminders.md

Work for this repo is tracked in three Markdown files at the root, written in Portuguese. There are no GitHub Issues: the repo is public, and the backlog mentions private stacks and accounts.

## What each file holds

- `ORDEM.md`: what is being worked on now and in which order: a dated plan whose steps are tagged [A] (the agent alone) or [U] (needs the user), an "Estacionado" list where each parked item names the trigger that brings it back, and short reference notes per host. The [U] steps live in the wizard the plan names, under `scratch/wizards/`.
- `TODO.md`: the detail of every item, grouped by area. Each item is one `- [ ]` bullet with a bold title, the date it was asked for or seen, the facts found so far, and the next step.
- `reminders.md`: what depends on a place or moment (at the Mac, at home), not on order.

## Conventions

- A new request in an upkeep pass is recorded in `TODO.md`, not implemented on the spot.
- An item the user confirms as fixed, or reports as no longer a problem after testing, leaves `TODO.md` (or is ticked in `ORDEM.md`); say so in the reply.
- Facts go into the item as they are found (versions, what was ruled out), so the next session starts from them.
- A spec for a larger piece of work lives in `scratch/handoffs/spec-<slug>.md` (gitignored), with a `Status:` line near the top (role strings in `triage-labels.md`); the `TODO.md` item points at it.
- Whatever concerns a stack of `private-services` is tracked in that repo, never here.

## When a skill says "publish to the issue tracker"

Add a `TODO.md` item in the right section; for a spec, write `scratch/handoffs/spec-<slug>.md` and point the item at it. If the work changes the order, update `ORDEM.md` too.

## When a skill says "fetch the relevant ticket"

Read the `TODO.md` item (and the spec it points at). The user will normally name the item.

## Wayfinding operations

Used by `/wayfinder`. The map is `scratch/handoffs/<effort>/map.md`; child tickets are `scratch/handoffs/<effort>/issues/NN-<slug>.md`, numbered from `01`, each with `Type:`, `Status:` and `Blocked by:` lines. Resolve a ticket by appending `## Answer`, setting `Status: resolved` and adding a pointer to the map. When the effort ends, its outcome moves to `TODO.md`/`ORDEM.md` and the decisions to `agent_logs.md`.
