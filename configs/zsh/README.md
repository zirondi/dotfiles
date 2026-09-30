# Modular ZSH Configuration

This directory contains a modularized configuration setup for ZSH, designed to provide a consistent experience across macOS and Linux systems.

## Files and Directories

- **`.zshrc`**: The main entry point. It sets up `oh-my-zsh` and conditionally sources all configurations from the `shared` directory and the OS-specific directory (`macos` or `linux`).
- **`.zshrc_essentials`**: Contains absolute essentials that need to be universally applied regardless of OS, such as history settings and Kitty terminal title tab manipulation.
- **`shared/`**: Put files here that contain aliases, plugins (starship, zoxide, fzf), or configurations that should be active on *both* macOS and Linux.
- **`macos/`**: macOS-specific setup, such as darwin rebuild commands, Homebrew fixes, or macOS-only CLI tool configurations.
- **`linux/`**: Linux-specific setup, such as NixOS rebuild commands, apt/pacman aliases, etc.

## Propagating to Remote Servers

If you use Kitty, your `ssh.conf` automatically copies the `.zshrc`, `.zshrc_essentials`, and both the `shared/` and `linux/` folders to your remote host when you use `kitten ssh <host>`. This ensures your familiar Linux aliases and plugins travel with you without extra setup.
