# Command history

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

# Append each command to the history file as it runs.
setopt INC_APPEND_HISTORY

# Keep only the latest copy of a repeated command.
setopt HIST_IGNORE_ALL_DUPS

# Remove unnecessary whitespace.
setopt HIST_REDUCE_BLANKS

# Commands starting with a space are not saved.
setopt HIST_IGNORE_SPACE

# Do not record the history command itself.
setopt HIST_NO_STORE