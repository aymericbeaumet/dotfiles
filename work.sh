#!/bin/bash
set -euo pipefail

# Colors (shared by work, _work_open, _work_ensure_repos, _work_list_and_select)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

work() {
  set -euo pipefail

  # Configurable via env vars
  local WORKDIR="${WORKDIR:-$HOME/beside}"
  local GIT_BRANCH_PREFIX="${GIT_BRANCH_PREFIX:-$USER/}"

  local only_repo=""
  local positional_args=()

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --client)
        only_repo="tma-clients"
        shift
        ;;
      --backend)
        only_repo="tma-backend"
        shift
        ;;
      --infra)
        only_repo="tma-infra"
        shift
        ;;
      --data)
        only_repo="tma-data"
        shift
        ;;
      -h|--help)
        echo -e "${BOLD}Usage:${NC} work.sh [--client|--backend|--infra|--data] [<topic...>]"
        echo ""
        echo "Creates git worktrees for TMA repos from \$WORKDIR/main into \$WORKDIR/<slug>/"
        echo ""
        echo -e "${BOLD}Without arguments:${NC}"
        echo "  Lists existing worktree directories and opens fzf to select one"
        echo ""
        echo -e "${BOLD}Options:${NC}"
        echo "  --client   Only tma-clients"
        echo "  --backend  Only tma-backend"
        echo "  --infra    Only tma-infra"
        echo "  --data     Only tma-data"
        echo "  -h, --help Show this help message"
        echo ""
        echo -e "${BOLD}Environment:${NC}"
        echo "  WORKDIR           Base directory (default: ~/beside)"
        echo "  GIT_BRANCH_PREFIX Branch prefix (default: \$USER/)"
        echo ""
        echo -e "${BOLD}Examples:${NC}"
        echo "  work.sh                        # fzf select from existing worktrees"
        echo "  work.sh --backend              # fzf select, filtered to dirs with tma-backend"
        echo "  work.sh fix subscriptions      # create worktrees for all repos"
        echo "  work.sh --backend auth refresh # create worktree only for tma-backend"
        return 0
        ;;
      -*)
        echo -e "${RED}Unknown option: $1${NC}"
        echo "Use --help for usage information"
        return 2
        ;;
      *)
        positional_args+=("$1")
        shift
        ;;
    esac
  done

  local base_root="${WORKDIR}/main"

  # If no positional args, list existing worktrees and offer fzf selection
  if [[ ${#positional_args[@]} -eq 0 ]]; then
    _work_list_and_select "$WORKDIR" "$only_repo"
    return $?
  fi

  # Build slug: join words with '-' and normalize
  local slug
  slug="$(
    printf '%s\n' "${positional_args[*]}" |
      tr '[:upper:]' '[:lower:]' |
      sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
  )"

  local out_root="${WORKDIR}/${slug}"
  local branch="${GIT_BRANCH_PREFIX}${slug}"

  # Ensure base_root exists
  mkdir -p "$base_root"

  # Clone missing repos (always all repos, filtering happens at worktree creation)
  _work_ensure_repos "$base_root"

  mkdir -p "$out_root"

  # Parallel fetch all repos upfront (much faster than sequential)
  echo -e "${CYAN}Fetching latest from all repos...${NC}"
  for repo_dir in "$base_root"/*; do
    [[ -d "$repo_dir" ]] || continue
    git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || continue
    git -C "$repo_dir" fetch --prune origin >/dev/null 2>&1 &
  done
  wait

  # Determine a sensible base ref to branch from:
  # prefer origin/main, then origin/master, then local main/master, else HEAD.
  _work_base_ref() {
    local repo_dir="$1"
    (
      cd "$repo_dir"
      if git show-ref --verify --quiet "refs/remotes/origin/main"; then
        echo "origin/main"
      elif git show-ref --verify --quiet "refs/remotes/origin/master"; then
        echo "origin/master"
      elif git show-ref --verify --quiet "refs/heads/main"; then
        echo "main"
      elif git show-ref --verify --quiet "refs/heads/master"; then
        echo "master"
      else
        echo "HEAD"
      fi
    )
  }

  # Iterate all directories under ~/beside/main/*
  local repo_dir repo wt_dir base_ref
  local cd_target="$out_root"
  shopt -s nullglob
  for repo_dir in "$base_root"/*; do
    [[ -d "$repo_dir" ]] || continue

    # Only treat as repo if it's a git worktree/repo
    if ! git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      continue
    fi

    repo="$(basename "$repo_dir")"

    # If a specific repo was requested, skip others
    if [[ -n "$only_repo" && "$repo" != "$only_repo" ]]; then
      continue
    fi

    wt_dir="${out_root}/${repo}-${slug}"

    if [[ -e "$wt_dir" ]]; then
      echo -e "${YELLOW}Worktree already exists:${NC} ${wt_dir}"
      # Still set cd_target for this repo
      if [[ -n "$only_repo" ]]; then
        cd_target="$wt_dir"
      fi
      continue
    fi

    # Prune stale worktree entries (handles deleted directories)
    git -C "$repo_dir" worktree prune

    base_ref="$(_work_base_ref "$repo_dir")"

    # Ensure local branch exists in the main worktree repo
    if git -C "$repo_dir" show-ref --verify --quiet "refs/heads/${branch}"; then
      echo -e "${CYAN}Branch exists:${NC} ${repo} -> ${branch}"
    else
      echo -e "${BLUE}Creating branch:${NC} ${repo} -> ${branch} (from ${base_ref})"
      git -C "$repo_dir" branch "$branch" "$base_ref"
    fi

    echo -e "${GREEN}Adding worktree:${NC} ${wt_dir}"
    git -C "$repo_dir" worktree add "$wt_dir" "$branch"

    # If a specific repo was requested, cd directly into it
    if [[ -n "$only_repo" ]]; then
      cd_target="$wt_dir"
    fi
  done
  shopt -u nullglob

  echo ""
  echo -e "${GREEN}${BOLD}Done.${NC} Worktrees rooted at: ${out_root}"

  # Open environment
  _work_open "$slug" "$cd_target"
}

_work_open() {
  local slug="$1"
  local target_dir="$2"

  echo -e "${CYAN}Preparing${NC} ${target_dir}"

  # Create tmux window with nvim+ClaudeCode on left (62%), shell on right (38%)
  # Golden ratio: φ ≈ 1.618, so φ/(1+φ) ≈ 62%
  if command -v tmux &>/dev/null && [[ -n "${TMUX:-}" ]]; then
    # Left pane: nvim with :ClaudeCode (golden ratio - wider)
    tmux new-window -n "$slug" -c "$target_dir" "nvim -c 'ClaudeCode' ."
    # Right pane: shell (38%)
    tmux split-window -h -l 38% -c "$target_dir"
    # Focus nvim pane
    tmux select-pane -t 1
    # Open Cursor IDE
    cursor "$target_dir"
  fi
}

_work_ensure_repos() {
  local base_root="$1"

  # Define all TMA repos
  local repos=("tma-backend" "tma-clients" "tma-infra" "tma-data")
  local repo repo_dir

  for repo in "${repos[@]}"; do
    repo_dir="${base_root}/${repo}"

    if [[ -d "$repo_dir" ]]; then
      # Check if it's a valid git repo
      if git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo -e "${CYAN}Repo exists:${NC} ${repo}"
        continue
      else
        echo -e "${BLUE}Directory exists but not a git repo, cloning:${NC} ${repo}"
        rm -rf "$repo_dir"
      fi
    fi

    echo -e "${GREEN}Cloning:${NC} ${repo} -> ${repo_dir}"
    git clone "git@github.com:interfaceinc/${repo}.git" "$repo_dir"
  done
}

_work_list_and_select() {
  local workdir="$1"
  local only_repo="$2"

  # Check if fzf is available
  if ! command -v fzf &>/dev/null; then
    echo -e "${RED}Error: fzf is not installed${NC}"
    return 1
  fi

  # Build list of candidate directories
  local candidates=()
  local dir name

  shopt -s nullglob
  for dir in "$workdir"/*; do
    [[ -d "$dir" ]] || continue
    name="$(basename "$dir")"

    # Skip 'main' directory
    [[ "$name" == "main" ]] && continue

    # If filtering by repo, check if that repo exists in this worktree dir
    # Worktrees are named: repo-slug (e.g., tma-backend-detect-dual-subscriptions)
    if [[ -n "$only_repo" ]]; then
      if [[ ! -d "$dir/${only_repo}-${name}" ]]; then
        continue
      fi
    fi

    candidates+=("$name")
  done
  shopt -u nullglob

  if [[ ${#candidates[@]} -eq 0 ]]; then
    if [[ -n "$only_repo" ]]; then
      echo -e "${YELLOW}No worktree directories found containing ${only_repo}${NC}"
    else
      echo -e "${YELLOW}No worktree directories found in ${workdir}${NC}"
    fi
    echo -e "Use ${CYAN}work.sh <topic>${NC} to create a new worktree"
    return 0
  fi

  # Use fzf to select
  local selected
  selected="$(printf '%s\n' "${candidates[@]}" | fzf --prompt="Select worktree> " --height=~50% --reverse)"

  if [[ -z "$selected" ]]; then
    echo -e "${YELLOW}No selection made${NC}"
    return 0
  fi

  local target_dir="$workdir/$selected"

  # If filtering by repo, cd directly into that repo
  # Worktrees are named: repo-slug (e.g., tma-backend-detect-dual-subscriptions)
  if [[ -n "$only_repo" ]]; then
    target_dir="$target_dir/${only_repo}-${selected}"
  fi

  _work_open "$selected" "$target_dir"
}

# Run if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  work "$@"
fi
