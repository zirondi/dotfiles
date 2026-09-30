# ~/.portable_zshrc
# Lightweight, Zero-Dependency Zsh Configuration for Kitty SSH

# --- Portable Specific Configs ---
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt appendhistory
setopt sharehistory
setopt incappendhistory
setopt hist_reduce_blanks

autoload -Uz compinit
compinit -u
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# --- Shared Essentials ---
# Load all cross-platform aliases, history tweaks, and Kitty tab titles
source ~/.zshrc_essentials

# --- Zsh Plugins (Syntax Highlighting & Autosuggestions) ---
# Auto-downloads lightweight Zsh plugins on new servers so your remote feels like home
if [ ! -d "$HOME/.local/share/zsh-plugins" ]; then
  echo "🎨 First time setup: Downloading Zsh plugins (Syntax Highlighting & Autosuggestions)..."
  mkdir -p "$HOME/.local/share/zsh-plugins"
  git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.local/share/zsh-plugins/zsh-syntax-highlighting" > /dev/null 2>&1
  git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git "$HOME/.local/share/zsh-plugins/zsh-autosuggestions" > /dev/null 2>&1
fi
source "$HOME/.local/share/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" 2>/dev/null
source "$HOME/.local/share/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" 2>/dev/null

# --- Essential Aliases ---
alias ls='ls --color=auto'
alias ll='ls -alF'

# --- Automatic Starship Bootstrap ---
# If starship isn't installed natively (like on a fresh university server), 
# this silently downloads the portable binary to ~/.local/bin without needing sudo.
export PATH="$HOME/.local/bin:$PATH"
if ! command -v starship &> /dev/null; then
  echo "🚀 First time setup: Downloading Starship binary to ~/.local/bin..."
  mkdir -p ~/.local/bin
  # The -y skips the confirmation prompt, -b specifies the bin dir
  curl -sS https://starship.rs/install.sh | sh -s -- -y -b ~/.local/bin > /dev/null
fi

# --- Starship Prompt ---
eval "$(starship init zsh)"
