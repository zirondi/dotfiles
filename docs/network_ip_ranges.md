# Network IP Address Management (IPAM) Plan

This document defines the IP address ranges (subnets) used across your infrastructure. Keeping these organized prevents IP conflicts, especially when dealing with VPNs (Tailscale), local networks, and container engines (Docker/Podman).

## 1. Local Area Network (LAN)
This is your physical home network (Wi-Fi and Ethernet) managed by your ISP Router (Askey). Since you mentioned using a `10.X.X.X` network, here is the standard convention:

*   **Subnet:** `10.0.0.0/24`
*   **IP Range:** `10.0.0.1` to `10.0.0.254`
*   **Usage:** Your trusted physical devices (Mac Mini, Acer Nitro, Raspberry Pi, smartphones).
*   **Example Assignments:**
    *   `10.0.0.1`: Askey Router (Gateway)
    *   `10.0.0.5`: Raspberry Pi (Static IP)
    *   `10.0.0.10`: Mac Mini M1 (Static IP)
    *   `10.0.0.100 - 10.0.0.200`: DHCP Range for phones/laptops.

## 2. Tailscale Mesh Network (VPN)
Tailscale automatically assigns IPs from the Carrier-Grade NAT (CGNAT) space. You cannot change this range, but you should document it so you recognize it when configuring services.

*   **Subnet:** `100.64.0.0/10`
*   **IP Range:** `100.64.0.1` to `100.127.255.254`
*   **Usage:** Secure, encrypted communication between your devices anywhere in the world.
*   **Example Assignments (Auto-assigned by Tailscale):**
    *   `100.69.134.71`: Raspberry Pi (`rpi3`, subnet router for `10.0.0.0/24`)
    *   `100.115.88.115`: Hetzner VPS (`hetzner`)
    *   `100.115.45.60`: Oracle Cloud VPS
    *   `100.80.90.100`: Acer Nitro 5

## 3. Container Networks (Podman / Docker)
When you run containers (like Home Assistant, Pi-hole, Netdata), the container engine creates virtual networks for them to talk to each other. By default, they use the `172.16.x.x` space.

*   **Subnet:** `172.16.0.0/12` (Commonly defaults to `172.17.0.0/16` for the default bridge)
*   **IP Range:** `172.16.0.1` to `172.31.255.254`
*   **Usage:** Internal communication between containers on the same host (e.g., a web container talking to a database container on the Oracle VPS).
*   **Note:** You rarely need to interact with these IPs directly. In our NixOS config, we used `--network=host` for Home Assistant and mapped specific ports for Pi-hole, which bypasses this isolation and uses the host's IPs directly.

---

## 4. Future Expansion Ranges (VLANs)
As your infrastructure grows, you may want to segment your network. If you ever flash OpenWrt on a router or get a managed switch, here are the recommended subnets to use to prevent overlapping:

### A. IoT / Smart Home Network
*   **Subnet:** `10.0.20.0/24`
*   **Usage:** Untrusted smart devices (smart bulbs, smart TVs, vacuum cleaners).
*   **Why?** IoT devices are notorious for security vulnerabilities and calling home to weird servers. Isolating them means if a smart bulb is compromised, it cannot access your Mac Mini or Password Manager. Home Assistant on the Pi can be configured to bridge this gap securely.

### B. Guest Wi-Fi Network
*   **Subnet:** `10.0.30.0/24`
*   **Usage:** Wi-Fi for visiting friends/family.
*   **Why?** Prevents guests from accidentally casting to your TVs, seeing your shared Mac Mini folders, or trying to access your Pi-hole admin panel.

### C. DMZ / Public Facing Servers
*   **Subnet:** `10.0.40.0/24`
*   **Usage:** If you ever host physical servers at home that are exposed to the internet (without using Cloudflare Tunnels). 
*   **Why?** Strict firewall rules can be applied to ensure compromised web servers cannot access the rest of your internal home network.

## Summary Checklist to Avoid Conflicts
1. **Never** use `100.64.0.0/10` for your local network (Tailscale relies on this).
2. **Avoid** using `172.16.x.x` to `172.31.x.x` for your home router (Podman/Docker relies on this).
3. **Stick to** blocks within `10.0.x.x` or `192.168.x.x` for your home LAN and future VLANs.
