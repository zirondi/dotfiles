# Infrastructure

The shared language for the machines this flake defines, the container stacks they run and how work reaches them. The desktop has its own glossary in `configs/design/GLOSSARY.md`.

## Hosts

**Host**:
A machine defined in this flake, whatever its role.
_Avoid_: machine, box, node

**Workstation**:
A host with a desktop that the user works at: `macmini` and `nitro5`.
_Avoid_: desktop, client, laptop (as a role)

**Server**:
A host without a desktop that runs stacks: `hetzner` and `rpi3`.
_Avoid_: node, VPS (as a role)

**Tailnet**:
The private Tailscale network that joins every host.
_Avoid_: VPN, mesh

**Node**:
A member of the tailnet, as Tailscale names it. Used only in that sense.
_Avoid_: host (when the tailnet membership is what matters)

## Stacks

**Stack**:
One compose project in its own directory of `services` or `private-services`, started and stopped as a unit.
_Avoid_: service (for the directory), app

**Service**:
One container definition inside a stack.
_Avoid_: container (for the definition), stack

**Exposure**:
How a routed service is reached: tunnel, tailnet or public. Each routed service has exactly one.
_Avoid_: edge, access, visibility

**Tunnel exposure**:
Reached from the internet through the Cloudflare Tunnel, with no port open on the host.

**Tailnet exposure**:
Reached only from the tailnet, at a per-host name.

**Public exposure**:
Reached directly on the host's public address.

## Moving work

**Switch**:
Applying this repo's configuration to the host you are on.
_Avoid_: rebuild, apply (for the whole act)

**Deploy**:
Applying the configuration to a remote host: a NixOS rebuild, a stack upload, or both.
_Avoid_: push, ship, switch (for a remote host)

**Stack upload**:
The part of a deploy that copies stacks to a server and restarts the ones named.
_Avoid_: compose sync, service sync

**Sync**:
Carrying the uncommitted working tree between the two workstations. Commits never travel this way.
_Avoid_: sync (for a deploy or for moving commits)
