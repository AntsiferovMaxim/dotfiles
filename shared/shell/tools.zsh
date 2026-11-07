# Optional interactive shell tools

# Smart directory navigation
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi

# Fuzzy finder
if (( $+commands[fzf] )); then
  source <(fzf --zsh)
fi

# Per-project tool versions (node, rust, python, ...)
if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
fi

# Per-project environment variables from .envrc
if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
fi

# Prompt
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

# Source the first existing plugin file among Homebrew and common
# Linux package locations.
_source_plugin() {
  local name="$1" dir
  for dir in \
    "${HOMEBREW_PREFIX:-/opt/homebrew}/share/$name" \
    "/usr/share/$name" \
    "/usr/share/zsh/plugins/$name"; do
    if [[ -r "$dir/$name.zsh" ]]; then
      source "$dir/$name.zsh"
      return
    fi
  done
}

# Suggest commands from history as you type (accept with →).
_source_plugin zsh-autosuggestions

# Must be sourced last: it wraps every widget defined before it.
_source_plugin zsh-syntax-highlighting

unfunction _source_plugin
