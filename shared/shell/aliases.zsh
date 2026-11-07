# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'

# Reload Zsh configuration
alias reload='exec zsh -l'

# Modern file listing
if (( $+commands[eza] )); then
  alias ll='eza -lah --group-directories-first'
  alias la='eza -a'
  alias lt='eza --tree --level=2'
fi

# Syntax-highlighted file viewer
if (( $+commands[bat] )); then
  alias b='bat'
  alias bp='bat --plain'
fi

# VSCodium installs its CLI as "codium"; keep the familiar "code"
if (( $+commands[codium] )) && ! (( $+commands[code] )); then
  alias code='codium'
fi
