# Initialize Zsh completion system.
# The full security check of completion directories runs at most
# once a day; other shells reuse the cached dump (compinit -C).
autoload -Uz compinit
() {
  local dump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
  local -a stale
  mkdir -p "${dump:h}"
  stale=("$dump"(N.mh+24))

  if [[ ! -f "$dump" ]] || (( $#stale )); then
    compinit -d "$dump"
    # compinit only rewrites the dump when completions change;
    # touch it so the daily check does not repeat on every shell.
    touch "$dump"
  else
    compinit -C -d "$dump"
  fi
}

# Interactive completion menu.
zstyle ':completion:*' menu select

# Case-insensitive matching.
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}'

# Group completion results.
zstyle ':completion:*' group-name ''

# Show descriptions.
zstyle ':completion:*:descriptions' format '%F{cyan}%d%f'

# Enable selection using arrow keys in completion menus.
zmodload zsh/complist

# Search command history by typed prefix.
autoload -Uz up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search

zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# Common application-cursor escape sequences.
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search