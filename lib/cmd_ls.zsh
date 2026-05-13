# wisdom ls — list snippets, newest first.
#
# Usage: wisdom ls [--bucket KEY] [--limit N]

_wisdom_ls() {
  local bucket="" limit=20
  while (( $# )); do
    case "$1" in
      --bucket) bucket="$2"; shift 2 ;;
      --bucket=*) bucket="${1#--bucket=}"; shift ;;
      --limit)  limit="$2"; shift 2 ;;
      --limit=*) limit="${1#--limit=}"; shift ;;
      -*) print -r -- "ls: unknown flag $1" >&2; return 1 ;;
      *)  print -r -- "ls: unexpected arg $1" >&2; return 1 ;;
    esac
  done

  local repo
  repo=$(wisdom_repo_path) || return 2

  local -a files
  files=("$repo"/wisdoms/**/*.md(N))
  if (( ${#files} == 0 )); then
    print -r -- "no wisdoms yet"
    return 0
  fi

  # Extract id, created_at, category, body preview per file; emit tab-separated.
  local f id ts cat body preview
  local -a rows
  for f in $files; do
    [[ "${f:t}" == "_categories.yml" ]] && continue
    id=$(awk -F': ' '/^id:/{print $2; exit}' "$f")
    ts=$(awk -F': ' '/^created_at:/{print $2; exit}' "$f")
    cat=$(awk -F': ' '/^category:/{print $2; exit}' "$f")
    body=$(awk '/^---$/{n++; next} n==2 && NF{print; exit}' "$f")
    preview=$(print -r -- "$body" | cut -c1-80)
    if [[ -n "$bucket" && "$cat" != "$bucket" ]]; then continue; fi
    rows+=("$ts	$id	$cat	$preview")
  done

  if (( ${#rows} == 0 )); then
    [[ -n "$bucket" ]] && print -r -- "no wisdoms in bucket: $bucket" || print -r -- "no wisdoms yet"
    return 0
  fi

  # Sort by timestamp desc, take first $limit
  print -rl -- $rows | sort -r | head -n "$limit" | awk -F'\t' '{printf "%s  %s  [%s]  %s\n", $2, substr($1,1,10), $3, $4}'
}
