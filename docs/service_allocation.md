# Service Allocation Plan

This document maps out which services will run on which infrastructure to balance load, maintain security, and optimize for latency.

## 1. Personal & Family Services
These services require high availability and low latency since they are used daily by you and your family.

*   **Password Manager (Vaultwarden/Bitwarden)**
    *   **Target:** Oracle Cloud (São Paulo)
    *   **Reason:** Low latency for fast syncing in Brazil, free tier has plenty of resources.
*   **Trilium Server (Knowledge Base)**
    *   **Target:** Oracle Cloud (São Paulo)
    *   **Reason:** Needs to be responsive and highly available for note-taking.
*   **Calibre Web (Online Library) & n8n (Automations)**
    *   **Target:** Oracle Cloud or Hetzner VPS
    *   **Reason:** Can be heavy on RAM/CPU. Oracle's 16GB RAM tier handles this easily.
*   **LLM Models (Local inference)**
    *   **Target:** Mac Mini M1 (Home)
    *   **Reason:** Best local hardware for AI inference without incurring API costs.
*   **Home Assistant (Smart Home)**
    *   **Target:** Raspberry Pi 3 (Home)
    *   **Reason:** Local control of smart devices. Very lightweight as an OCI container via Podman.
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
