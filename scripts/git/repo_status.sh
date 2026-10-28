#!/usr/bin/env bash
# Git status dashboard for the personal repos (dotfiles, vault, .g), plus
# Claude plan usage left. Fetches remotes + usage in parallel, then shows
# branch, ahead/behind and working-tree changes per repo.
#
# usage: repo_status.sh [lab] [-n|--no-fetch] [-l|--list]
#   lab  run it on the lab over ssh, against the lab's own checkouts (no claude usage)
#   -n   skip the fetch (instant; ahead/behind + claude usage may be stale)
#   -l   also list every changed file

REPOS=("$HOME/dotfiles" "$HOME/vault" "$HOME/.g")
USAGE_HELPER="$(dirname "$0")/claude_usage.py"
FETCH_TIMEOUT=10

# s lab: pipe this script to the lab rather than trusting the lab's own (maybe older) copy
if [[ ${1:-} == lab ]]; then
  shift
  flags=()
  for arg in "$@"; do
    case "$arg" in -n|--no-fetch|-l|--list) flags+=("$arg") ;; esac
  done
  exec ssh -o ConnectTimeout=8 lab "S_HOST=lab COLUMNS=$(tput cols 2>/dev/null || echo 80) bash -s -- ${flags[*]}" < "$0"
fi
remote=${S_HOST:-}

do_fetch=1
show_files=0
for arg in "$@"; do
  case "$arg" in
    -n|--no-fetch) do_fetch=0 ;;
    -l|--list) show_files=1 ;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  esac
done

# colours
R=$'\033[0m'; B=$'\033[1m'; D=$'\033[2m'
RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; BLU=$'\033[34m'; MAG=$'\033[35m'; CYN=$'\033[36m'

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# --- fetch all remotes in parallel, capped at FETCH_TIMEOUT seconds -----------
if [[ $do_fetch == 1 ]]; then
  printf '%s' "${D}fetching remotes…${R}"
  pids=()
  i=0
  for repo in "${REPOS[@]}"; do
    (
      # keep the repo's own core.sshCommand (per-account identity), but never prompt
      ssh_cmd=$(git -C "$repo" config --get core.sshCommand 2>/dev/null || echo ssh)
      GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="$ssh_cmd -o BatchMode=yes -o ConnectTimeout=5" \
        git -C "$repo" fetch --quiet --no-recurse-submodules >/dev/null 2>&1 \
        && touch "$tmp/ok.$i"
    ) &
    pids+=($!)
    i=$((i + 1))
  done
  if [[ -z $remote ]]; then
    FORCE_COLOR=1 python3 "$USAGE_HELPER" >"$tmp/claude" 2>/dev/null &
    pids+=($!)
  fi
  ( sleep "$FETCH_TIMEOUT"; kill "${pids[@]}" 2>/dev/null ) >/dev/null 2>&1 &
  watchdog=$!
  wait "${pids[@]}" 2>/dev/null
  kill "$watchdog" 2>/dev/null
  wait "$watchdog" 2>/dev/null
  printf '\r\033[K'
fi

# --- render -------------------------------------------------------------------
cols=${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}
rule() { printf '%s' "$D"; printf '─%.0s' $(seq 1 "$1"); printf '%s\n' "$R"; }

printf '\n %s %s\n' "${B}repo status${remote:+ · ${remote}}${R}" "${D}$(date '+%H:%M')$( [[ $do_fetch == 0 ]] && echo ' · no fetch')${R}"
rule $(( cols < 72 ? cols : 72 ))

i=-1
for repo in "${REPOS[@]}"; do
  i=$((i + 1))
  name=$(basename "$repo")

  if ! git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
    printf ' %s %s  %s\n' "${RED}✗${R}" "${B}${name}${R}" "${RED}not a git repo: $repo${R}"
    continue
  fi

  branch="" upstream="" ahead=0 behind=0
  staged=0 modified=0 untracked=0 conflicts=0
  files=()
  while IFS= read -r line; do
    case "$line" in
      "# branch.head "*)     branch=${line#\# branch.head } ;;
      "# branch.upstream "*) upstream=${line#\# branch.upstream } ;;
      "# branch.ab "*)
        ab=${line#\# branch.ab }
        ahead=${ab%% *}; ahead=${ahead#+}
        behind=${ab##* }; behind=${behind#-} ;;
      "1 "*|"2 "*)
        xy=${line:2:2}
        [[ ${xy:0:1} != . ]] && staged=$((staged + 1))
        [[ ${xy:1:1} != . ]] && modified=$((modified + 1))
        # path is the last field (for renames, "new<TAB>old" — keep new)
        if [[ ${line:0:1} == 2 ]]; then p=$(cut -d' ' -f10- <<<"$line"); p=${p%%$'\t'*}
        else p=$(cut -d' ' -f9- <<<"$line"); fi
        files+=("$xy $p") ;;
      "u "*)
        conflicts=$((conflicts + 1))
        files+=("UU $(cut -d' ' -f11- <<<"$line")") ;;
      "? "*)
        untracked=$((untracked + 1))
        files+=("?? ${line#\? }") ;;
    esac
  done < <(git -C "$repo" status --porcelain=v2 --branch 2>/dev/null)

  last=$(git -C "$repo" log -1 --format='%cr' 2>/dev/null)
  dirty=$((staged + modified + untracked + conflicts))

  # headline icon: red = conflicts or diverged, yellow = needs action, green = all good
  if (( conflicts > 0 )) || { (( ahead > 0 )) && (( behind > 0 )); }; then icon="${RED}●${R}"
  elif (( dirty > 0 || ahead > 0 || behind > 0 )) || [[ -z $upstream ]]; then icon="${YEL}●${R}"
  else icon="${GRN}●${R}"; fi

  # sync state vs upstream
  if [[ $branch == "(detached)" ]]; then
    sync="${MAG}detached HEAD${R}"
  elif [[ -z $upstream ]]; then
    sync="${YEL}no upstream${R}"
  elif (( ahead == 0 && behind == 0 )); then
    sync="${GRN}✓ up to date${R}"
  else
    sync=""
    (( ahead > 0 ))  && sync+="${CYN}↑${ahead} to push${R}"
    (( ahead > 0 && behind > 0 )) && sync+="  "
    (( behind > 0 )) && sync+="${MAG}↓${behind} to pull${R}"
  fi
  if [[ $do_fetch == 1 && -n $upstream && ! -e $tmp/ok.$i ]]; then
    sync+="  ${RED}⚠ fetch failed${R}"
  fi

  printf ' %s %s%-10s%s %s%-8s%s %s\n' "$icon" "$B" "$name" "$R" "$BLU" "$branch" "$R" "$sync"

  # working tree summary
  parts=()
  (( conflicts > 0 )) && parts+=("${RED}${conflicts} conflicted${R}")
  (( staged > 0 ))    && parts+=("${GRN}${staged} staged${R}")
  (( modified > 0 ))  && parts+=("${YEL}${modified} modified${R}")
  (( untracked > 0 )) && parts+=("${RED}${untracked} untracked${R}")
  if (( ${#parts[@]} == 0 )); then
    summary="${GRN}clean${R}"
  else
    summary=""
    for p in "${parts[@]}"; do summary+="${summary:+${D} · ${R}}$p"; done
  fi
  printf '   %s%s\n' "$summary" "${last:+  ${D}last commit ${last}${R}}"

  # changed files (only with -l)
  (( show_files )) && for f in "${files[@]}"; do
    xy=${f:0:2}; path=${f:3}
    case "$xy" in
      UU) c=$RED ;;
      '??') c=$RED ;;
      .?) c=$YEL ;;
      *) c=$GRN ;;
    esac
    # keep the tail of long paths so lines don't wrap
    max=$(( cols - 9 ))
    (( ${#path} > max && max > 10 )) && path="…${path:$(( ${#path} - max + 1 ))}"
    printf '     %s%s%s %s\n' "$c" "${xy//./ }" "$R" "$path"
  done
done

# --- claude plan usage (fetched above; cached copy if that timed out or -n) ----
if [[ -n $remote ]]; then :
elif [[ -s $tmp/claude ]]; then cat "$tmp/claude"
else FORCE_COLOR=1 python3 "$USAGE_HELPER" --cache-only 2>/dev/null; fi
echo
