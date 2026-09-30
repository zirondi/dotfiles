# Tailscale Subnet Router Setup

Because Tailscale is natively built into your NixOS configuration (`rpi-services.nix`), the background daemon is already running automatically on your Raspberry Pi! 

However, you still need to log the Pi into your Tailscale account (your "Tailnet") for the very first time. Because IP forwarding is enabled in your configuration, this guide will also show you how to configure the Pi as a **Subnet Router**, which allows you to access your entire home network remotely from anywhere in the world.

## Step 1: Authenticate the Pi
You must trigger the authentication URL from the Pi's command line.

1. SSH into the Pi from your computer:
   ```bash
   ssh root@10.0.0.10
   ```
2. Run the Tailscale startup command:
   ```bash
   tailscale up --advertise-routes=10.0.0.0/24 --accept-dns=false
   ```
   *(Note: `--accept-dns=false` is important so Tailscale doesn't accidentally override your local Pi-hole DNS settings on the Pi itself).*
3. The terminal will spit out an authentication URL. **Copy and paste that URL into your computer's browser** and log in with your Tailscale account to authorize the node.

## Step 2: Approve the Subnet Route (Admin Console)
Even after authenticating, Tailscale requires an admin to explicitly approve the subnet route for security reasons.

1. Go to your [Tailscale Admin Console](https://login.tailscale.com/admin/machines) in your browser.
2. Find the Raspberry Pi in the list of machines.
3. Click the three dots (`...`) on the right side of the Pi's row and select **Edit route settings**.
4. Toggle the switch to approve the `10.0.0.0/24` subnet.

That's it! Your Pi is now permanently connected to your Tailnet and acting as a secure gateway into your home network.
