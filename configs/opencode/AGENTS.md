# Limits of this environment

OpenCode here runs small local models (about 9B parameters, 64k context) on 16 GB of
unified memory. Context is the scarce resource: every token read is held in memory and
slows each following step.

- Do not read whole files over ~300 lines. Search with grep and read only the lines needed.
- Before editing existing code, write `PLANO.md` as a checklist of small steps, one file or
  one function per step.
- Do one step at a time: mark it `[x]` in `PLANO.md` and stop.
- To explore the codebase, use the `explore` subagent and ask it for a short summary.
