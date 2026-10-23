# Stacks: conventions and the workflow for a new one

Read this before creating or changing a stack. Terms (stack, service, exposure, deploy, stack upload) are defined in `docs/GLOSSARY.md`.

## Where stacks live

- Public stacks: `services/<stack>/compose.yml`, in the `services` submodule of this repo (its own repository, branch `dev`). Private stacks: `../../private/private-services/<stack>/`, same conventions.
- Edit stacks only in the `services/` submodule. The standalone checkout at `~/repos/github/me/public/services` is a read-only mirror: if work turns up there, stop and move it into the submodule first. Never symlink one checkout into the other.
- A stack that runs in production is committed in the `services` repository in the same session that deploys it: propose that commit to the user, and before finishing run `git -C services status` and report anything left uncommitted.
- Hosts and the Nix-declared containers of `rpi3` (`hosts/rpi3/services.nix`) are the exception: they are not compose stacks.

## Every service

- Start from `services/.template/compose.yml`.
- `security_opt: [no-new-privileges=true]`.
- Timezone: mount `/etc/timezone:ro` and `/etc/localtime:ro` and set `TZ=America/Sao_Paulo`.
- Prefer a container (compose, or Podman in Nix) to a bare-metal install. NixOS hosts run Podman Compose (`virtualisation.podman.enable = true`), not Docker.
- Keep personal stacks (Home Assistant, Trilium, Vaultwarden) apart from academic and public ones (CACCo sites, CTF servers): separate networks, and separate hosts or VMs where the risk calls for it.

## Exposure and networks

Each routed service has exactly one exposure and joins exactly one network:

| Exposure | Network | Traefik entrypoint | Name |
| :--- | :--- | :--- | :--- |
| tunnel | `tunnel-network` | `web` (Cloudflare Tunnel) | public name of one level |
| tailnet | `tunnel-network` | `websecure` | `service.<host>.<domain>` |
| public | `public-network` | `public` (DNS-only record) | public name |

- There is one Traefik stack per host (`services/traefik`). `cloudflared-network` belongs to it alone; no service joins it. Services that need the Docker API join `socket-proxy`.
- The name `edge-network` is retired on purpose, so a leftover reference fails instead of landing on an exposed network.
- The tailnet and public entrypoints are bound to different host addresses (`TAILNET_IP`, `PUBLIC_IP`, exported by `scripts/deploy.sh`). Bind each to its address, never `0.0.0.0`, and do not rely on source-address filters: rootless Podman hides the client address from Traefik.
- A service names its domain in its own labels; copy the block for its exposure from `services/.template/traefik-label-template.yml`. The Cloudflare DNS token must be able to edit every zone used for a certificate.

## Secrets

- File-based Docker secrets: `./secrets/<NAME>` mapped to `/run/secrets/`. Plain `.env` files are never committed: encrypt them or keep them out of git.
- Generate a secret straight into `services/<stack>/secrets/` without echoing it (`just secrets <stack>` / `scripts/init-secrets.sh` creates the stubs), then encrypt it with the stack's rules:

  ```bash
  sops -e --config services/.sops.yaml --input-type binary <file> > <file>.sops.yaml
  ```

  `.sops.yaml` assigns keys by directory (`services/**/secrets.sops.yaml`); servers decrypt with keys derived from their SSH host keys. Only `*.sops.yaml` is committed or uploaded.

## Workflow for a new stack

1. Pick the exposure, then copy the template compose file and the matching label block (above).
2. Add the hardening and timezone lines.
3. Create and encrypt its secrets (above).
4. Test it locally: `just test-compose <stack>`, or with the proxy, `just test-compose socket-proxy traefik <stack>`; `--amd64` forces x86_64 emulation on Apple Silicon. The script creates the networks and dummy secrets.
5. Update the inventories in `docs/` (`service_allocation.md`, `infrastructure_inventory.md`, `network_ip_ranges.md`, `network_topology.md` as the change requires).
6. Deploy only through the script, after the user confirms: `just deploy <host> --svc <stack>`.
7. Propose the commit in the `services` repo (above), and raise the GitHub topics if the stack brings a new core technology (`AGENTS.md`, "Scope and topics").
