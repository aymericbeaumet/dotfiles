#!/usr/bin/env bash
# Display PR information for the current branch in a tmux popup.
# Renders summary, mergeability, CI checks, body, and comments
# with Nerd Font icons and ANSI colors. Body/comments via glow.

set -uo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not installed. Install with: brew install gh"
  read -n 1 -r -s -p "Press any key to close..."
  exit 0
fi

JSON_FIELDS='number,title,url,state,isDraft,mergeable,mergeStateStatus,reviewDecision,headRefName,baseRefName,body,author,additions,deletions,changedFiles,createdAt,updatedAt,labels,assignees,reviewRequests,statusCheckRollup'

if ! pr=$(gh pr view --json "$JSON_FIELDS" 2>&1); then
  printf '\033[1;31m✗\033[0m No PR found for the current branch.\n\n%s\n\n' "$pr"
  read -n 1 -r -s -p "Press any key to close..."
  exit 0
fi

# ANSI helpers
c_reset=$'\033[0m'
c_bold=$'\033[1m'
c_dim=$'\033[2m'
c_grey=$'\033[38;5;245m'
c_cyan=$'\033[38;5;38m'
c_blue=$'\033[38;5;75m'
c_yellow=$'\033[38;5;178m'
c_orange=$'\033[38;5;208m'
c_green=$'\033[38;5;42m'
c_red=$'\033[38;5;203m'
c_violet=$'\033[38;5;141m'

# Glow renders to stdout; force a width that fits typical popup
GLOW_WIDTH=${GLOW_WIDTH:-100}
render_md() {
  if command -v glow >/dev/null 2>&1; then
    glow -s dark -w "$GLOW_WIDTH" -
  else
    cat
  fi
}

hr() {
  printf '%s' "$c_grey"
  printf '─%.0s' $(seq 1 "${COLUMNS:-100}")
  printf '%s\n' "$c_reset"
}

section() {
  local icon=$1 label=$2
  printf '\n%s%s %s%s\n' "$c_yellow" "$icon" "$label" "$c_reset"
  hr
}

# Status colorizers
color_state() {
  case "$1" in
    OPEN)   printf '%s %sopen%s'   "$c_green"  "$c_green"  "$c_reset" ;;
    CLOSED) printf '%s %sclosed%s' "$c_red"    "$c_red"    "$c_reset" ;;
    MERGED) printf '%s %smerged%s' "$c_violet" "$c_violet" "$c_reset" ;;
    *)      printf '%s%s%s'           "$c_grey"   "$1"        "$c_reset" ;;
  esac
}

color_mergeable() {
  case "$1" in
    MERGEABLE)  printf '%s %smergeable%s'  "$c_green" "$c_green" "$c_reset" ;;
    CONFLICTING)printf '%s %sconflicts%s'  "$c_red"   "$c_red"   "$c_reset" ;;
    UNKNOWN)    printf '%s %sunknown%s'    "$c_grey"  "$c_grey"  "$c_reset" ;;
    *)          printf '%s%s%s'              "$c_grey"  "$1"       "$c_reset" ;;
  esac
}

color_merge_state() {
  case "$1" in
    CLEAN)               printf '%sclean%s'                "$c_green"  "$c_reset" ;;
    HAS_HOOKS)           printf '%shas hooks%s'            "$c_green"  "$c_reset" ;;
    UNSTABLE)            printf '%sunstable%s'             "$c_yellow" "$c_reset" ;;
    BEHIND)              printf '%sbehind%s'               "$c_yellow" "$c_reset" ;;
    BLOCKED)             printf '%sblocked%s'              "$c_red"    "$c_reset" ;;
    DIRTY)               printf '%sdirty%s'                "$c_red"    "$c_reset" ;;
    DRAFT)               printf '%sdraft%s'                "$c_grey"   "$c_reset" ;;
    *)                   printf '%s%s%s'                     "$c_grey"   "$1"        "$c_reset" ;;
  esac
}

color_review() {
  case "$1" in
    APPROVED)         printf '%s %sapproved%s'          "$c_green"  "$c_green"  "$c_reset" ;;
    CHANGES_REQUESTED)printf '%s %schanges requested%s' "$c_red"    "$c_red"    "$c_reset" ;;
    REVIEW_REQUIRED)  printf '%s %sreview required%s'   "$c_yellow" "$c_yellow" "$c_reset" ;;
    "")               printf '%s—%s'                       "$c_grey"   "$c_reset" ;;
    *)                printf '%s%s%s'                       "$c_grey"   "$1"        "$c_reset" ;;
  esac
}

# Single PR info call already cached in $pr
get() { echo "$pr" | jq -r "$1"; }

number=$(get '.number')
title=$(get '.title')
url=$(get '.url')
state=$(get '.state')
is_draft=$(get '.isDraft')
mergeable=$(get '.mergeable')
merge_state=$(get '.mergeStateStatus')
review_decision=$(get '.reviewDecision // ""')
head_ref=$(get '.headRefName')
base_ref=$(get '.baseRefName')
body=$(get '.body')
author=$(get '.author.login')
additions=$(get '.additions')
deletions=$(get '.deletions')
changed_files=$(get '.changedFiles')
created=$(get '.createdAt')
updated=$(get '.updatedAt')
labels=$(get '[.labels[].name] | join(", ")')
assignees=$(get '[.assignees[].login] | join(", ")')
reviewers=$(get '[.reviewRequests[].login // .reviewRequests[].name] | join(", ")')

draft_tag=""
[[ "$is_draft" == "true" ]] && draft_tag=" ${c_grey}· draft${c_reset}"

{
  # ─── Header ───
  printf '\n%s%s #%s%s  %s%s%s\n' \
    "$c_bold" "$c_cyan" "$number" "$c_reset" \
    "$c_bold" "$title" "$c_reset"
  printf '   %s%s%s\n' "$c_dim" "$url" "$c_reset"
  printf '\n'

  # ─── Summary block ───
  printf '   %s %s%s%s %s→%s %s%s%s\n' \
    "$c_blue" "$c_cyan" "$head_ref" "$c_reset" "$c_grey" "$c_reset" "$c_cyan" "$base_ref" "$c_reset"
  printf '   %s %s%s\n' "$c_grey" "$author" "$c_reset"

  printf '   '
  color_state "$state"
  printf '%s\n' "$draft_tag"

  printf '   '
  color_mergeable "$mergeable"
  printf '%s · %s' "$c_grey" "$c_reset"
  color_merge_state "$merge_state"
  printf '\n'

  printf '   '
  color_review "$review_decision"
  printf '\n'

  printf '   %s+%s%s %s-%s%s %s· %s files · created %s · updated %s%s\n' \
    "$c_green" "$additions" "$c_reset" \
    "$c_red"   "$deletions" "$c_reset" \
    "$c_grey" "$changed_files" \
    "${created%%T*}" "${updated%%T*}" "$c_reset"

  [[ -n "$labels"    ]] && printf '   %s %s%s%s\n' "$c_grey" "$c_violet" "$labels"    "$c_reset"
  [[ -n "$reviewers" ]] && printf '   %s %s%s%s\n' "$c_grey" "$c_grey"   "$reviewers" "$c_reset"
  [[ -n "$assignees" ]] && printf '   %s %s%s%s\n' "$c_grey" "$c_grey"   "$assignees" "$c_reset"

  # ─── Checks ───
  section "" "checks"
  echo "$pr" | jq -r '
    if (.statusCheckRollup // []) | length == 0 then "  (no checks)"
    else
      .statusCheckRollup | map(
        (.conclusion // .status // "") as $c |
        (if   $c == "SUCCESS"     then "\u001b[38;5;42m\uf00c"
         elif $c == "FAILURE"     then "\u001b[38;5;203m\uf00d"
         elif $c == "CANCELLED"   then "\u001b[38;5;245m\uf00d"
         elif $c == "TIMED_OUT"   then "\u001b[38;5;203m\uf00d"
         elif $c == "ACTION_REQUIRED" then "\u001b[38;5;208m\uf071"
         elif $c == "NEUTRAL"     then "\u001b[38;5;245m\uf068"
         elif $c == "SKIPPED"     then "\u001b[38;5;245m\uf068"
         elif $c == "QUEUED"      then "\u001b[38;5;178m\uf017"
         elif $c == "IN_PROGRESS" then "\u001b[38;5;178m\uf017"
         elif $c == "PENDING"     then "\u001b[38;5;178m\uf017"
         else "\u001b[38;5;245m?" end) as $icon |
        "  \($icon) \u001b[0m\(.name // .context // "?")\u001b[38;5;245m  \($c | ascii_downcase | gsub("_"; " "))\u001b[0m"
      ) | .[]
    end'

  # ─── Description ───
  if [[ -n "$body" && "$body" != "null" ]]; then
    section "" "description"
    printf '%s\n' "$body" | render_md
  fi

  # ─── Comments ───
  section "󰅺" "comments"
  comments_md=$(gh pr view --comments 2>/dev/null || true)
  if [[ -z "$comments_md" ]]; then
    printf '  %s(none)%s\n' "$c_grey" "$c_reset"
  else
    printf '%s\n' "$comments_md" | render_md
  fi

  printf '\n'
} | less -R
