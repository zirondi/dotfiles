# Introducing a YubiKey to your Bitwarden Workflow

When you introduce a hardware token like a YubiKey (or any FIDO2 security key) to this setup, you have an important architectural decision to make. You can either use the YubiKey to protect your **Password Manager**, or you can use it to protect the **Servers directly**.

Here are the two ways this integration works, and how to set them up.

---

## Option 1: The "Vault Lock" Method (Recommended starting point)

In this setup, you continue using the Bitwarden SSH Agent exactly as described in the previous guide. The YubiKey is used to secure your Bitwarden account itself.

*   **How it works:** You configure Bitwarden to require the YubiKey as your Two-Step Login (2FA) method. 
*   **The Security Benefit:** If an attacker steals your Bitwarden Master Password, they cannot access your vault (and therefore cannot access your SSH keys or servers) without physically possessing your YubiKey.
*   **The Experience:** When you log into Bitwarden on your Mac or Linux laptop, you will type your Master Password and then physically tap the YubiKey. Once the vault is unlocked, your SSH and `sudo` commands will happen smoothly and seamlessly without requiring a tap every single time.

### How to set it up:
1. Log into your **Bitwarden Web Vault** (this must be done in the browser, not the desktop app).
2. Go to **Settings > Security > Two-Step Login**.
3. Locate the **FIDO2 WebAuthn** option and click **Manage**.
4. Click **Add Credential**, plug in your YubiKey, and tap it when prompted by your browser.
5. *(Important!)* Save the recovery codes Bitwarden gives you in a safe physical location. If you lose your YubiKey, these codes are the only way to get your SSH keys back!

---

## Option 2: The "Touch-to-Authenticate" Method (Maximum Security)

In this setup, you **do not** store the SSH private key in Bitwarden. Instead, the SSH key is generated directly inside the physical YubiKey itself. 

*   **How it works:** The private key material is locked in the YubiKey's Secure Element. You bypass the Bitwarden SSH Agent and use standard `ssh-agent` tools provided by macOS/Linux to talk to the USB device.
*   **The Security Benefit:** Absolute proof of physical presence. Malware cannot steal the key, and a hacker who takes over your computer remotely cannot SSH or run `sudo` on your servers unless a human is sitting at the desk physically touching the flashing USB key.
*   **The Experience:** Every single time you type `ssh user@server` or run a remote `sudo` command via `pam_ssh_agent_auth`, the terminal will freeze, the YubiKey will flash, and you must physically tap it to authorize the action.

### How to set it up:
1. Open your terminal on Mac or Linux. Ensure your YubiKey is plugged in.
2. Generate a hardware-backed FIDO2 key by running:
   ```bash
   ssh-keygen -t ed25519-sk -O resident -O application=ssh:MyServerKey -f ~/.ssh/id_yubikey
   ```
   *(Note: The key will flash during this process. Tap it to generate the key.)*
3. This creates a "stub" private key file `~/.ssh/id_yubikey` and a public key `~/.ssh/id_yubikey.pub`. 
4. Add the public key to your servers' `authorized_keys` files just like before.
5. In your `~/.ssh/config`, tell SSH to use this specific hardware key:
   ```ssh-config
   Host *
       IdentityFile ~/.ssh/id_yubikey
       ForwardAgent yes
   ```
6. **Disable the Bitwarden SSH Agent** in the desktop app, and remove the `export SSH_AUTH_SOCK` lines from your shell profile so your OS goes back to handling standard SSH key files.

---

## Which should you choose?

*   Choose **Option 1** if you want convenience. Typing a Master Password once a day and letting Bitwarden handle the rest is a massive security upgrade over typing server passwords, and it's much less annoying than tapping a USB stick 20 times a day when running multiple `sudo` commands.
*   Choose **Option 2** for your most critical infrastructure (like the server hosting your self-hosted Bitwarden instance). It is highly recommended to use a physical YubiKey lock for your primary recovery infrastructure!
