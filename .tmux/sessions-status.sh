#!/bin/sh
current=$(tmux display-message -p '#S' 2>/dev/null)
out=''
for entry in 1:perso 2:beside 3:control; do
  num="${entry%%:*}"
  name="${entry#*:}"
  tmux has-session -t "$name" 2>/dev/null || continue
  if [ "$name" = "$current" ]; then
    out="${out}#[fg=colour0,bg=colour178] ${num}-${name} #[bg=default,fg=colour178]│"
  else
    out="${out}#[fg=colour245] ${num}-${name} #[fg=colour178]│"
  fi
done
printf '%s' "$out"
