# ~/.zprofile
# Executed for login shells.

# --- Environment Variables ---
# Set Neovim as the default editor for all systems
export EDITOR="nvim"
export VISUAL="nvim"

# Add dotfiles scripts to PATH for easy access to monorepo management scripts
export PATH="$HOME/dotfiles/scripts:$PATH"