# ~/.zshrc
# Zsh configuration entry point (Home Manager handles plugins and history)

# Completion styling (compinit itself is run by Home Manager: enableCompletion)
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# --- Modular Configuration Loading ---
ZSH_CONFIG_DIR=~/dotfiles/configs/zsh

# Load Shared Configurations
if [[ -d "$ZSH_CONFIG_DIR/shared" ]]; then
  for config_file in "$ZSH_CONFIG_DIR/shared"/*.zsh; do
    source "$config_file"
  done
fi

# Load OS-Specific Configurations
if [[ "$OSTYPE" == "darwin"* ]]; then
  if [[ -d "$ZSH_CONFIG_DIR/macos" ]]; then
    for config_file in "$ZSH_CONFIG_DIR/macos"/*.zsh; do
      source "$config_file"
    done
  fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if [[ -d "$ZSH_CONFIG_DIR/linux" ]]; then
    for config_file in "$ZSH_CONFIG_DIR/linux"/*.zsh; do
      source "$config_file"
    done
  fi
fi

# Load Shared Essentials (History, Kitty Title)
source ~/.zshrc_essentials
