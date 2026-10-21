# Infrastructure Inventory

## Domains
*   **leazirondi.com.br**
    *   **Purpose:** Main personal domain
    *   **Registrar:** registro.br
    *   **DNS Management:** Cloudflare
*   **cacco.com.br**
    *   **Purpose:** Academic Center domain
    *   **Registrar:** registro.br (Technical contact; pending transfer to CACCo CNPJ)
    *   **DNS Management:** Cloudflare
*   **seccomp.com.br**
    *   **Purpose:** Academic presentations week domain
    *   **Registrar:** registro.br (Technical contact; pending transfer to CACCo CNPJ)
    *   **DNS Management:** Cloudflare

## Compute Resources (Servers & Devices)

### Personal & Family
*   **Hetzner VPS** (Finland)
    *   **Specs:** 2 vCPU (x86) AMD EPYC-Rome 2.44GHz, 4GB RAM, 2GB swap file (`/var/lib/swapfile`, since 2026-10-15), 80GB Disk
    *   **Role:** Reliable cloud compute, good for public-facing or isolated services.
    *   **Stacks:** traefik, socket-proxy, n8n, mail (Stalwart + SnappyMail), vaultwarden, whoami, nextcloud.
*   **Oracle Cloud Free Tier** (São Paulo - *Planned*)
    *   **Specs:** 2 vCPU, 16GB RAM (Typically ARM based on RAM specs, but confirm upon provisioning)
    *   **Role:** Low latency for South America, high availability, good for core personal services.
*   **Raspberry Pi 3** (Home)
    *   **Role:** Pi-hole (DNS, DHCP planned), Cloudflare Tunnel, Tailscale subnet router for `10.0.0.0/24`.
*   **Mac Mini M1** (Home)
    *   **Role:** Local LLM model inference, heavy local processing.
*   **Acer Nitro 5 Notebook** (Personal)
    *   **Role:** Main workstation, Tailscale client.

### College / Academic (CACCo)
*   **CACCo Server 1**
    *   **Specs:** Intel (Older generation), 8GB RAM DDR3
    *   **Role:** On-premise hosting for college projects.
*   **CACCo Server 2**
    *   **Specs:** Intel (Older generation), 8GB RAM DDR3
    *   **Role:** On-premise hosting for college projects, redundancy.

## Storage & Backup
*   **Google Drive**
    *   **Capacity:** 5TB
    *   **Role:** Primary backup destination (using `rsync`/`rclone`).

## Monitoring & Alerting
*   **Netdata Agents**
    *   **Role:** Installed on every compute node. Monitors CPU, RAM, Disk IO, and SSH logins locally. Dispatches alerts to Telegram.
*   **Uptime Kuma**
    *   **Role:** Hosted on Oracle Cloud. Pings all Tailscale nodes. Alerts Telegram if a node shuts down or disconnects.
