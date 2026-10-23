# Service Allocation Plan

This document maps out which services will run on which infrastructure to balance load, maintain security, and optimize for latency.

## 1. Personal & Family Services
These services require high availability and low latency since they are used daily by you and your family.

*   **Password Manager (Vaultwarden/Bitwarden)**
    *   **Target:** Hetzner VPS (Helsinki)
    *   **Reason:** VPS estável com 4GB RAM e Podman, roteado com segurança via Cloudflare Tunnel.
*   **AliasVault (password and email alias manager, on trial)**
    *   **Target:** Hetzner VPS (Helsinki): `aliasvault.leazirondi.com.br` through the tunnel without `/admin`, and `aliasvault.hetzner.leazirondi.com.br` over the tailnet with the admin panel.
    *   **Reason:** Candidate to replace Vaultwarden once vault sharing between accounts of the same server ships for self-hosting (0.31.0 only laid the groundwork). Upstream multi-container layout pinned to 0.31.1, about 430 MB. Aliases at `alias.leazirondi.com.br`: the MX points to this host and Stalwart, which owns port 25, relays the domain to `aliasvault-smtp` over `mail-internal`.
*   **Nextcloud (mail, calendar and contacts)**
    *   **Target:** Hetzner VPS (Helsinki), tailnet only: `nextcloud.hetzner.leazirondi.com.br`
    *   **Reason:** One web UI for every mail account (Nextcloud Mail over IMAP, with XOAUTH2 for Google and Microsoft), plus CalDAV/CardDAV for the phone over Tailscale. It replaced the SnappyMail webmail, removed on 2026-10-22 because its image shipped an unpatched PHP (CVE-2026-109618/109619); Stalwart stays as the mail server for the own domain. Postgres 17 and Redis on a stack-only network; about 120 MB idle. Revisit when the Oracle host exists (16 GB+ RAM, closer to Brazil).
*   **Trilium Server (Knowledge Base)**
    *   **Target:** Oracle Cloud (São Paulo)
    *   **Reason:** Needs to be responsive and highly available for note-taking.
*   **Calibre Web (Online Library) & n8n (Automations)**
    *   **Target:** Oracle Cloud or Hetzner VPS
    *   **Reason:** Can be heavy on RAM/CPU. Oracle's 16GB RAM tier handles this easily.
*   **LLM Models (Local inference)**
    *   **Target:** Mac Mini M1 (Home)
    *   **Reason:** Best local hardware for AI inference without incurring API costs.
*   **Smart Home (Tuya devices: lamp and smart plug)**
    *   **Target:** Raspberry Pi 3 (Home)
    *   **Reason:** Planned as small scripts talking to the devices over the LAN. Home Assistant was removed from the Pi in 2026-10: it used more memory than everything else on it combined.
*   **Ferdium Server (sync for the Ferdium messaging client)**
    *   **Target:** Raspberry Pi 3 (Home)
    *   **Reason:** Small (about 135 MB idle) and only needed by the user's own devices, so it is published on the Pi's tailnet address only.
*   **Gitea (mirror of GitHub)**
    *   **Target:** Raspberry Pi 3 (Home), tailnet only: `gitea.rpi3.leazirondi.com.br`
    *   **Reason:** A second, organised copy of every personal and organisation repository; GitHub stays where pushes go. Native NixOS module with SQLite (lighter than a container on 1 GB of RAM), in the Pi's backup; mirrors created by `scripts/gitea-mirror.sh`.
*   **Diun (image update notices)**
    *   **Target:** Hetzner VPS (Helsinki), no exposure
    *   **Reason:** Image tags are pinned, so something has to say when a release comes out. Watches the repository of each image running on the host (through `socket-proxy`) plus the images declared for `rpi3`, and posts to Telegram.
*   **Pi-hole (Network Ad Blocking)**
    *   **Target:** Raspberry Pi 3 (Home)
    *   **Reason:** Provides network-wide ad blocking for the local network. Runs as an OCI container via Podman.

## 2. College Projects & CACCo Services
These should be separated from your personal infrastructure where possible.

*   **CACCo & Seccomp Websites (`cacco.com.br`, `seccomp.com.br`)**
    *   **Target:** CACCo Intel Servers (via Cloudflare Tunnels) or Hetzner VPS
    *   **Reason:** If CACCo servers are reliable and always on, host them there. Otherwise, Hetzner is a solid fallback for public web traffic.
*   **College Password Manager**
    *   **Target:** CACCo Intel Servers
    *   **Reason:** Data sovereignty for the academic center, keeping college credentials on college hardware.
*   **CTF SSH Server**
    *   **Target:** Hetzner VPS
    *   **Reason:** CTF infrastructure often gets targeted or abused. Isolating this on the Hetzner server (which is separate from your personal/Oracle nodes) is best for security.

## 3. Network & Backup Infrastructure
*   **Tailscale VPN**
    *   **Nodes:** All servers and devices (Hetzner, Oracle, RPi 3, Mac Mini, Acer Nitro, CACCo Servers).
    *   **Subnet Router:** Raspberry Pi 3 (allows access to your local home network securely).
*   **Cloudflare Tunnels (`cloudflared`)**
    *   **Target:** Raspberry Pi 3
    *   **Reason:** Exposes local web services (from the Mac Mini or Acer Nitro) securely to the public internet via Cloudflare without needing port forwarding on the ISP router.
*   **Backup System**
    *   **Method:** Nightly cron jobs using `rsync` or `rclone` pointing to Google Drive (5TB).
    *   **Targets:** Database dumps (Password managers, Trilium), Docker volumes, and configurations.

## 4. Monitoring & Alerting
*   **Uptime Kuma**
    *   **Target:** Oracle Cloud
    *   **Reason:** Central dashboard for uptime tracking. Pings Tailscale IPs of all servers. Sends Telegram alerts on node shutdowns.
*   **Netdata (Agents)**
    *   **Target:** All Servers (Oracle, Hetzner, RPi, CACCo)
    *   **Reason:** Ultra-lightweight resource monitoring. Sends Telegram alerts for high CPU/RAM/Disk, and logs every SSH login directly.
