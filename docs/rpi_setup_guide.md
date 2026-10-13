# NixOS Raspberry Pi Setup Guide (Docker Remote Build Workflow)

This guide walks you through deploying your Raspberry Pi infrastructure declaratively using NixOS, specifically optimized for low-resource devices like the Pi 3B+ by delegating the heavy compiling to another computer using Docker.

## Step 1: Prep the Live Environment & Bootstrap
If you are starting from a completely fresh NixOS Live CD (or SD card image), boot the Pi and connect a monitor and keyboard.

1. Generate the hardware configuration (so Nix knows your exact SD card UUIDs):
   ```bash
   sudo nixos-generate-config
   ```
2. Set a temporary password for the `nixos` user so we can SSH in:
   ```bash
   passwd
   ```
3. Start the SSH server and find the temporary DHCP IP address:
   ```bash
   sudo systemctl start sshd
   ip a
   ```

## Step 2: Push the Bootstrap Configuration
We need to copy the hardware configuration to your local repository, and push an ultra-lightweight "bootstrap" configuration back to the Pi. This initial config creates the swap, ZRAM, and marks your user as a trusted remote builder.

1. On your host computer, pull the new hardware config:
   ```bash
   cd ~/dotfiles/hosts/rpi3
   scp nixos@<PI_TEMPORARY_IP>:/etc/nixos/hardware-configuration.nix .
   ```
2. Push the `initial-configuration.nix` to the Pi's home directory (because `/etc/nixos/` requires `root` privileges):
   ```bash
   scp initial-configuration.nix nixos@<PI_TEMPORARY_IP>:~
   ```
3. SSH back into the Pi and move the file into place:
   ```bash
   ssh nixos@<PI_TEMPORARY_IP>
   sudo mv ~/initial-configuration.nix /etc/nixos/configuration.nix
   ```

## Step 3: Local Bootstrap Rebuild
Go back to the Raspberry Pi's keyboard and run the rebuild locally. Because this config is completely barebones, it will take less than a minute.

```bash
sudo nixos-rebuild switch
```

**Once it finishes, the Pi is fully bootstrapped!** It will now be trusted to accept remote builds, it has 2GB of swap, ZRAM is enabled, and its IP has permanently shifted to `10.0.0.10`.

## Step 4: Setup Secrets and Backups
From your host computer, SSH into the new permanent IP:
```bash
ssh zirondi@10.0.0.10
```

1. Change your default temporary password immediately:
   ```bash
   passwd
   ```
2. Create the secret files for your services:
   ```bash
   # Pi-hole Admin Password
   sudo mkdir -p /var/lib/pihole
   echo 'WEBPASSWORD=your_secure_password' | sudo tee /var/lib/pihole/secrets.env
   sudo chmod 600 /var/lib/pihole/secrets.env

   # Cloudflared Tunnel Token
   sudo mkdir -p /var/lib/cloudflared
   echo 'TUNNEL_TOKEN=your_actual_token_here' | sudo tee /var/lib/cloudflared/token.env
   sudo chmod 600 /var/lib/cloudflared/token.env
   ```
3. Type `exit` to disconnect.

### Step 4b: Google Drive Backup Authentication
Because Google Drive uses OAuth2, you must authenticate it on a computer with a web browser and push the token to the Pi's root user.

1. On a computer with a web browser, install rclone and configure it:
   ```bash
   rclone config
   ```
   *(Press `n` for New remote, name it **`gdrive`**, select Google Drive (`drive`), and follow the browser prompts to log in).*
2. Push the config to the Pi's root user:
   ```bash
   ssh root@10.0.0.10 "mkdir -p /root/.config/rclone"
   scp ~/.config/rclone/rclone.conf root@10.0.0.10:/root/.config/rclone/rclone.conf
   ```

## Step 5: The Full Remote Build (Atomized Part 2)
Now that the Pi is bootstrapped and trusted, the full system is built on the Mac and only copied to the Pi. The Pi never compiles anything: with 1 GB of RAM, building its kernel there takes days (the `linux-rpi` kernel comes from `nixos-hardware`, so it is not in the NixOS binary cache).

Run the deployment script from the Mac:
```bash
./scripts/deploy.sh rpi3 root@rpi3 --nix
```

What happens:
1. The flake is evaluated on the Mac.
2. The system is built inside the `nix-builder` container (a `nixos/nix` image running in the Podman machine, which is `aarch64-linux` like the Pi). It is created on first use and keeps its store in the `nix-builder-store` volume, so later builds only redo what changed.
3. Only the store paths the Pi does not have yet are copied over SSH, and the new generation is activated.

Useful variants:
- `./scripts/deploy.sh rpi3 --nix --build-only` — build without touching the Pi.
- `./scripts/deploy.sh rpi3 root@rpi3 --nix --build-on target` — old behaviour (build on the Pi).
- `just clean builder` — garbage-collect the builder's store.

The first build after a kernel bump compiles the kernel. Give the Podman machine at least 4 GiB for it (`podman machine stop && podman machine set --memory 4096 && podman machine start`); below that the builder limits itself to 2 cores.

## Step 6: Final Verification
Everything is now running automatically via `systemd` and `podman`!
- **Pi-hole Admin:** `http://10.0.0.10/admin`
