# wisdom find — search snippets by full-text using rg (preferred) or grep.

_wisdom_find() {
  if (( $# == 0 )); then
    print -r -- "find: query required" >&2; return 1
  fi
  local query="$*"
  local repo
  repo=$(wisdom_repo_path) || return 2
  local dir="$repo/wisdoms"
  [[ -d "$dir" ]] || { print -r -- "no matches"; return 0; }

  local -a hits
  local raw
  if (( $+commands[rg] )); then
    raw=$(rg --color=never -l -i -F -- "$query" "$dir" 2>/dev/null || true)
  else
    raw=$(grep -rl -i -F -- "$query" "$dir" 2>/dev/null || true)
  fi
  hits=("${(@f)raw}")
  hits=("${(@)hits:#}")  # strip empty entries

  if (( ${#hits} == 0 )); then
    print -r -- "no matches for: $query"
    return 0
  fi

  local f id cat line
  for f in $hits; do
    [[ "${f:t}" == "_categories.yml" ]] && continue
    id=$(awk -F': ' '/^id:/{print $2; exit}' "$f")
    cat=$(awk -F': ' '/^category:/{print $2; exit}' "$f")
    line=$(grep -i -F -- "$query" "$f" | head -n 1 | cut -c1-120)
    print -r -- "$id  [$cat]  $line"
  done
}
