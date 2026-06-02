#!/usr/bin/env bash
set -euo pipefail

rows=0
cols=0
agent_cmd=""

for arg in "$@"; do
  case "$arg" in
    --rows=*) rows="${arg#--rows=}" ;;
    --cols=*) cols="${arg#--cols=}" ;;
    --claude) agent_cmd="claude" ;;
    --codex) agent_cmd="codex" ;;
    --agy) agent_cmd="agy" ;;
  esac
done

if [ "$rows" -eq 0 ] || [ "$cols" -eq 0 ]; then
  echo "Usage: grid.sh --rows=R --cols=C [--claude]" >&2
  exit 1
fi

total=$((rows * cols))
win=$(tmux display-message -p '#{window_id}')
active=$(tmux display-message -p '#{pane_id}')

n=$(tmux list-panes -t "$win" | wc -l | tr -d ' ')

# Kill extraneous panes from the end to reach exact count
while [ "$n" -gt "$total" ]; do
  last=$(tmux list-panes -t "$win" -F '#{pane_id}' | tail -1)
  tmux kill-pane -t "$last"
  n=$((n - 1))
done

# Create missing panes
if [ "$n" -lt "$total" ]; then
  cwd=$(tmux display-message -p '#{pane_current_path}')
  case "$cwd" in */zinit/plugins/*) cwd="$HOME" ;; esac
  while [ "$n" -lt "$total" ]; do
    tmux split-window -t "$win" -c "$cwd"
    tmux select-layout -t "$win" tiled
    n=$((n + 1))
  done
fi

ids=()
while IFS= read -r p; do ids+=("${p#%}"); done \
  < <(tmux list-panes -t "$win" -F '#{pane_id}')

W=$(tmux display-message -t "$win" -p '#{window_width}')
H=$(tmux display-message -t "$win" -p '#{window_height}')

# Compute column widths and x positions
aw=$((W - (cols - 1)))
col_w=()
col_x=(0)
rem_w=$aw
for ((c=0; c<cols; c++)); do
  cw=$((rem_w / (cols - c)))
  col_w+=("$cw")
  rem_w=$((rem_w - cw))
  if [ "$c" -lt $((cols - 1)) ]; then
    col_x+=($((col_x[c] + cw + 1)))
  fi
done

# Compute row heights and y positions
ah=$((H - (rows - 1)))
row_h=()
row_y=(0)
rem_h=$ah
for ((r=0; r<rows; r++)); do
  rh=$((rem_h / (rows - r)))
  row_h+=("$rh")
  rem_h=$((rem_h - rh))
  if [ "$r" -lt $((rows - 1)) ]; then
    row_y+=($((row_y[r] + rh + 1)))
  fi
done

# Build layout string
if [ "$rows" -eq 1 ] && [ "$cols" -eq 1 ]; then
  layout="${W}x${H},0,0,${ids[0]}"
elif [ "$rows" -eq 1 ]; then
  layout="${W}x${H},0,0{"
  for ((c=0; c<cols; c++)); do
    [ "$c" -gt 0 ] && layout+=","
    layout+="${col_w[$c]}x${H},${col_x[$c]},0,${ids[$c]}"
  done
  layout+="}"
elif [ "$cols" -eq 1 ]; then
  layout="${W}x${H},0,0["
  for ((r=0; r<rows; r++)); do
    [ "$r" -gt 0 ] && layout+=","
    layout+="${W}x${row_h[$r]},0,${row_y[$r]},${ids[$r]}"
  done
  layout+="]"
else
  layout="${W}x${H},0,0["
  for ((r=0; r<rows; r++)); do
    [ "$r" -gt 0 ] && layout+=","
    h="${row_h[$r]}"
    y="${row_y[$r]}"
    layout+="${W}x${h},0,${y}{"
    for ((c=0; c<cols; c++)); do
      [ "$c" -gt 0 ] && layout+=","
      layout+="${col_w[$c]}x${h},${col_x[$c]},${y},${ids[$((r * cols + c))]}"
    done
    layout+="}"
  done
  layout+="]"
fi

# Compute tmux layout checksum
csum=0
for ((i=0; i<${#layout}; i++)); do
  c=$(printf '%d' "'${layout:$i:1}")
  csum=$(( ((csum >> 1) | ((csum & 1) << 15)) + c ))
  csum=$((csum & 0xFFFF))
done

tmux select-layout -t "$win" "$(printf '%04x' $csum),${layout}"

if [ -n "$agent_cmd" ]; then
  # Skip the user's active pane and any pane already running the agent so the
  # binding is idempotent — re-running in an existing window won't type
  # "claude" into a running claude session.
  for ((i=0; i<total && i<${#ids[@]}; i++)); do
    pane_id="%${ids[$i]}"
    [ "$pane_id" = "$active" ] && continue
    cmd=$(tmux display-message -p -t "$pane_id" '#{pane_current_command}')
    case "$cmd" in
      "$agent_cmd"*) continue ;;
    esac
    tmux send-keys -t "$pane_id" "$agent_cmd" Enter
  done
fi

# Re-select active pane if it survived, otherwise pick first
if tmux list-panes -t "$win" -F '#{pane_id}' | grep -q "^${active}$"; then
  tmux select-pane -t "$active"
else
  tmux select-pane -t "%${ids[0]}"
fi
