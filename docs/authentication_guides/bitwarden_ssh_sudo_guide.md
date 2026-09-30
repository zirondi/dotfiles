# Bitwarden SSH Agent & Remote Sudo Guide

This guide will walk you through replacing server passwords with SSH keys stored in Bitwarden, and using those keys to authenticate both SSH logins and remote `sudo` commands.

## Prerequisites & Architecture
*   **The Goal**: You will no longer type passwords for your servers. Instead, Bitwarden will act as your `ssh-agent`. 
*   **macOS (No Touch ID)**: Since your Mac Mini lacks Touch ID, Bitwarden will rely on its Vault Timeout settings. When you attempt an SSH/sudo action, if the vault is locked, you will type your Master Password once. If unlocked, the action happens instantly. *(Pro tip: If you wear an Apple Watch, you can configure macOS and Bitwarden to use your Watch to approve these prompts!)*
*   **SSH Forwarding**: Your local `ssh-agent` connection will be "forwarded" to the remote server so the server can talk back to Bitwarden on your laptop/Mac when you type `sudo`.

---

## Phase 1: Create the Key in Bitwarden

1. Open the Bitwarden Desktop app on either your Mac or Linux laptop.
2. Go to **Settings > SSH Agent**.
3. Check **Enable SSH Agent**.
4. Click **Create new key**. Generate an **Ed25519** key. Name it something like "Server Infrastructure Key". 
5. Copy the **Public Key** to your clipboard. You will need this for the servers.

---

## Phase 2: Client Setup

### 1. macOS (Mac Mini) Setup

You need to tell macOS to stop using its default SSH agent and use Bitwarden's instead.

1.  Open your terminal profile file (`nano ~/.zprofile` or `nano ~/.zshrc`).
2.  Add this exact line to point to Bitwarden's socket:
    ```bash
    export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.bitwarden.desktop/ssh-agent.sock"
    ```
3.  Apply the changes: `source ~/.zprofile`.
4.  Configure SSH to forward this agent to your servers. Edit `nano ~/.ssh/config`:
    ```ssh-config
    Host *
        ForwardAgent yes
    ```
    *(Note: Using `Host *` forwards your agent to every server. For higher security, replace `*` with your specific server IPs or hostnames).*

### 2. NixOS (Laptop) Client Setup

1.  Ensure you have the Bitwarden desktop app installed via your `configuration.nix` or `home.nix` (e.g., `environment.systemPackages = [ pkgs.bitwarden ];`).
2.  Open Bitwarden and enable the SSH Agent in Settings.
3.  Find the socket path. On Linux, it is typically in your home directory. Add this to your shell profile (e.g., in your `home-manager` zsh/bash config, or `~/.bashrc`):
    ```bash
    export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
    ```
    *(Check Bitwarden's SSH Agent settings page; it will display the exact path for your system).*
4.  Just like macOS, configure your `~/.ssh/config` to forward the agent:
    ```ssh-config
    Host *
        ForwardAgent yes
    ```

---

## Phase 3: Server Setup (SSH Login)

Before doing the fancy `sudo` trick, ensure standard SSH works.

For **every server (NixOS, Ubuntu, Arch)**:
1. Log in normally using your password.
2. Edit `~/.ssh/authorized_keys` and paste the **Public Key** you copied from Bitwarden.
3. Log out and try to SSH back in. Bitwarden on your client should approve the login without asking for the server's password.
4. *(Highly Recommended)* Once it works, edit `/etc/ssh/sshd_config` on the servers and set `PasswordAuthentication no`. Restart the SSH service.

---

## Phase 4: Remote Sudo Setup (`pam_ssh_agent_auth`)

Now, we configure the servers to accept your forwarded Bitwarden SSH agent for `sudo` privileges.

### Ubuntu / Debian Servers

1. Install the PAM module:
   ```bash
   sudo apt update && sudo apt install libpam-ssh-agent-auth
   ```
2. By default, this module looks for keys in `/etc/security/authorized_keys`. Create this file and add your public key:
   ```bash
   sudo mkdir -p /etc/security
   echo "YOUR_PUBLIC_KEY_HERE" | sudo tee /etc/security/authorized_keys
   sudo chmod 644 /etc/security/authorized_keys
   ```
3. Configure `sudo` to preserve your SSH connection. Run `sudo visudo` and add this line below the other `Defaults` lines:
   ```text
   Defaults env_keep += "SSH_AUTH_SOCK"
   ```
4. Finally, tell PAM to use it. Edit `sudo nano /etc/pam.d/sudo`. Add this line **at the very top**, just below the comments:
   ```text
   auth sufficient pam_ssh_agent_auth.so file=/etc/security/authorized_keys
   ```
   *Test it by opening a NEW terminal, SSHing in, and typing `sudo ls`. If it fails, your old terminal session with root access is still open to fix it!*

### Arch Linux Servers

The process is almost identical to Debian, but you must build the module from the AUR.

1. Install from AUR:
   ```bash
   yay -S pam_ssh_agent_auth
   ```
2. Follow **Steps 2, 3, and 4** exactly as written in the Ubuntu/Debian section above. The file paths and `visudo` configurations are identical on Arch.

### NixOS Servers

NixOS makes this beautifully simple through declarative configuration. 

1. Open your server's `configuration.nix`.
2. Ensure your user account is configured with your SSH public key.
3. Add the following blocks to enable the PAM module and configure `sudo` to preserve the environment variable:

```nix
  # 1. Ensure your user has the public key
  users.users.your_username = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "YOUR_PUBLIC_KEY_HERE"
    ];
  };

  # 2. Enable SSH Agent Auth for PAM (Sudo)
  security.pam.sshAgentAuth.enable = true;

  # 3. Ensure sudo keeps the SSH_AUTH_SOCK environment variable
  security.sudo.extraConfig = ''
    Defaults env_keep += "SSH_AUTH_SOCK"
  '';
```

4. Rebuild the system: `sudo nixos-rebuild switch`. 
5. Log out, SSH back in (ensure Agent Forwarding is on), and type `sudo ls`. It will seamlessly authenticate using Bitwarden on your local machine!
