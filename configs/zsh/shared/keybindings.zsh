# --- Shared ZSH Keybindings ---
# Ensures Home, End, Delete, and word-navigation keys work correctly
# across all terminal emulators (Kitty, xterm, SSH) and operating systems.
#
# These cover both xterm-style (\e[H) and application-mode (\eOH) sequences
# since different terminals and $TERM values emit different codes.

# Home → beginning of line
bindkey "^[[H"  beginning-of-line
bindkey "^[OH"  beginning-of-line

# End → end of line
bindkey "^[[F"  end-of-line
bindkey "^[OF"  end-of-line

# Delete → delete character forward
bindkey "^[[3~" delete-char

# Ctrl+Left/Right → jump word by word
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

# Ctrl+Backspace → delete entire word backward
bindkey "^H" backward-kill-word
