# --- Starship Prompt ---
eval "$(starship init zsh)"

# --- Zoxide ---
eval "$(zoxide init zsh)"

# --- fzf ---
source <(fzf --zsh)

# --- SSH Autocomplete Tweaks ---
# Tell Zsh to use the exact same autocompletion as 'ssh' for your 'remote' alias
compdef _ssh remote

# Force SSH autocomplete to ONLY complete hosts (ignoring users like 'root' or 'zirondi')
zstyle ':completion:*:ssh:*:*' tag-order hosts

# Force SSH autocomplete to ONLY read from ~/.ssh/config and ~/.ssh/known_hosts (ignoring /etc/hosts)
# We also parse known_hosts strictly to strip out brackets, ports, and deduplicate everything cleanly.
_my_ssh_hosts=($(awk '/^Host / {for(i=2; i<=NF; i++) if($i !~ /[*?]/) print $i}' ~/.ssh/config 2>/dev/null))
_my_ssh_hosts+=($(awk '{split($1, a, ","); for(i in a) { host=a[i]; gsub(/^\[|\]:[0-9]+$/, "", host); if(host !~ /\|/) print host }}' ~/.ssh/known_hosts 2>/dev/null))
zstyle ':completion:*:ssh:*' hosts ${(u)_my_ssh_hosts}
