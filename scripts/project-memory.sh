#!/usr/bin/env bash

set -euo pipefail

export LC_ALL=C
umask 077

usage() {
  cat <<'USAGE'
Usage: project-memory.sh [--path] [DIRECTORY]

Create the shared memory for DIRECTORY's Git project. By default, print the
memory as agent context; with --path, print only the physical MEMORY.md path.
USAGE
}

sha256() {
  if command -v shasum >/dev/null 2>&1; then
    printf '%s' "$1" | shasum -a 256 | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$1" | sha256sum | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    printf '%s' "$1" | openssl dgst -sha256 -r | awk '{print $1}'
  else
    printf 'project-memory: no SHA-256 implementation found\n' >&2
    return 1
  fi
}

normalize_remote_url() {
  local url="$1"
  local scheme authority host path

  url=${url%%\#*}
  url=${url%%\?*}
  case "$url" in
    file://* | /* | ./* | ../* | ~/*) return 1 ;;
  esac

  if [[ "$url" =~ ^([[:alpha:]][[:alnum:]+.-]*)://([^/]+)/(.*)$ ]]; then
    scheme=$(printf '%s' "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]')
    [[ "$scheme" != "file" ]] || return 1
    authority=${BASH_REMATCH[2]}
    path=${BASH_REMATCH[3]}
    host=${authority##*@}
    case "$scheme" in
      ssh | git+ssh) host=${host%:22} ;;
      https) host=${host%:443} ;;
      http) host=${host%:80} ;;
    esac
  elif [[ "$url" =~ ^([^/:]+@)?([^/:]+):(.+)$ ]]; then
    host=${BASH_REMATCH[2]}
    path=${BASH_REMATCH[3]}
  else
    return 1
  fi

  host=$(printf '%s' "$host" | tr '[:upper:]' '[:lower:]')
  while [[ "$path" == /* ]]; do
    path=${path#/}
  done
  while [[ "$path" == */ ]]; do
    path=${path%/}
  done
  path=${path%.git}
  [[ -n "$host" && -n "$path" ]] || return 1
  printf '%s/%s\n' "$host" "$path"
}

project_id() {
  local project_root="$1"
  local remote_url canonical_remote remote_name candidate_url root_commits
  local common_git_dir common_root path_key digest

  remote_url=$(git -C "$project_root" remote get-url origin 2>/dev/null || true)
  canonical_remote=""
  if [[ -n "$remote_url" ]]; then
    canonical_remote=$(normalize_remote_url "$remote_url" 2>/dev/null || true)
  fi

  if [[ -z "$canonical_remote" ]]; then
    while IFS= read -r remote_name; do
      [[ -n "$remote_name" ]] || continue
      candidate_url=$(git -C "$project_root" remote get-url "$remote_name" 2>/dev/null || true)
      if canonical_remote=$(normalize_remote_url "$candidate_url" 2>/dev/null); then
        break
      fi
      canonical_remote=""
    done < <(git -C "$project_root" remote 2>/dev/null | sort)
  fi

  if [[ -n "$canonical_remote" ]]; then
    digest=$(sha256 "git:$canonical_remote")
    printf 'git-%s\n' "$digest"
    return 0
  fi

  root_commits=$(git -C "$project_root" rev-list --max-parents=0 HEAD 2>/dev/null | sort || true)
  if [[ -n "$root_commits" ]]; then
    digest=$(sha256 "commit:$root_commits")
    printf 'commit-%s\n' "$digest"
    return 0
  fi

  common_git_dir=$(git -C "$project_root" rev-parse --git-common-dir)
  case "$common_git_dir" in
    /*) ;;
    *) common_git_dir="$project_root/$common_git_dir" ;;
  esac
  common_root=$(CDPATH='' cd "$(dirname "$common_git_dir")" && pwd -P)
  case "$common_root" in
    "$HOME") path_key="." ;;
    "$HOME"/*) path_key=${common_root#"$HOME"/} ;;
    *) path_key=$common_root ;;
  esac
  digest=$(sha256 "path:$path_key")
  printf 'path-%s\n' "$digest"
}

mode=render
case "${1:-}" in
  --path)
    mode=path
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  -*)
    usage >&2
    exit 2
    ;;
esac

if (($# > 1)); then
  usage >&2
  exit 2
fi

cwd=${1:-}
if [[ -z "$cwd" && ! -t 0 ]]; then
  payload=$(cat)
  if command -v jq >/dev/null 2>&1; then
    cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null || true)
  fi
fi
cwd=${cwd:-$PWD}
[[ -d "$cwd" ]] || exit 0
cwd=$(CDPATH='' cd "$cwd" && pwd -P)

project_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)
[[ -n "$project_root" && -d "$project_root" ]] || exit 0
project_root=$(CDPATH='' cd "$project_root" && pwd -P)

memory_root=${PROJECT_MEMORY_ROOT:-$HOME/.dotfiles/.agents/memories}
if [[ -e "$memory_root/.git" || -L "$memory_root/.git" ]]; then
  printf 'project-memory: legacy nested repository remains at %s; run dotfiles setup first\n' \
    "$memory_root" >&2
  exit 1
fi

id=$(project_id "$project_root")
memory_dir="$memory_root/$id"
memory_file="$memory_dir/MEMORY.md"
mkdir -p "$memory_dir"
chmod 700 "$memory_root" "$memory_dir"
memory_dir=$(CDPATH='' cd "$memory_dir" && pwd -P)
memory_file="$memory_dir/MEMORY.md"

if [[ ! -e "$memory_file" && ! -L "$memory_file" ]]; then
  (
    set -o noclobber
    printf '%s\n' \
      '# Project Memory' \
      '' \
      'Keep concise project knowledge here. Use `.handouts/` for session resumption and `AGENTS.md` for committed guidance.' \
      >"$memory_file"
  ) 2>/dev/null || true
fi
if [[ ! -f "$memory_file" || -L "$memory_file" ]]; then
  printf 'project-memory: expected a regular file at %s\n' "$memory_file" >&2
  exit 1
fi
chmod 600 "$memory_file"

project_link="$project_root/.memories"
if [[ -L "$project_link" ]]; then
  if [[ "$(readlink "$project_link")" != "$memory_dir" ]]; then
    printf 'project-memory: refusing to replace conflicting symlink %s -> %s\n' \
      "$project_link" "$(readlink "$project_link")" >&2
    exit 1
  fi
elif [[ -e "$project_link" ]]; then
  printf 'project-memory: refusing to replace existing path %s\n' "$project_link" >&2
  exit 1
elif ! ln -s "$memory_dir" "$project_link" 2>/dev/null; then
  if [[ ! -L "$project_link" || "$(readlink "$project_link")" != "$memory_dir" ]]; then
    printf 'project-memory: failed to create %s\n' "$project_link" >&2
    exit 1
  fi
fi

if [[ "$mode" == "path" ]]; then
  printf '%s\n' "$memory_file"
else
  printf 'Shared project memory from %s follows.\n\n' "$project_root/.memories/MEMORY.md"
  cat "$memory_file"
fi
