# Network Topology

The infrastructure will be tied together using **Tailscale** to create a secure, flat mesh network. This allows all servers and devices to communicate securely without exposing internal services directly to the public internet. Public-facing services will be routed through Cloudflare or specific reverse proxies.

```mermaid
flowchart TD
    %% Define Styles
    classDef personal fill:#4285F4,stroke:#fff,stroke-width:2px,color:#fff
    classDef cloud fill:#0F9D58,stroke:#fff,stroke-width:2px,color:#fff
    classDef cacco fill:#F4B400,stroke:#fff,stroke-width:2px,color:#fff
    classDef network fill:#DB4437,stroke:#fff,stroke-width:2px,color:#fff
    classDef storage fill:#8e44ad,stroke:#fff,stroke-width:2px,color:#fff

    %% External Services
    Internet((Public Internet)):::network
    CF[Cloudflare DNS/Proxy]:::network
    Telegram((Telegram API)):::network

    Internet <--> CF

    %% Tailscale Network Box
    subgraph TailscaleMesh ["Tailscale Mesh Network (Private VPN)"]
        direction TB

        %% Cloud Nodes
        subgraph CloudInfrastructure ["Cloud Infrastructure"]
            Hetzner["Hetzner VPS (Finland)\n[CTF SSH, Fallback Web, Netdata]"]:::cloud
            Oracle["Oracle Cloud (São Paulo)\n[Vaultwarden, Trilium, Uptime Kuma, Netdata]"]:::cloud
        end

        %% Home Nodes
        subgraph HomeNetwork ["Home Network"]
            RPi["Raspberry Pi 3\n[Tailscale Subnet Router, Home Assistant, Netdata]"]:::personal
            MacMini["Mac Mini M1\n[Local LLMs, Netdata]"]:::personal
            Nitro["Acer Nitro 5\n[Workstation, Netdata]"]:::personal
        end

        %% CACCo Nodes
        subgraph CACCoOnPremise ["CACCo On-Premise"]
            CACCo1["CACCo Intel Server 1\n[Websites, Passwords, Netdata]"]:::cacco
            CACCo2["CACCo Intel Server 2\n[Redundancy, Netdata]"]:::cacco
        end
        
        %% Connect everything in Tailscale
        Hetzner -.- Oracle
        Oracle -.- RPi
        Hetzner -.- RPi
        RPi -.- MacMini
        RPi -.- Nitro
        Hetzner -.- CACCo1
        Oracle -.- CACCo1
        CACCo1 -.- CACCo2
    end

    %% External Connections
    CF -- "Web Traffic" --> Hetzner
    CF -- "Cloudflare Tunnels" --> CACCo1
    
    %% Backup
    GDRIVE[("Google Drive (5TB)\n[rsync/rclone backups]")]:::storage
    Oracle -. "Nightly Backups" .-> GDRIVE
    Hetzner -. "Nightly Backups" .-> GDRIVE
    CACCo1 -. "Nightly Backups" .-> GDRIVE
    CACCo2 -. "Nightly Backups" .-> GDRIVE

    %% Monitoring Alerts
    Oracle -. "Uptime & Resource Alerts" .-> Telegram
    Hetzner -. "SSH/Resource Alerts" .-> Telegram
    CACCo1 -. "SSH/Resource Alerts" .-> Telegram
    RPi -. "SSH/Resource Alerts" .-> Telegram

```

## Topology Notes:
1.  **Tailscale Mesh:** Every node sits on the Tailscale network. You can access the Trilium server on Oracle Cloud directly from your Acer Nitro 5 via its Tailscale IP (e.g., `100.x.y.z`), without exposing Trilium to the public internet.
2.  **Raspberry Pi as Subnet Router:** If you need to access smart home devices or other non-Tailscale devices on your home network while away, the RPi can advertise your home subnet to Tailscale. It's lightweight enough to handle VPN routing without sweating.
3.  **Public Exposure:** Cloudflare proxies traffic for your domains (`leazirondi.com.br`, `cacco.com.br`) and forwards it only to the specific servers hosting public services (e.g., websites). You can use **Cloudflare Tunnels** (`cloudflared`) on the CACCo servers so you don't even need to open inbound ports on the college firewall. The Hetzner box will have port 22 (or a custom port) open specifically for the CTF SSH server.
